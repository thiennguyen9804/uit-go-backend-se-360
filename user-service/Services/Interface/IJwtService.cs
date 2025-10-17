using user_service.Dtos;

namespace user_service.Services.Interface;

public interface IJwtService
{
    string GenerateToken(Guid userId,
        string email,
        string? role);
}