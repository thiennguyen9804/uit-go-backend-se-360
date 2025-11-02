using System;
using System.Text.Json;
using System.Threading.Tasks;
using driver_service.Services.Redis;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace driver_service.Controllers;

[ApiController]
[Route("api/drivers/driver-state")]
public class DriverStateController : ControllerBase
{
    private readonly driver_service.Services.DriverState.IDriverStateService _service;
    private readonly driver_service.Services.Redis.IRedisService _redis;

    public DriverStateController(driver_service.Services.DriverState.IDriverStateService service, driver_service.Services.Redis.IRedisService redis)
    {
        _service = service;
        _redis = redis;
    }

    private string? GetDriverIdFromToken()
    {
        return User.Identity?.Name;
    }

    public class WorkingStateRequest { public bool Enabled { get; set; } }

    public class LocationRequest { 
        public double Latitude { get; set; } 
        public double Longitude { get; set; } 
    }

    [HttpPut("working-state")]
    [Authorize]
    public async Task<IActionResult> ToggleWorkingState([FromBody] WorkingStateRequest req)
    {
        var driverId = GetDriverIdFromToken();
        if (string.IsNullOrEmpty(driverId)) return Unauthorized();

        try
        {
            var res = await _service.ToggleWorkingStateAsync(driverId, req.Enabled);
            return Ok(new { status = res.Status, tripId = res.TripId });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
    [HttpGet("debug-token")]
    public IActionResult DebugToken()
    {
        return Ok(User.Claims.Select(c => new { c.Type, c.Value }));
    }

    [HttpPost("location")]
    [Authorize]
    public async Task<IActionResult> PostLocation([FromBody] LocationRequest req)
    {
        var driverId = GetDriverIdFromToken();
        if (string.IsNullOrEmpty(driverId)) return Unauthorized();
        if (req == null) return BadRequest(new { error = "invalid payload" });

        try
        {
            await _service.PostLocationAsync(driverId, req.Latitude, req.Longitude);
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
