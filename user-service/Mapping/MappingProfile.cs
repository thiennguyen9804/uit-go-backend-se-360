using AutoMapper;
using ProtoContracts.Driver;
using user_service.Dtos;
using user_service.Entities;

namespace user_service.Mapping;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<string, Guid>().ConvertUsing(s => Guid.Parse(s));
        CreateMap<Guid, string>().ConvertUsing(g => g.ToString());

        CreateMap<CreateDriverRegisterDto, DriverRegister>()
            .ForMember(dest => dest.CreatedAt, opt => opt.MapFrom(_ => DateTime.Now))
            .ForMember(dest => dest.Status, opt => opt.MapFrom(_ => RegisterStatus.Pending));
        CreateMap<DriverRegister, DriverRegisterDto>()
            .ForMember(dest => dest.UserId, optn => optn.MapFrom(src => $"{src.UserId}"))
            .ForMember(dest => dest.Name, optn => optn.MapFrom(src => src.User != null ? src.User.FullName : null))
            .ForMember(dest => dest.PhoneNumber, optn => optn.MapFrom(src => src.User != null ? src.User.PhoneNumber : null))
            .ForMember(dest => dest.UpdatedAt, optn => optn.MapFrom(src => src.UpdatedAt ?? src.CreatedAt));
        CreateMap<DriverRegister, CreateDriverRequest>()
            .ForMember(dest => dest.Id, opt => opt.MapFrom(src => $"{src.UserId}"))
            .ForMember(dest => dest.Name, opt => opt.MapFrom(src => src.User != null ? src.User.FullName : null))
            .ForMember(dest => dest.PhoneNumber, opt => opt.MapFrom(src => src.User != null ? src.User.PhoneNumber : null));

    }
}
