using user_service.Dtos;

namespace user_service.Services.Interface;

public interface IIdentityService
{
    Task<UserDto> GetByIdAsync(Guid id);
    Task<UserDto> CreateAsync(CreateUserDto dto);
    Task<UserDto> UpdateAsync(Guid id, UpdateUserDto dto);
    Task<LoginResponseDto> LoginAsync(LoginDto dto);
    
    Task<bool> CheckEmailExists(string email);
    Task<string> GeneratePasswordResetTokenAsync(string email);
    Task ChangePasswordAsync(Guid userId, string oldPassword, string newPassword);
    Task ResetPasswordAsync(string email, string code, string newPassword);
    
   
}