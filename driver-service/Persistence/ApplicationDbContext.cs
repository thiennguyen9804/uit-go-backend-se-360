using Microsoft.EntityFrameworkCore;
using driver_service.Entities;

namespace driver_service.Persistence;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
    }
    public DbSet<DriverWorkStatusEvent> DriverWorkStatusEvents { get; set; }
    public DbSet<Driver> Drivers { get; set; }
}
