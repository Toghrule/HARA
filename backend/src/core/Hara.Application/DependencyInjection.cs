using System.Globalization;
using System.Reflection;
using FluentValidation;
using Hara.Application.Common.Behaviours;
using MediatR;
using Microsoft.Extensions.DependencyInjection;

namespace Hara.Application;

/// <summary>Registers the Application layer's services with the DI container: MediatR handlers, the validation pipeline behaviour, and every FluentValidation validator in this assembly.</summary>
public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        var assembly = Assembly.GetExecutingAssembly();

        // FluentValidation otherwise picks the server OS's language, so validation messages would
        // come out in e.g. Russian on a ru-RU machine while every client UI is in English.
        ValidatorOptions.Global.LanguageManager.Culture = new CultureInfo("en");

        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(assembly));
        services.AddValidatorsFromAssembly(assembly);
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehaviour<,>));
        services.AddScoped<Venue.VenueAccess>();

        return services;
    }
}
