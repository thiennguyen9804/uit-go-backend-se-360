using AutoMapper;
using user_service.Dtos;
using user_service.Entities;

namespace user_service.Mapping;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<CreateDriverRegisterDto, DriverRegister>()
            .ForMember(dest => dest.CreatedAt, opt => opt.MapFrom(_ => DateTime.Now))
            .ForMember(dest => dest.Status, opt => opt.MapFrom(_ => RegisterStatus.Pending));
        CreateMap<DriverRegister, DriverRegisterDto>()
            .ForMember(src=>src.Name,optn=>optn.MapFrom(src=>src.User.UserName))
            .ForMember(src=>src.UpdatedAt,optn=>optn.MapFrom(src=>src.UpdatedAt ?? src.CreatedAt));

    }
}
