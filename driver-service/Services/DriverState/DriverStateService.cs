using System;
using System.Threading.Tasks;
using driver_service.Services.Redis;
using driver_service.Persistence.Repositories;
using driver_service.Entities;

namespace driver_service.Services.DriverState;

// Hybrid: use Redis for live state+locations; persist On/InTrip/Off events to SQL for audit
public class DriverStateService : IDriverStateService
{
    private readonly IRedisService _redis;
    private readonly IWorkStatusEventRepository _eventRepo;

    public DriverStateService(IRedisService redis, IWorkStatusEventRepository eventRepo)
    {
        _redis = redis;
        _eventRepo = eventRepo;
    }

    public async Task<DriverStateResult> ToggleWorkingStateAsync(string driverId, bool enabled)
    {
        // parse driver id once and reuse
        var driverGuid = Guid.Parse(driverId);

        if (enabled)
        {
            // turning on: require that latest event is Off (strict). If latest is not Off, throw. 
            var latestCheck = await _eventRepo.GetLatestByDriverIdAsync(driverGuid);
            if (latestCheck != null && latestCheck.WorkStatus != WorkStatus.Off)
            {
                throw new InvalidOperationException("Cannot turn on: latest work status is not Off.");
            }

            var evOn = new DriverWorkStatusEvent
            {
                Id = Guid.NewGuid(),  
                DriverId = driverGuid,
                WorkStatus = WorkStatus.On,
                OnAt = DateTime.UtcNow
            };
            await _eventRepo.AddAsync(evOn);

            return new DriverStateResult { Status = WorkStatus.On.ToString() };
        }

        // turning off: ensure driver is currently registered as free in geo index
        var isInFree = await _redis.IsInGeoSetAsync(driverId, "drivers:geo:free");
        if (!isInFree)
        {
            throw new InvalidOperationException("Driver is not marked as free in geo index; cannot turn off.");
        }

        // remove Redis state (includes removal from geo sets)
        await _redis.RemoveWorkingStateAsync(driverId);

    var latest = await _eventRepo.GetLatestByDriverIdAsync(driverGuid);
        if (latest != null)
        {
            latest.OffAt = DateTime.UtcNow;
            await _eventRepo.UpdateAsync(latest);
        }
        else
        {
            throw new InvalidOperationException("No prior On/InTrip event found for this driver; cannot record Off.");
        }

        return new DriverStateResult { Status = WorkStatus.Off.ToString() };
    }

    public async Task PostLocationAsync(string driverId,  double latitude, double longitude)
    {
        // check DB for latest status
        var driverGuid = Guid.Parse(driverId);
        var latest = await _eventRepo.GetLatestByDriverIdAsync(driverGuid);
        if (latest == null) throw new InvalidOperationException("No work-status found for driver; cannot stream location.");

        if (latest.WorkStatus != WorkStatus.On && latest.WorkStatus != WorkStatus.InTrip)
        {
            throw new InvalidOperationException("Driver is not in On or InTrip status; cannot stream location.");
        }

        // forward to Redis to update geo coordinate
        await _redis.AddOrUpdateLocationAsync(driverId, latitude, longitude);
    }
}
