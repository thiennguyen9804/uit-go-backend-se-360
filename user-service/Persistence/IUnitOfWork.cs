using Microsoft.EntityFrameworkCore.Storage;

namespace user_service.Persistence;


public interface IUnitOfWork : IAsyncDisposable
{
    Task BeginTransactionAsync();
    Task CommitAsync();
    Task RollbackAsync();
    Task<int> SaveChangesAsync();
    Task ExecuteInTransactionAsync(Func<Task> operation);
    Task<T> ExecuteInTransactionAsync<T>(Func<Task<T>> operation);

}
