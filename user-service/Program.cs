using Grpc.Net.Client.Web;
using user_service;
var builder = WebApplication.CreateBuilder(args);
AppContext.SetSwitch("System.Net.Http.SocketsHttpHandler.Http2UnencryptedSupport", true);

// Add services
builder.Services.AddControllers()

    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
    });
builder.Services.AddAppServices(builder.Configuration);
builder.Services.AddRouting(options => options.LowercaseUrls = true);
builder.Services.AddGrpcClient<ProtoContracts.Driver.GrpcDriverService.GrpcDriverServiceClient>(o =>
{
    o.Address = new Uri("http://driver-service:8386");
})
.ConfigureChannel(options =>
{
    options.HttpHandler = new SocketsHttpHandler
    {
        EnableMultipleHttp2Connections = true
    };
});


var app = builder.Build();

// Middlewares
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Ensure routing middleware is registered before CORS and authentication
app.UseRouting();
app.UseCors("AllowFrontend");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
// Seed admin
await app.SeedIdentityDataAsync(builder.Configuration);

app.Run();