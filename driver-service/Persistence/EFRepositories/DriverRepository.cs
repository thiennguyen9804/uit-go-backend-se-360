using Microsoft.EntityFrameworkCore;
using driver_service.Entities;
using driver_service.Persistence;
using driver_service.Persistence.Repositories;

namespace driver_service.Persistence.EFRepositories;

public class DriverRepository : GenericRepository<Driver>, IDriverRepository
{
    public DriverRepository(ApplicationDbContext context, ILogger<Driver> logger) : base(context, logger)
    {
    }

    public override async Task<Driver?> GetByIdAsync(Guid id)
    {
        return await _dbSet.FirstOrDefaultAsync(d => d.Id == id);
    }

    public async Task AddAsync(Driver driver)
    {
        await AddAsync((Driver)(object)driver);
    }

    public async Task UpdateAsync(Driver driver)
    {
        await UpdateAsync((Driver)(object)driver);
    }

    public async Task<PaginatedResult<Driver>> GetAllAsync(int page, int size)
    {
        var query = _dbSet.OrderByDescending(d => d.CreatedAt).AsQueryable();
        var total = await query.CountAsync();
        var items = await query.Skip((page - 1) * size).Take(size).ToListAsync();
        return new PaginatedResult<Driver>
        {
            Data = items,
            Page = page,
            Size = size,
            Total = total
        };
    }
}
