namespace Kripteks.Core.Entities;

public class Log
{
    public int Id { get; set; } // Loglar çok fazla olabilir o yüzden int/long daha performanslı olabilir, ama tutarlılık için Guid de olur. Int yapalım.
    public Guid BotId { get; set; }
    public string Message { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public LogLevel Level { get; set; } = LogLevel.Info;
}

public enum LogLevel
{
    Info,
    Warning,
    Error
}
