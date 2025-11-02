using System;
using System.Threading.Tasks;
using driver_service.Entities;

namespace driver_service.Persistence.Repositories;

public interface IWorkStatusEventRepository:IGenericRepository<DriverWorkStatusEvent>
{
    Task<DriverWorkStatusEvent?> GetLatestByDriverIdAsync(Guid driverId);
    Task<DriverWorkStatusEvent> UpdateAsync(DriverWorkStatusEvent ev);
}
