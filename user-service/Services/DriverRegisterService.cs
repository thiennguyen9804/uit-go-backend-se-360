using AutoMapper;
using user_service.Dtos;
using user_service.Entities;
using user_service.Repositories;
using user_service.Services.Interface;

namespace user_service.Services;

public class DriverRegisterService:IDriverRegisterService
{
    protected IDriverRegisterRepository _driverRegisterRepository;
    protected IIdentityService _identityService;

    public DriverRegisterService(IDriverRegisterRepository driverRegisterRepository, IMapper mapper, IIdentityService identityService)
    {
        _driverRegisterRepository = driverRegisterRepository;
        _mapper = mapper;
        _identityService = identityService;
    }

    protected IMapper _mapper;
    
    public async Task<DriverRegisterDto> GetByIdAsync(Guid id)
    {
        var driverRegister = await _driverRegisterRepository.GetUserDriverRegisterByIdAsync(id);
        if (driverRegister == null)
            throw new Exception("Driver register not found");
        return _mapper.Map<DriverRegisterDto>(driverRegister);
    }

    public async Task<DriverRegisterDto> CreateAsync(Guid userId, CreateDriverRegisterDto registerDriverrDto)
    {
        var register = await _driverRegisterRepository.GetLatestRegisterAsync(userId);
        if (register != null && register.Status != RegisterStatus.Rejected)
        {
            throw new Exception("You are having the pending register or already approved");
        }

        await _identityService.UpdateUserNameAsync(userId, registerDriverrDto.Name);
        var driverRegister = _mapper.Map<DriverRegister>(registerDriverrDto);
        driverRegister.UserId = userId;
        await _driverRegisterRepository.AddAsync(driverRegister);
        var dto = _mapper.Map<DriverRegisterDto>(driverRegister);
        dto.Name = registerDriverrDto.Name;
        return dto;
    }

    public async Task<PaginatedResult<DriverRegisterDto>> GetMyDriverRegistersAsync(Guid userId, PaginationRequest paginationRequest)
    {
        var registers = await _driverRegisterRepository.GetMyDriverRegistersAsync(userId, paginationRequest.Page, paginationRequest.Size);
        var dtos = registers.Data.Select(x => _mapper.Map<DriverRegisterDto>(x));
        return new PaginatedResult<DriverRegisterDto>
        {
            Data = dtos,
            Page = registers.Page,
            Size = registers.Size,
            Total = registers.Total
        };
    }

    public async Task<PaginatedResult<DriverRegisterDto>> GetAllDriverRegistersAsync(
        AllDriverRegistersPageRequest paginationRequest)
    {
        var registers = await _driverRegisterRepository.GetAllDriverRegistersAsync(paginationRequest.Page,
            paginationRequest.Size, paginationRequest.Status);
        var dtos = registers.Data.Select(x => _mapper.Map<DriverRegisterDto>(x));
        return new PaginatedResult<DriverRegisterDto>
        {
            Data = dtos,
            Page = registers.Page,
            Size = registers.Size,
            Total = registers.Total
        };
    }

    public async Task<DriverRegisterDto> UpdateAsync(Guid id, UpdateDriverRegisterDto updateRegisterDriverrDto)
    {
        var register = await  _driverRegisterRepository.GetUserDriverRegisterByIdAsync(id);
        if (register == null)
        {
            throw new Exception("Driver Register not found");
        }
        register.Status = updateRegisterDriverrDto.Status;
        register.UpdatedAt = DateTime.Now;
        await _driverRegisterRepository.UpdateAsync(register);
        // grpc call insert into driver service
        return _mapper.Map<DriverRegisterDto>(register);
    }
}