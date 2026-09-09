using Hara.Application;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Hara.Application.Tests;

public class DependencyInjectionTests
{
    [Fact]
    public void AddApplication_ReturnsSameServiceCollection()
    {
        var services = new ServiceCollection();

        var result = services.AddApplication();

        Assert.Same(services, result);
    }
}
