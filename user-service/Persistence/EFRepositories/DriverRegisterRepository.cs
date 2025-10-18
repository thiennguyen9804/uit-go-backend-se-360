using Microsoft.EntityFrameworkCore;
using user_service.Dtos;
using user_service.Entities;
using user_service.Repositories;

namespace user_service.EFRepository;

public class DriverRegisterRepository:GenericRepository<DriverRegister>,IDriverRegisterRepository
{
    public DriverRegisterRepository(ApplicationDbContext context, ILogger<DriverRegister> logger) : base(context, logger)
    {
    }

    public async Task<DriverRegister?> GetUserDriverRegisterByIdAsync(Guid id)
    {
        return  _dbSet.Include(dr=>dr.User)
            .FirstOrDefault(dr=>dr.Id == id);
    }

    public async Task<DriverRegister?> GetLatestRegisterAsync(Guid userId)
    {
        return await _dbSet
            .Include(dr => dr.User)
            .Where(dr => dr.UserId == userId)
            .OrderByDescending(dr => dr.CreatedAt) 
            .FirstOrDefaultAsync();
    }

    public async Task<PaginatedResult<DriverRegister>> GetMyDriverRegistersAsync(
        Guid userId,
        int paginationRequestPage,
        int paginationRequestSize)
    {
        var query = _dbSet
            .Include(dr => dr.User)
            .Where(dr => dr.UserId == userId)
            .OrderByDescending(dr => dr.CreatedAt);

        var totalCount = await query.CountAsync();

        var items = await query
            .Skip((paginationRequestPage - 1) * paginationRequestSize)
            .Take(paginationRequestSize)
            .ToListAsync();

        return new PaginatedResult<DriverRegister>
        {
            Page = paginationRequestPage,
            Size = paginationRequestSize,
            Total = totalCount,
            Data = items
        };
    }


    public async Task<PaginatedResult<DriverRegister>> GetAllDriverRegistersAsync(
        int paginationRequestPage,
        int paginationRequestSize,
        RegisterStatus paginationRequestStatus)
    {
        var query = _dbSet
            .Include(dr => dr.User)
            .AsQueryable();

        if (paginationRequestStatus != RegisterStatus.All)
            query = query.Where(dr => dr.Status == paginationRequestStatus);

        query = query.OrderByDescending(dr => dr.CreatedAt);

        var totalCount = await query.CountAsync();

        var items = await query
            .Skip((paginationRequestPage - 1) * paginationRequestSize)
            .Take(paginationRequestSize)
            .ToListAsync();

        return new PaginatedResult<DriverRegister>
        {
            Page = paginationRequestPage,
            Size = paginationRequestSize,
            Total = totalCount,
            Data = items
        };
    }

}