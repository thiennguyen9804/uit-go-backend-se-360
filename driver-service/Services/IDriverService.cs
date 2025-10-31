using driver_service.Dtos;
using driver_service.Persistence.Repositories;

namespace driver_service.Services;

public interface IDriverService
{
    Task<DriverDto> GetByIdAsync(Guid id);
    Task<DriverDto> CreateAsync(CreateDriverDto dto);
    Task<DriverDto> UpdateAsync(Guid id, UpdateDriverDto dto);
    Task<PaginatedResult<driver_service.Entities.Driver>> GetAllAsync(int page, int size);
}
