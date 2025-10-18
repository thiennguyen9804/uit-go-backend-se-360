using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;

using user_service.Entities;

namespace user_service;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    public DbSet<DriverRegister> DriverRegisters { get; set; }
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }
}
