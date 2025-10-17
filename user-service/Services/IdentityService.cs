using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using user_service.Dtos;
using user_service.Entities;
using user_service.Services.Interface;

namespace user_service.Services;

public class IdentityService(
    UserManager<ApplicationUser> userManager,
    SignInManager<ApplicationUser> signInManager,
    RoleManager<IdentityRole> roleManager,
    IJwtService jwtService)
    : IIdentityService
{
    private readonly IJwtService _jwtService = jwtService;

    public async Task<UserDto> GetByIdAsync(Guid id)
    {
        var user = await userManager.FindByIdAsync(id.ToString());
        if (user == null) 
            throw new Exception("User not found");
        var roles = await userManager.GetRolesAsync(user);
        if(roles==null || roles.Count==0)
            throw new Exception("Role not found");
        return new UserDto
        {
            Id = user.Id,
            Email = user.Email!,
            Username = user.UserName,
            Role =   roles.First().ToString()
        };
    }

    public async Task<UserDto> CreateAsync(CreateUserDto dto)
    {
        var user = new ApplicationUser
        {
            UserName = dto.Email,
            Email = dto.Email,
        };

        var result = await userManager.CreateAsync(user, dto.Password);
        if (!result.Succeeded)
            throw new Exception(string.Join(", ", result.Errors.Select(e => e.Description)));
        var roleResult = await userManager.AddToRolesAsync(user, [nameof(AppRole.User)]);
        if (!roleResult.Succeeded)
            throw new Exception(string.Join(", ", roleResult.Errors.Select(e => e.Description)));

        return new UserDto
        {
            Id = user.Id,
            Email = user.Email!,
            Username = user.UserName,
        };
    }

    public Task<UserDto> UpdateAsync(Guid id, UpdateUserDto dto)
    {
        throw new NotImplementedException();
    }

    public async Task<LoginResponseDto> LoginAsync(LoginDto dto)
    {
        var user = await userManager.FindByEmailAsync(dto.Email);
        if (user == null)
            throw new Exception($"User not found with email {dto.Email}");

        var result = await signInManager.CheckPasswordSignInAsync(user, dto.Password, false);

        if (!result.Succeeded)
            throw new Exception("Invalid login attempt");

        IList<string> roles = await userManager.GetRolesAsync(user);


        string? first = null;
        foreach (var role in roles)
        {
            first = role;
            break;
        }

        var token = _jwtService
                .GenerateToken(Guid.Parse(user.Id), 
                user.Email!,
                first);

        return new LoginResponseDto
        {
            User = await GetByIdAsync(Guid.Parse(user.Id)),
            Token = token
        };
    }

    public async Task<bool> CheckEmailExists(string email)
    {
        var user = await userManager.FindByEmailAsync(email);
        return user != null;
    }

    public async Task<string> GeneratePasswordResetTokenAsync(string email)
    {
        var user = await userManager.FindByEmailAsync(email);
        if (user == null)
            throw new Exception($"User not found with email ${email}");

        return await userManager.GeneratePasswordResetTokenAsync(user);
    }

    public async Task ChangePasswordAsync(Guid userId, string oldPassword, string newPassword)
    {
        var user = await userManager.FindByIdAsync(userId.ToString());
        if (user == null)
            throw new UnauthorizedAccessException("User not found");
        await userManager.ChangePasswordAsync(user,oldPassword, newPassword);
    }

    public async Task ResetPasswordAsync(string email, string code, string newPassword)
    {
        var user = await userManager.FindByEmailAsync(email);
        if (user == null)
            throw new Exception($"User not found with email: {email}");
        var result = await userManager.ResetPasswordAsync(user, code, newPassword);
        if(!result.Succeeded)
            throw new Exception($"{result.Errors.First().Description}");
    }

    

}
