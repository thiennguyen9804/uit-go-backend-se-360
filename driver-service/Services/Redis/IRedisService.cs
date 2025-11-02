using System.Threading.Tasks;
using System.Collections.Generic;

namespace driver_service.Services.Redis;

public interface IRedisService
{
    //Task<bool> SetWorkingStateAsync(string driverId, string status, string? tripId = null);
    //Task<(string? tripId, string? status)> GetWorkingStateAsync(string driverId);
    Task<bool> RemoveWorkingStateAsync(string driverId);
    Task AddOrUpdateLocationAsync(string driverId, double latitude, double longitude);
    //Task AppendEventAsync(string driverId, string eventType, string payload);
    // Check whether a driver is present in a geo set (e.g. "drivers:geo:free")
    Task<bool> IsInGeoSetAsync(string driverId, string geoSet);
}
