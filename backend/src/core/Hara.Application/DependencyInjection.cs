using Microsoft.Extensions.DependencyInjection;

namespace Hara.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        return services;
    }
}
