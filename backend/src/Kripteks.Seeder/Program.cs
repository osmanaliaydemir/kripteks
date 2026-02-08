using Kripteks.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Identity;
using Kripteks.Core.Entities;

// Configuration okuma
var basePath = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../Kripteks.Api"));
var configuration = new ConfigurationBuilder()
    .SetBasePath(basePath)
    .AddJsonFile("appsettings.json")
    .Build();

// Service Provider oluşturma
var services = new ServiceCollection();

// DbContext ekleme
services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));

// Identity ekleme
services.AddIdentity<AppUser, IdentityRole>()
    .AddEntityFrameworkStores<AppDbContext>()
    .AddDefaultTokenProviders();

var serviceProvider = services.BuildServiceProvider();

// Seed Data çalıştırma
Console.WriteLine("🌱 Seeding production database...");
try
{
    await SeedData.Initialize(serviceProvider);
    Console.WriteLine("✅ Seed completed successfully!");
}
catch (Exception ex)
{
    Console.WriteLine($"❌ Seed failed: {ex.Message}");
    Console.WriteLine($"Inner: {ex.InnerException?.Message}");
}
