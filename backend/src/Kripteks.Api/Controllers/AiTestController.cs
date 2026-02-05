using Kripteks.Core.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AiTestController : ControllerBase
{
    private readonly IChatDevService _chatDevService;

    public AiTestController(IChatDevService chatDevService)
    {
        _chatDevService = chatDevService;
    }

    [HttpPost("chatdev-workflow")]
    public async Task<IActionResult> RunWorkflow([FromQuery] string workflow, [FromBody] string prompt)
    {
        var result = await _chatDevService.RunWorkflowAsync(workflow, prompt);
        return Ok(result);
    }

    [HttpPost("analyze-sentiment")]
    public async Task<IActionResult> AnalyzeSentiment([FromBody] string news)
    {
        var result = await _chatDevService.AnalyzeMarketSentimentAsync(news);
        return Ok(result);
    }
}
