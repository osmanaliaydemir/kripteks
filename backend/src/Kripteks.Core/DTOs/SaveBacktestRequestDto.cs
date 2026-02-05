namespace Kripteks.Core.DTOs;

public class SaveBacktestRequestDto
{
    public BacktestRequestDto Request { get; set; } = new();
    public BacktestResultDto Result { get; set; } = new();
}
