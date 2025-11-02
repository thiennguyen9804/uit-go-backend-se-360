using driver_service.Persistence.EFRepositories;
using driver_service.Persistence.Repositories;
using driver_service.Services;

namespace driver_service;

public static class DependencyInjection
{
    public static IServiceCollection AddPersistences(this IServiceCollection services, IConfiguration config)
    {
        services.AddScoped<IDriverRepository, DriverRepository>();
        services.AddScoped<driver_service.Persistence.Repositories.IWorkStatusEventRepository, driver_service.Persistence.EFRepositories.WorkStatusEventRepository>();
        return services;
    }

    public static IServiceCollection AddServices(this IServiceCollection services, IConfiguration config)
    {
        services.AddScoped<IDriverService, DriverService>();
        services.AddScoped<driver_service.Services.DriverState.IDriverStateService, driver_service.Services.DriverState.DriverStateService>();
        return services;
    }
}
