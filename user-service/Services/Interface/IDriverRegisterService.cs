using user_service.Dtos;

namespace user_service.Services.Interface;

public interface IDriverRegisterService
{
    Task<DriverRegisterDto> GetByIdAsync(Guid id);
    Task<DriverRegisterDto> CreateAsync(Guid userId, CreateDriverRegisterDto registerDriverrDto);
    Task<PaginatedResult<DriverRegisterDto>> GetMyDriverRegistersAsync(Guid userId, PaginationRequest  paginationRequest);
    Task<PaginatedResult<DriverRegisterDto>> GetAllDriverRegistersAsync(AllDriverRegistersPageRequest  paginationRequest);
    Task<DriverRegisterDto> UpdateAsync(Guid id, UpdateDriverRegisterDto updateRegisterDriverrDto);
}

