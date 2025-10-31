using Microsoft.AspNetCore.Identity;

namespace user_service.Entities;

public class ApplicationUser : IdentityUser
{
    // Optional full name for the user (display name)
    public string? FullName { get; set; }

    public virtual List<DriverRegister> DriverRegisters { get; set; } = new();
}

