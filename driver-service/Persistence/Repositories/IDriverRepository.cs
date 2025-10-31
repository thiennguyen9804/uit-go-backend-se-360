using driver_service.Entities;

namespace driver_service.Persistence.Repositories;

public interface IDriverRepository:IGenericRepository<Driver>

{
    Task<PaginatedResult<Driver>> GetAllAsync(int page, int size);
}

public class PaginatedResult<T>
{
    public IEnumerable<T> Data { get; set; } = Enumerable.Empty<T>();
    public int Page { get; set; }
    public int Size { get; set; }
    public int Total { get; set; }
}
