using Microsoft.AspNetCore.Identity;

namespace user_service.Entities;

public class ApplicationUser : IdentityUser
{
    public virtual List<DriverRegister> DriverRegisters { get; set; }
}

