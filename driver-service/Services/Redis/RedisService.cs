using System;
using System.Text.Json;
using System.Threading.Tasks;
using StackExchange.Redis;

namespace driver_service.Services.Redis;

public class RedisService : IRedisService
{
    private readonly IConnectionMultiplexer _mux;
    private readonly IDatabase _db;

    public RedisService(IConnectionMultiplexer mux)
    {
        _mux = mux;
        _db = _mux.GetDatabase();
    }


    public async Task<bool> RemoveWorkingStateAsync(string driverId)
    {
        // remove from geo indices as driver is no longer available
        await _db.SortedSetRemoveAsync("drivers:geo:free", driverId).ConfigureAwait(false);
        await _db.SortedSetRemoveAsync("drivers:geo:intrip", driverId).ConfigureAwait(false);
        return true;
    }

    public async Task AddOrUpdateLocationAsync(string driverId, double latitude, double longitude)
    {
        // GEOADD only stores member + coordinates. We maintain two GEO sets: free and intrip.
        var isInTrip = (await _db.SortedSetScoreAsync("drivers:geo:intrip", driverId).ConfigureAwait(false)).HasValue;

        if (isInTrip)
        {
            // update coords in intrip geo set
            await _db.GeoAddAsync("drivers:geo:intrip", longitude, latitude, driverId).ConfigureAwait(false);
            // ensure driver not present in free set
            await _db.SortedSetRemoveAsync("drivers:geo:free", driverId).ConfigureAwait(false);
        }
        else
        {
            // update coords in free geo set
            await _db.GeoAddAsync("drivers:geo:free", longitude, latitude, driverId).ConfigureAwait(false);
            // ensure driver not present in intrip set
            await _db.SortedSetRemoveAsync("drivers:geo:intrip", driverId).ConfigureAwait(false);
        }
    }

    public async Task<bool> IsInGeoSetAsync(string driverId, string geoSet)
    {
        var score = await _db.SortedSetScoreAsync(geoSet, driverId).ConfigureAwait(false);
        return score.HasValue;
    }
}

