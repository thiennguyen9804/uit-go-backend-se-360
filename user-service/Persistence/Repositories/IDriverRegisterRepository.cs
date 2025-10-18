using user_service.Dtos;
using user_service.Entities;

namespace user_service.Repositories;

public interface IDriverRegisterRepository:IGenericRepository<DriverRegister>
{
    Task<DriverRegister?> GetUserDriverRegisterByIdAsync(Guid id);
    Task<DriverRegister?> GetLatestRegisterAsync(Guid userId);
    Task<PaginatedResult<DriverRegister>> GetMyDriverRegistersAsync(Guid userId, int paginationRequestPage, int paginationRequestSize);
    Task<PaginatedResult<DriverRegister>> GetAllDriverRegistersAsync(int paginationRequestPage, int paginationRequestSize, RegisterStatus paginationRequestStatus);
}