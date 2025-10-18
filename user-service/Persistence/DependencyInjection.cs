using user_service.EFRepository;
using user_service.Repositories;

namespace user_service;

public static class DependencyInjection
{
    public static IServiceCollection AddPersistences(this IServiceCollection services,IConfiguration config)
    {
        services.AddScoped<IDriverRegisterRepository, DriverRegisterRepository>();
        return services;
    }
}