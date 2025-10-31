namespace user_service.Entities;

public class DriverRegister:BaseEntity
{
    public required string VehicleNumber {get; set;}
    public VehicleType VehicleType { get; set; }
    public RegisterStatus Status { get; set; } = RegisterStatus.Pending;
    // Identity uses string keys by default (ApplicationUser.Id is string).
    // Store UserId as string so EF can correctly wire the navigation property.
    public string UserId { get; set; }
    public virtual ApplicationUser? User { get; set; }
}

public enum VehicleType
{
    SmallCar,
    Motor,
    BigCar
}

public enum RegisterStatus
{
    Approved,
    Pending,
    Rejected,
    All
}