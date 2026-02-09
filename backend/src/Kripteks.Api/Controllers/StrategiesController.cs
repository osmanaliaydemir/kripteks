using Kripteks.Core.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class StrategiesController : ControllerBase
{
    private readonly IStrategyFactory _strategyFactory;

    public StrategiesController(IStrategyFactory strategyFactory)
    {
        _strategyFactory = strategyFactory;
    }

    [HttpGet]
    public IActionResult GetStrategies([FromQuery] string? category = null)
    {
        IEnumerable<IStrategy> strategies;

        if (!string.IsNullOrWhiteSpace(category) &&
            Enum.TryParse<StrategyCategory>(category, ignoreCase: true, out var parsedCategory))
        {
            strategies = _strategyFactory.GetStrategiesByCategory(parsedCategory);
        }
        else
        {
            strategies = _strategyFactory.GetAllStrategies();
        }

        var result = strategies.Select(s => new
        {
            id = s.Id,
            name = s.Name,
            description = s.Description,
            category = s.Category.ToString().ToLowerInvariant()
        });

        return Ok(result);
    }

    [HttpGet("{id}")]
    public IActionResult GetStrategy(string id)
    {
        try
        {
            var strategy = _strategyFactory.GetStrategy(id);

            return Ok(new
            {
                id = strategy.Id,
                name = strategy.Name,
                description = strategy.Description,
                category = strategy.Category.ToString().ToLowerInvariant()
            });
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = $"'{id}' ID'sine sahip strateji bulunamadı." });
        }
    }
}
