using System.Threading.Tasks;
using driver_service.Entities;
using driver_service.Persistence.Repositories;
using Microsoft.EntityFrameworkCore;

namespace driver_service.Persistence.EFRepositories;

public class WorkStatusEventRepository : GenericRepository<DriverWorkStatusEvent>, IWorkStatusEventRepository
{
    public WorkStatusEventRepository(ApplicationDbContext context, ILogger<DriverWorkStatusEvent> logger) : base(context, logger)
    {
    }

    
    public async Task<DriverWorkStatusEvent?> GetLatestByDriverIdAsync(Guid driverId)
    {
        return await _dbSet.OrderByDescending(e => e.OnAt).FirstOrDefaultAsync(e => e.DriverId == driverId);
    }
    
    public async Task<DriverWorkStatusEvent> UpdateAsync(DriverWorkStatusEvent ev)
    {
        _dbSet.Update(ev);
        await _context.SaveChangesAsync();
        return ev;
    }
}
