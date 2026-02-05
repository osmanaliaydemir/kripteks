using System.Security.Claims;
using Kripteks.Infrastructure.Services;
using Kripteks.Core.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class ScannerController : ControllerBase
{
    private readonly ScannerService _scannerService;

    public ScannerController(ScannerService scannerService)
    {
        _scannerService = scannerService;
    }

    private string UserId => User.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;

    [HttpGet("favorites")]
    public async Task<ActionResult<List<ScannerFavoriteListDto>>> GetFavorites()
    {
        return Ok(await _scannerService.GetUserFavoritesAsync(UserId));
    }

    [HttpPost("favorites")]
    public async Task<ActionResult<Guid>> SaveFavorite([FromBody] SaveFavoriteListDto dto)
    {
        return Ok(await _scannerService.SaveFavoriteListAsync(UserId, dto));
    }

    [HttpDelete("favorites/{id}")]
    public async Task<ActionResult> DeleteFavorite(Guid id)
    {
        await _scannerService.DeleteFavoriteListAsync(UserId, id);
        return Ok();
    }

    [HttpPost("scan")]
    public async Task<ActionResult<ScannerResultDto>> Scan([FromBody] ScannerRequestDto request)
    {
        var result = await _scannerService.ScanAsync(request);
        return Ok(result);
    }
}
