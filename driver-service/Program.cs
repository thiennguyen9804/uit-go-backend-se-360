using driver_service;
using Microsoft.EntityFrameworkCore;
using driver_service.Persistence;
using Microsoft.AspNetCore.Server.Kestrel.Core;

var builder = WebApplication.CreateBuilder(args);
AppContext.SetSwitch("System.Net.Http.SocketsHttpHandler.Http2UnencryptedSupport", true);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
// Register gRPC services
builder.Services.AddGrpc();
var configuration = builder.Configuration;

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sqlOptions => sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 5,            
            maxRetryDelay: TimeSpan.FromSeconds(10),  
            errorNumbersToAdd: null      
        )
    )
);


builder.Services.AddAutoMapper(typeof(driver_service.Mapping.MappingProfile));
// Register persistence and services via extensions
builder.Services.AddPersistences(configuration);
builder.Services.AddServices(configuration);

var app = builder.Build();

// Apply EF Core migrations at startup to ensure the driver-service database exists
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var db = services.GetRequiredService<ApplicationDbContext>();
        db.Database.Migrate();
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "An error occurred while migrating or initializing the database.");
        throw;
    }
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();
app.UseRouting();
app.UseAuthorization();
app.MapControllers();
app.MapGrpcService<DriverGrpcService>();
app.MapGet("/", () => "Driver service running (REST:8081, gRPC:8386)");
// Ensure the app listens on port 8081 by default
// var urls = configuration["ASPNETCORE_URLS"] ?? "http://0.0.0.0:8081";
// app.Urls.Clear();
// app.Urls.Add(urls);

app.Run();

