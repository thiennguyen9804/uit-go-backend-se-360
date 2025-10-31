using user_service.Services;
using user_service.Services.Interface;

namespace user_service.Service;

public static class DependencyInjection
{
    public static IServiceCollection AddServices(this IServiceCollection services,IConfiguration config)
    {
        services.AddScoped<IJwtService, JwtService>();
        services.AddScoped<IIdentityService, IdentityService>();
        services.AddScoped<IEmailService>(sp =>
            new SmtpEmailService(
                config["SeedAdmin:Email"],
                "sandbox.smtp.mailtrap.io",
                2525,
                config["Mailtrap:Username"],
                config["Mailtrap:Password"]
            ));
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<GrpcClient.DriverGrpcClient>();
        services.AddScoped<IDriverRegisterService, DriverRegisterService>();
        return services;
    }
}