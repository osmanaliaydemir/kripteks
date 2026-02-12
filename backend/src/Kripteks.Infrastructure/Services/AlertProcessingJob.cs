using Kripteks.Core.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

public class AlertProcessingJob : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<AlertProcessingJob> _logger;

    public AlertProcessingJob(IServiceProvider serviceProvider, ILogger<AlertProcessingJob> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Alert Processing Job started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using (var scope = _serviceProvider.CreateScope())
                {
                    var alertService = scope.ServiceProvider.GetRequiredService<IAlertService>();
                    await alertService.ProcessAlertsAsync();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while processing alerts.");
            }

            // Run every 10 seconds
            await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
        }
    }
}
