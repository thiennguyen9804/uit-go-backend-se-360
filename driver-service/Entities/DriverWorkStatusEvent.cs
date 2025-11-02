using System.ComponentModel.DataAnnotations;

namespace driver_service.Entities;

public class DriverWorkStatusEvent
{
    [Key]
    public Guid Id { get; set; }
    public Guid DriverId { get; set; }
    public virtual Driver Driver { get; set; }
    public WorkStatus WorkStatus { get; set; }
    public DateOnly Date { get; set; } = DateOnly.FromDateTime(DateTime.Now);
    public DateTime OnAt { get; set; } = DateTime.UtcNow;
    public DateTime? OffAt { get; set; }

}

public enum WorkStatus
{
    On,
    InTrip,
    Off
}