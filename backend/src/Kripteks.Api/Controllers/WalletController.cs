using Kripteks.Core.Entities;
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

        return Ok(new 
        {
            current_balance = wallet.Balance + wallet.LockedBalance + totalActivePnl, // Toplam Varlık (Cüzdan + Bloke + Kar/Zarar)
            available_balance = wallet.AvailableBalance,
            locked_balance = wallet.LockedBalance,
            total_pnl = totalActivePnl
        });
    }

    [HttpGet("transactions")]
    public async Task<IActionResult> GetTransactions()
    {
        var transactions = await _context.WalletTransactions
            .OrderByDescending(t => t.CreatedAt)
            .Take(50) // Son 50 işlem
            .Select(t => new 
            {
                t.Id,
                t.Amount,
                type = t.Type.ToString(),
                t.Description,
                t.CreatedAt
            })
            .ToListAsync();

        return Ok(transactions);
    }
}
