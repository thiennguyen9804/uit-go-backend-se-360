using System.ComponentModel.DataAnnotations;

namespace user_service.Entities;

public abstract class BaseEntity
{
    [Key]
    public Guid Id { get; set; } 
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    public DateTime? DeletedAt { get; set; }
    
    public bool IsDeleted { get; set; } = false;


}