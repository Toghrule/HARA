using System.Text;
using Hara.Api.Endpoints;
using Hara.Api.Middleware;
using Hara.Api.RateLimiting;
using Hara.Application;
using Hara.Infrastructure;
using Hara.Persistence;
using Hara.Persistence.Identity;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Secrets (JWT signing key, admin password) are kept out of git in backend/secrets/local-settings.json, which has the same
// shape as appsettings.json. It is looked for in the app's folder and every folder above it, so it is found whether the
// API is started with `dotnet run`, from the built files, or on a server.
var localSettings = FindUpwards("secrets/local-settings.json");
if (localSettings is not null)
{
    builder.Configuration.AddJsonFile(localSettings, optional: true, reloadOnChange: false);
}

builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddPersistence(builder.Configuration, builder.Environment);
builder.Services.AddHaraRateLimiting(builder.Configuration);
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<Hara.Application.Common.Interfaces.ICurrentUserService, Hara.Api.Services.CurrentUserService>();

var jwtSection = builder.Configuration.GetSection(JwtOptions.SectionName);
var jwtOptions = jwtSection.Get<JwtOptions>() ?? new JwtOptions();

if (string.IsNullOrWhiteSpace(jwtOptions.SigningKey))
{
    throw new InvalidOperationException(
        $"Configuration \"{JwtOptions.SectionName}:{nameof(JwtOptions.SigningKey)}\" is required and must not be empty. " +
        "Put it in backend/secrets/local-settings.json (see HANDOFF.md), an environment variable, or user-secrets before starting the API. " +
        $"(Environment: {builder.Environment.EnvironmentName}; local-settings.json: {(localSettings ?? "not found")}.)");
}

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtOptions.Issuer,
            ValidateAudience = true,
            ValidAudience = jwtOptions.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtOptions.SigningKey)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1)
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("Admin", policy => policy.RequireRole(IdentitySeeder.AdminRole));
    // Signed in as a restaurant owner or waiter. Whether they are *approved* for a restaurant is
    // checked against the database on each request, not trusted from the token.
    options.AddPolicy("VenueMember", policy => policy.RequireRole(IdentitySeeder.OwnerRole, IdentitySeeder.StaffRole));
    options.AddPolicy("Owner", policy => policy.RequireRole(IdentitySeeder.OwnerRole));
});

var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        if (allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins).AllowAnyHeader().AllowAnyMethod();
        }
    });
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    var securityScheme = new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter a JWT bearer token, e.g. from POST /api/auth/login.",
        Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
    };
    options.AddSecurityDefinition("Bearer", securityScheme);
    options.AddSecurityRequirement(new OpenApiSecurityRequirement { { securityScheme, [] } });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Creates the admin account from configuration if it does not exist yet (does nothing without AdminUser settings).
using (var scope = app.Services.CreateScope())
{
    await IdentitySeeder.SeedAsync(scope.ServiceProvider);
}

// Behind a tunnel or reverse proxy on this machine (cloudflared, nginx) every request arrives from 127.0.0.1. Trusting its
// forwarded headers (only from a proxy on this machine, the default) makes the rate limits count each real client
// separately instead of all of them together.
app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});

app.UseHttpsRedirection();
app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseCors();
// After CORS so a 429 still carries the CORS headers a browser client needs to read it.
app.UseRateLimiter();

var fileStorageBasePath = builder.Configuration["FileStorage:BasePath"] ?? "App_Data/uploads";
var fileStoragePublicUrl = builder.Configuration["FileStorage:PublicBaseUrl"] ?? "/uploads";
Directory.CreateDirectory(fileStorageBasePath);
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(Path.GetFullPath(fileStorageBasePath)),
    RequestPath = fileStoragePublicUrl
});

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }))
    .WithName("HealthCheck")
    .AllowAnonymous();

app.MapAuthEndpoints();
app.MapPasswordResetsEndpoints();
app.MapRestaurantsEndpoints();
app.MapSubmissionsEndpoints();
app.MapReservationsEndpoints();
app.MapVenueEndpoints();
app.MapChangeRequestsEndpoints();
app.MapAdvertisementsEndpoints();
app.MapCompanyInfoEndpoints();
app.MapFaqEndpoints();
app.MapUploadsEndpoints();

app.Run();

// The first folder, from the app's own up to the drive root, that holds the given relative path; null if none does.
static string? FindUpwards(string relativePath)
{
    foreach (var start in new[] { AppContext.BaseDirectory, Directory.GetCurrentDirectory() })
    {
        for (var directory = new DirectoryInfo(start); directory is not null; directory = directory.Parent)
        {
            var candidate = Path.Combine(directory.FullName, relativePath);
            if (File.Exists(candidate))
            {
                return candidate;
            }
        }
    }

    return null;
}
