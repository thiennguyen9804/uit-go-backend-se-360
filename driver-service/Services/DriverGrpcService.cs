using AutoMapper;
using driver_service.Entities;
using driver_service.Persistence.Repositories;
using Google.Protobuf.WellKnownTypes;
using Grpc.Core;
using ProtoContracts.Driver;

public class DriverGrpcService : GrpcDriverService.GrpcDriverServiceBase
{
    private IDriverRepository _driverRepository;

    public DriverGrpcService(IDriverRepository driverRepository, IMapper mapper)
    {
        _driverRepository = driverRepository;
        _mapper = mapper;
    }

    private IMapper _mapper;
    public override async Task<CreateDriverReply> CreateDriver(CreateDriverRequest request, ServerCallContext context)
    {
        var driver = _mapper.Map<CreateDriverRequest, Driver>(request);
        await _driverRepository.AddAsync(driver);
        return new CreateDriverReply
        {
            Success = true,
            Message = "Driver created successfully",
            Id = driver.Id.ToString(),
            CreatedAt = Timestamp.FromDateTime(driver.CreatedAt)
        };

    }

    public override async Task<GetDriverReply> GetDriver(GetDriverRequest request, ServerCallContext context)
    {
        if (string.IsNullOrEmpty(request.Id))
        {
            return new GetDriverReply { Found = false };
        }

        if (!Guid.TryParse(request.Id, out var guid))
        {
            return new GetDriverReply { Found = false };
        }

        var driver = await _driverRepository.GetByIdAsync(guid);
        if (driver == null)
        {
            return new GetDriverReply { Found = false };
        }

        return new GetDriverReply
        {
            Found = true,
            Id = driver.Id.ToString(),
            Name = driver.Name ?? string.Empty,
            PhoneNumber = driver.PhoneNumber ?? string.Empty,
            VehicleNumber = driver.VehicleNumber ?? string.Empty,
            VehicleType = driver.VehicleType ?? string.Empty,
            CreatedAt = Timestamp.FromDateTime(driver.CreatedAt)
        };
    }
}