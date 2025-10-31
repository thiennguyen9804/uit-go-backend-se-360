using driver_service.Entities;

namespace driver_service.Persistence.Repositories;

public interface IGenericRepository<T> where T : class
{
    Task<T?> GetByIdAsync(Guid id);
    Task<IEnumerable<T>> GetAllAsync();
    Task<T> AddAsync(T entity);
    Task<T> UpdateAsync(T entity);
    Task SoftDeleteAsync(Guid id);
    Task<bool> ExistsAsync(Guid id);
    Task<int> CountAsync();
}
