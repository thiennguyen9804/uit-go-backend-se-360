
using System.Reflection;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using user_service.Dtos;
using user_service.Entities;
using user_service.Service;
using user_service.Persistence;
using user_service.Mapping;

namespace user_service;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddAppServices(this IServiceCollection services, IConfiguration config)
    {
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(config.GetConnectionString("DefaultConnection"),
                sqlOptions => sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 5,            
                    maxRetryDelay: TimeSpan.FromSeconds(10),  
                    errorNumbersToAdd: null      
                )));

        services.AddIdentity<ApplicationUser, IdentityRole>()
            .AddEntityFrameworkStores<ApplicationDbContext>()
            .AddDefaultTokenProviders();

        var jwtSection = config.GetSection("Jwt");
        var key = Encoding.UTF8.GetBytes(jwtSection["Key"] ?? "super_secret_key");

        // Ensure JWT is the default authentication and challenge scheme for API endpoints
        services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultSignInScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(opt =>
            {
                opt.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateIssuerSigningKey = true,
                    ValidateLifetime = true,
                    ValidIssuer = jwtSection["Issuer"],
                    ValidAudience = jwtSection["Audience"],
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ClockSkew = TimeSpan.Zero
                };
            });

        // Prevent Identity cookie authentication from redirecting API calls to the login page
        services.ConfigureApplicationCookie(options =>
        {
            options.Events.OnRedirectToLogin = ctx =>
            {
                if (ctx.Request.Path.StartsWithSegments("/api") || ctx.Request.Path.StartsWithSegments(new PathString("/api")))
                {
                    ctx.Response.StatusCode = StatusCodes.Status401Unauthorized;
                    return Task.CompletedTask;
                }
                ctx.Response.Redirect(ctx.RedirectUri);
                return Task.CompletedTask;
            };
            options.Events.OnRedirectToAccessDenied = ctx =>
            {
                if (ctx.Request.Path.StartsWithSegments("/api") || ctx.Request.Path.StartsWithSegments(new PathString("/api")))
                {
                    ctx.Response.StatusCode = StatusCodes.Status403Forbidden;
                    return Task.CompletedTask;
                }
                ctx.Response.Redirect(ctx.RedirectUri);
                return Task.CompletedTask;
            };
        });

        services.AddCors(options =>
        {
               options.AddPolicy("AllowAllOrigins", policy =>
                {
                    policy
                        .AllowAnyOrigin()    
                        .AllowAnyMethod()
                        .AllowAnyHeader();
                });
        });

        services.AddEndpointsApiExplorer();
        services.AddSwaggerGen(opt =>
        {
            var jwtScheme = new OpenApiSecurityScheme
            {
                Name = "Authorization",
                Type = SecuritySchemeType.Http,
                Scheme = "bearer",
                BearerFormat = "JWT",
                In = ParameterLocation.Header,
                Reference = new OpenApiReference
                {
                    Id = JwtBearerDefaults.AuthenticationScheme,
                    Type = ReferenceType.SecurityScheme
                }
            };

            opt.AddSecurityDefinition(jwtScheme.Reference.Id, jwtScheme);
            opt.AddSecurityRequirement(new OpenApiSecurityRequirement
            {
                { jwtScheme, Array.Empty<string>() }
            });
        });
        services.AddAutoMapper(typeof(MappingProfile).Assembly);

        services.AddServices(config)
            .AddPersistences(config);

        // Unit of Work
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddAuthorization(options =>
        {
        });

        return services;
    }

    public static async Task SeedIdentityDataAsync(this IApplicationBuilder app, IConfiguration config)
    {
        using var scope = app.ApplicationServices.CreateScope();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();

        foreach (var roleName in Enum.GetNames(typeof(AppRole)))
        {
            if (!await roleManager.RoleExistsAsync(roleName))
                await roleManager.CreateAsync(new IdentityRole(roleName));
        }

        var adminEmail = config["SeedAdmin:Email"] ?? "admin@local.com";
        var adminPassword = config["SeedAdmin:Password"] ?? "Admin@123";

        var admin = await userManager.FindByEmailAsync(adminEmail);
        if (admin == null)
        {
            admin = new ApplicationUser
            {
                UserName = adminEmail,
                Email = adminEmail,
                EmailConfirmed = true
            };
            var result = await userManager.CreateAsync(admin, adminPassword);
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(admin, nameof(AppRole.Admin));
            }
        }
        else
        {
            var roles = await userManager.GetRolesAsync(admin);
            if (!roles.Contains(nameof(AppRole.Admin)))
                await userManager.AddToRoleAsync(admin, nameof(AppRole.Admin));
        }
    }

}
