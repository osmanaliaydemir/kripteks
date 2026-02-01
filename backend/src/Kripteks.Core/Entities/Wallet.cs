namespace Kripteks.Core.Entities;

public class Wallet
{
    public int Id { get; set; }
    public decimal Balance { get; set; } = 0; // Toplam bakiye
    public decimal LockedBalance { get; set; } = 0; // İşlemde olan bakiye
    public decimal AvailableBalance => Balance;
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;

    // Navigation
    // public List<WalletTransaction> Transactions { get; set; } = new(); // Henüz gerek yok, doğrudan sorgularız
}
