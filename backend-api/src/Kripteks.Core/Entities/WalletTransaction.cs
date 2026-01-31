using System;

namespace Kripteks.Core.Entities;

public class WalletTransaction
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public int WalletId { get; set; }
    
    public decimal Amount { get; set; } // Hareket tutarı (+ veya -)
    public TransactionType Type { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    // public Wallet Wallet { get; set; } // Döngüsel referans olmaması için kapalı tutuyorum şimdilik
}

public enum TransactionType
{
    Deposit,        // Para Yatırma
    Withdraw,       // Para Çekme
    BotInvestment,  // Bot Yatırımı (Gider)
    BotReturn,      // Bot Getirisi (Gelir)
    Fee             // İşlem Ücreti (Gelecekte)
}
