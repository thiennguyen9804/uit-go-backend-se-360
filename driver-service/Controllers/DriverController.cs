using Microsoft.AspNetCore.Mvc;
using driver_service.Services;
using driver_service.Dtos;

namespace driver_service.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DriverController : BaseController
{
    private readonly IDriverService _service;

    public DriverController(IDriverService service)
    {
        _service = service;
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> Get(Guid id)
    {
        try
        {
            var d = await _service.GetByIdAsync(id);
            return Ok(d);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateDriverDto dto)
    {
        try
        {
            var created = await _service.CreateAsync(dto);
            return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateDriverDto dto)
    {
        try
        {
            var updated = await _service.UpdateAsync(id, dto);
            return Ok(updated);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int page = 1, [FromQuery] int size = 10)
    {
        try
        {
            var res = await _service.GetAllAsync(page, size);
            return Ok(res);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
