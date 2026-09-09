using Hara.Domain.Common;
using Xunit;

namespace Hara.Domain.Tests;

public class BaseEntityTests
{
    private sealed class TestEntity : BaseEntity;

    [Fact]
    public void NewEntity_HasNonEmptyId()
    {
        var entity = new TestEntity();

        Assert.NotEqual(Guid.Empty, entity.Id);
    }
}
