using System.Threading.Tasks;

namespace driver_service.Services.DriverState;

public interface IDriverStateService
{
    Task<DriverStateResult> ToggleWorkingStateAsync(string driverId, bool enabled);
    Task PostLocationAsync(string driverId, double latitude, double longitude);
}

public class DriverStateResult
{
    public string Status { get; set; } = string.Empty;
    public string? TripId { get; set; }
}
