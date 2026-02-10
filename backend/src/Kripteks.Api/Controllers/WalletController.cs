using Kripteks.Core.DTOs;
using Kripteks.Core.Entities;
using Kripteks.Core.Extensions;
using Kripteks.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class WalletController : ControllerBase
{
    private readonly AppDbContext _context;

    public WalletController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetWallet()
    {
        var wallet = await _context.Wallets.FirstOrDefaultAsync();

        // Cüzdan yoksa varsayılan oluştur
        if (wallet == null)
        {
            wallet = new Wallet { Balance = 10000, LockedBalance = 0 }; // 10k Başlangıç
            _context.Wallets.Add(wallet);
            await _context.SaveChangesAsync();
        }

        // Aktif PNL Hesapla (Running Botlardan)
        var totalActivePnl = await _context.Bots
            .Where(b => b.Status == BotStatus.Running)
            .SumAsync(b => b.CurrentPnl);

        // Self-Healing: Check if LockedBalance matches actual active bots
        var actualLocked = await _context.Bots
            .Where(b => b.Status == BotStatus.Running ||
                        (b.Status == BotStatus.WaitingForEntry && b.StrategyName == "strategy-market-buy"))
            .SumAsync(b => b.Amount);

        if (wallet.LockedBalance != actualLocked)
        {
            // Adjust Balance to absorb difference, preserving Total Balance
            // If Locked was high (600) and Actual is low (0), we release 600 to Balance.
            wallet.Balance += (wallet.LockedBalance - actualLocked);
            wallet.LockedBalance = actualLocked;
            await _context.SaveChangesAsync();
        }

        return Ok(new
        {
            current_balance =
                wallet.Balance + wallet.LockedBalance + totalActivePnl, // Toplam Varlık (Cüzdan + Bloke + Kar/Zarar)
            available_balance = wallet.AvailableBalance,
            locked_balance = wallet.LockedBalance,
            total_pnl = totalActivePnl
        });
    }

    [HttpGet("transactions")]
    public async Task<IActionResult> GetTransactions([FromQuery] PaginationRequest pagination)
    {
        var query = _context.WalletTransactions
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new
            {
                t.Id,
                t.Amount,
                type = t.Type.ToString(),
                t.Description,
                t.CreatedAt
            });

        var totalCount = await query.CountAsync();

        var items = await query
            .Skip((pagination.Page - 1) * pagination.PageSize)
            .Take(pagination.PageSize)
            .ToListAsync();

        return Ok(new PagedResult<object>
        {
            Items = items.Cast<object>().ToList(),
            Page = pagination.Page,
            PageSize = pagination.PageSize,
            TotalCount = totalCount
        });
    }
}
