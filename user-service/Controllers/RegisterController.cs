
using user_service.Dtos;
using user_service.Services.Interface;

namespace user_service.Controllers;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;



[ApiController]
[Route("api/user/driver-register")]
public class RegisterController : BaseController
{
    private readonly IDriverRegisterService _driverRegisterService;

    public RegisterController(IDriverRegisterService driverRegisterService)
    {
        _driverRegisterService = driverRegisterService;
    }

    [HttpGet("{id:guid}")]
    [Authorize]
    public async Task<IActionResult> GetById(Guid id)
    {
        if(!ModelState.IsValid)
            return BadRequest(ModelState);
        try
        {
            var register = await _driverRegisterService.GetByIdAsync(id);
            return Ok(register);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet("my")]
    [Authorize]
    public async Task<IActionResult> GetMyDriverRegisters([FromQuery] PaginationRequest request)
    {
        if(!ModelState.IsValid)
            return BadRequest(ModelState);
        try
        {
            var userId = GetCurrentUserId();
            if (userId == Guid.Empty)
                return Unauthorized("User not authenticated");

            var result = await _driverRegisterService.GetMyDriverRegistersAsync(userId, request);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost]
    [Authorize(Roles = nameof(AppRole.User))]
    public async Task<IActionResult> Create([FromBody] CreateDriverRegisterDto dto)
    {
        if(!ModelState.IsValid)
            return BadRequest(ModelState);
        try
        {
            var userId = GetCurrentUserId();
            if (userId == Guid.Empty)
                return Unauthorized("User not authenticated");

            var result = await _driverRegisterService.CreateAsync(userId, dto);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = nameof(AppRole.Admin))]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateDriverRegisterDto dto)
    {
        if(!ModelState.IsValid)
            return BadRequest(ModelState);
        try
        {
            var result = await _driverRegisterService.UpdateAsync(id, dto);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet("all")]
    [Authorize(Roles = nameof(AppRole.Admin))]
    public async Task<IActionResult> GetAll([FromQuery] AllDriverRegistersPageRequest request)
    {
        if(!ModelState.IsValid)
            return BadRequest(ModelState);
        try
        {
            var result = await _driverRegisterService.GetAllDriverRegistersAsync(request);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }
}
