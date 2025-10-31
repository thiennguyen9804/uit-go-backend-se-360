using AutoMapper;
using driver_service.Dtos;
using driver_service.Entities;
using ProtoContracts.Driver;

namespace driver_service.Mapping;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<Driver, DriverDto>().ReverseMap();
        CreateMap<CreateDriverDto, Driver>();
        CreateMap<CreateDriverRequest, Driver>()
            .ForMember(dest=>dest.Id, opt=>opt.MapFrom(src=>Guid.Parse(src.Id)))
            .ForMember(dest=>dest.CreatedAt,opt=>opt.MapFrom(_=>DateTime.UtcNow));
    }
}
