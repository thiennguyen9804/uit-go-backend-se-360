using AutoMapper;
using user_service.Dtos;
using user_service.Entities;
using user_service.GrpcClient;
using user_service.Repositories;
using user_service.Persistence;
using user_service.Services.Interface;

namespace user_service.Services;

public class DriverRegisterService:IDriverRegisterService
{
    protected IDriverRegisterRepository _driverRegisterRepository;
    protected IIdentityService _identityService;
    protected DriverGrpcClient _driverGrpcClient;
    protected IUnitOfWork _unitOfWork;

    public DriverRegisterService(
        IDriverRegisterRepository driverRegisterRepository, 
        IMapper mapper, 
        IIdentityService identityService,
        DriverGrpcClient driverGrpcClient,
        IUnitOfWork unitOfWork)
    {
        _driverRegisterRepository = driverRegisterRepository;
    _mapper = mapper;
    _identityService = identityService;
        _driverGrpcClient = driverGrpcClient;
        _unitOfWork = unitOfWork;
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

        await _identityService.UpdateUserContactAsync(userId, registerDriverrDto.Name, registerDriverrDto.PhoneNumber);
    var driverRegister = _mapper.Map<DriverRegister>(registerDriverrDto);
    // ApplicationUser.Id is a string (Identity). store the Guid as string so EF can link the navigation.
    driverRegister.UserId = userId.ToString();
        await _driverRegisterRepository.AddAsync(driverRegister);
        var dto = _mapper.Map<DriverRegisterDto>(driverRegister);
        dto.Name = registerDriverrDto.Name;
        dto.PhoneNumber = registerDriverrDto.PhoneNumber;
        return dto;
    }

    public async Task<PaginatedResult<DriverRegisterDto>> GetMyDriverRegistersAsync(Guid userId, PaginationRequest paginationRequest)
    {
        var registers = await _driverRegisterRepository.GetMyDriverRegistersAsync(userId, paginationRequest.Page, paginationRequest.Size);
        var dtos = registers.Data.Select(x =>
        {
            Console.WriteLine($"{x.User?.FullName} : {x.User?.PhoneNumber} ");
            return _mapper.Map<DriverRegisterDto>(x);
        }).ToList();
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

        await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            register.Status = updateRegisterDriverrDto.Status;
            register.UpdatedAt = DateTime.Now;
            await _driverRegisterRepository.UpdateAsync(register);

            var grpcSuccess = await _driverGrpcClient.CreateDriverAsync(register);
            if (!grpcSuccess)
                throw new Exception("Driver service reported failure creating driver");
        });

        return _mapper.Map<DriverRegisterDto>(register);
    }
}