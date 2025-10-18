using user_service.Entities;

namespace user_service.Dtos;


public class PaginatedResult<T>
{
    public IEnumerable<T> Data { get; set; }
    public int Total { get; set; }
    public int Page { get; set; }
    public int Size { get; set; }

}

public class PaginationRequest
{
    public int Page { get; set; } = 1;
    public int Size { get; set; } = 10;
}

public class AllDriverRegistersPageRequest : PaginationRequest
{
    public RegisterStatus  Status { get; set; }
}
