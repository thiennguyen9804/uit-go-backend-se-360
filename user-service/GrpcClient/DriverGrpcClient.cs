using AutoMapper;
using ProtoContracts.Driver;
using user_service.Entities;

namespace user_service.GrpcClient;

public class DriverGrpcClient
{
    private readonly GrpcDriverService.GrpcDriverServiceClient _client;
    private readonly IMapper _mapper;

    public DriverGrpcClient(GrpcDriverService.GrpcDriverServiceClient client,IMapper mapper)
    {
        _client = client;
        _mapper = mapper;
    }

    public async Task<bool> CreateDriverAsync(DriverRegister driverRegister)
    {
        var request = _mapper.Map<CreateDriverRequest>(driverRegister);
        var reply = await _client.CreateDriverAsync(request);
        return reply.Success;
    }
}