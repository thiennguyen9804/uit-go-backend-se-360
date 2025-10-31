using user_service.Entities;

namespace user_service.Dtos;

public class DriverRegisterDto 
{
    public Guid Id { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public RegisterStatus Status { get; set; } = RegisterStatus.Pending;
    public string UserId { get; set; }
    public string VehicleNumber { get; set; }
    public string PhoneNumber { get; set; }

    public VehicleType VehicleType { get; set; }
    public string Name { get; set; }
}

public class UpdateDriverRegisterDto
{
    public RegisterStatus Status { get; set; }
}

public class CreateDriverRegisterDto
{
    public VehicleType  VehicleType { get; set; }
    public required string PhoneNumber { get; set; }
    public required string VehicleNumber { get; set; }
    public required string Name { get; set; }
}