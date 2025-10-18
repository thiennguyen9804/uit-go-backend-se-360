namespace user_service.Entities;

public class DriverRegister:BaseEntity
{
    public required string VehicleNumber {get; set;}
    public VehicleType VehicleType { get; set; }
    public RegisterStatus Status { get; set; } = RegisterStatus.Pending;
    public Guid UserId { get; set; }
    public virtual ApplicationUser User { get; set; }
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