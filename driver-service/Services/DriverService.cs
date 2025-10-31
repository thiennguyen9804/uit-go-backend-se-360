using AutoMapper;
using driver_service.Dtos;
using driver_service.Entities;
using driver_service.Persistence.Repositories;

namespace driver_service.Services;

public class DriverService : IDriverService
{
    private readonly IDriverRepository _repository;
    private readonly IMapper _mapper;
    private readonly ILogger<DriverService> _logger;

    public DriverService(IDriverRepository repository, IMapper mapper, ILogger<DriverService> logger)
    {
        _repository = repository;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<DriverDto> GetByIdAsync(Guid id)
    {
        try
        {
            var d = await _repository.GetByIdAsync(id);
            if (d == null) throw new Exception("Driver not found");
            return _mapper.Map<DriverDto>(d);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "GetByIdAsync failed for {id}", id);
            throw;
        }
    }

    public async Task<DriverDto> CreateAsync(CreateDriverDto dto)
    {
        try
        {
            var entity = _mapper.Map<Driver>(dto);
            await _repository.AddAsync(entity);
            return _mapper.Map<DriverDto>(entity);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CreateAsync failed");
            throw;
        }
    }

    public async Task<DriverDto> UpdateAsync(Guid id, UpdateDriverDto dto)
    {
        try
        {
            var existing = await _repository.GetByIdAsync(id);
            if (existing == null) throw new Exception("Driver not found");
            if (!string.IsNullOrEmpty(dto.VehicleNumber)) existing.VehicleNumber = dto.VehicleNumber;
            if (!string.IsNullOrEmpty(dto.VehicleType)) existing.VehicleType = dto.VehicleType;
            existing.UpdatedAt = DateTime.UtcNow;
            await _repository.UpdateAsync(existing);
            return _mapper.Map<DriverDto>(existing);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "UpdateAsync failed for {id}", id);
            throw;
        }
    }

    public async Task<PaginatedResult<driver_service.Entities.Driver>> GetAllAsync(int page, int size)
    {
        try
        {
            return await _repository.GetAllAsync(page, size);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "GetAllAsync failed");
            throw;
        }
    }
}
