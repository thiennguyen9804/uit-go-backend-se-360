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
}