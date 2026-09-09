using Hara.Application.Common.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Hara.Persistence;

public class ApplicationDbContext : DbContext, IApplicationDbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }
}
