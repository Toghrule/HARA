using Hara.Application.Common.Interfaces;
using Hara.Application.Notifications;
using Hara.Infrastructure.Email;
using Hara.Infrastructure.Files;
using Hara.Infrastructure.Notifications;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Hara.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<FileStorageOptions>(configuration.GetSection(FileStorageOptions.SectionName));
        services.AddScoped<IFileStorageService, LocalFileStorageService>();

        services.Configure<FirebaseOptions>(configuration.GetSection(FirebaseOptions.SectionName));
        services.AddSingleton<IPushSender, FirebasePushSender>();

        // Email: through an SMTP service when one is set up; in development the messages go to the log; otherwise sending fails.
        services.Configure<EmailOptions>(configuration.GetSection(EmailOptions.SectionName));
        var email = configuration.GetSection(EmailOptions.SectionName).Get<EmailOptions>() ?? new EmailOptions();
        if (!string.IsNullOrWhiteSpace(email.Host))
        {
            services.AddSingleton<IEmailSender, SmtpEmailSender>();
        }
        else if (email.LogInstead)
        {
            services.AddSingleton<IEmailSender, LoggingEmailSender>();
        }
        else
        {
            services.AddSingleton<IEmailSender, UnconfiguredEmailSender>();
        }

        return services;
    }
}
