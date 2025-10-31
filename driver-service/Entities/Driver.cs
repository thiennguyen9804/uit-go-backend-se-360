using System.ComponentModel.DataAnnotations;

namespace driver_service.Entities;

public class Driver
{
    [Key]
    public Guid Id { get; set; }

    public string Name { get; set; } = string.Empty;

    public string PhoneNumber { get; set; } = string.Empty;

    public string VehicleNumber { get; set; } = string.Empty;
    public string VehicleType { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public virtual List<DriverWorkStatusEvent> DriverWorkStatusEvents { get; set; } = new List<DriverWorkStatusEvent>();
}
