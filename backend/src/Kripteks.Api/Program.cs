using Kripteks.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Services;
using Scalar.AspNetCore;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Binance.Net.Interfaces.Clients;
using Binance.Net.Clients;
using Binance.Net.Objects.Options;
using CryptoExchange.Net.Objects.Options;
using System.Net;
using System.Threading.RateLimiting;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;

var builder = WebApplication.CreateBuilder(args);

// Initialize Firebase Admin SDK
if (FirebaseApp.DefaultInstance == null)
{
    try
    {
        GoogleCredential? firebaseCredential = null;

        // 1. Önce JSON string'den dene (environment variable: Firebase__ServiceAccountJson)
        var firebaseJson = builder.Configuration["Firebase:ServiceAccountJson"];
        if (!string.IsNullOrEmpty(firebaseJson))
        {
            firebaseCredential = GoogleCredential.FromJson(firebaseJson);
            Console.WriteLine("[Firebase] Credential loaded from JSON string configuration.");
        }
        else
        {
            // 2. Dosyadan yükle - birden fazla olası dizini tara
            var firebaseConfigPath = builder.Configuration["Firebase:ServiceAccountPath"];
            if (!string.IsNullOrEmpty(firebaseConfigPath))
            {
                var searchPaths = new[]
                {
                    Path.Combine(AppContext.BaseDirectory, firebaseConfigPath),
                    Path.Combine(builder.Environment.ContentRootPath, firebaseConfigPath),
                    Path.Combine(builder.Environment.WebRootPath ?? "", firebaseConfigPath),
                    Path.Combine(builder.Environment.ContentRootPath, "wwwroot", firebaseConfigPath),
                    firebaseConfigPath
                };

                var filePath = searchPaths.FirstOrDefault(File.Exists);

                if (filePath != null)
                {
                    firebaseCredential = GoogleCredential.FromFile(filePath);
                    Console.WriteLine($"[Firebase] Credential loaded from file: {filePath}");
                }
                else
                {
                    Console.WriteLine($"[Firebase] WARNING: Service account file not found! Searched paths:");
                    foreach (var p in searchPaths)
                        Console.WriteLine($"  - {p} (exists: {File.Exists(p)})");
                }
            }
            else
            {
                Console.WriteLine(
                    "[Firebase] WARNING: No Firebase configuration found (ServiceAccountJson or ServiceAccountPath).");
            }
        }

        if (firebaseCredential != null)
        {
            // ProjectId'yi credential'dan al (service account JSON'daki project_id)
            string? firebaseProjectId = null;
            if (firebaseCredential.UnderlyingCredential is ServiceAccountCredential saCredential)
            {
                firebaseProjectId = saCredential.ProjectId;
                Console.WriteLine($"[Firebase] Service Account: {saCredential.Id}, Project: {firebaseProjectId}");
            }

            // SCOPE EKLEMEDEN Firebase'i başlat!
            // Firebase Admin SDK kendi scope'larını ekler (cloud-platform + firebase)
            // Manuel CreateScoped() SDK'nın scope yönetimini bozar
            FirebaseApp.Create(new AppOptions
            {
                Credential = firebaseCredential,
                ProjectId = firebaseProjectId
            });

            Console.WriteLine($"[Firebase] Initialization SUCCESS. ProjectId = {firebaseProjectId}");
        }
        else
        {
            Console.WriteLine("[Firebase] ERROR: Firebase NOT initialized - no credentials available.");
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[Firebase] FATAL: Firebase initialization failed: {ex.Message}");
        Console.WriteLine($"[Firebase] Stack: {ex.StackTrace}");
    }
}

// Mac/Development için Global SSL Bypass (.NET 9 uyumlu)
builder.Services.AddHttpClient("Binance").ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler
{
    ServerCertificateCustomValidationCallback = (message, cert, chain, errors) => true
});

// Varsayılan HttpClient konfigürasyonu
builder.Services.AddHttpClient(string.Empty).ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler
{
    ServerCertificateCustomValidationCallback = (message, cert, chain, errors) => true
});

// Firebase FCM API için HttpClient
builder.Services.AddHttpClient("Firebase");

// Add services to the container.
builder.Services.AddHttpContextAccessor();

// MSSQL Bağlantısı
// MSSQL Bağlantısı
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"),
        b => b.MigrationsAssembly("Kripteks.Infrastructure")));

// Identity & JWT Setup
builder.Services.AddIdentity<Kripteks.Core.Entities.AppUser, IdentityRole>()
    .AddEntityFrameworkStores<AppDbContext>()
    .AddDefaultTokenProviders();

var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var secretKey = System.Text.Encoding.UTF8.GetBytes(jwtSettings["Secret"] ?? "default_secret_key_must_be_long_2026");

builder.Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme =
            JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme =
            JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings["Issuer"],
            ValidAudience = jwtSettings["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(secretKey)
        };

        // SignalR için Token Okuma Ayarı (WebSocket Header desteklemez, QueryString kullanır)
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];

                // SignalR Hub'larına gelen isteklerde token varsa al
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) &&
                    (path.StartsWithSegments("/bot-hub") ||
                     path.StartsWithSegments("/backtest-hub") ||
                     path.StartsWithSegments("/market-hub")))
                {
                    context.Token = accessToken;
                }

                return Task.CompletedTask;
            }
        };
    });
// Şifreleme Servisi
builder.Services.AddSingleton<IEncryptionService, AesEncryptionService>();

// Servislerin Kaydı (Dependency Injection)
builder.Services.AddScoped<IBotService, BotService>();
builder.Services.AddSingleton<IMarketDataService, BinanceMarketService>();
builder.Services.AddScoped<BacktestService>();
builder.Services.AddScoped<ScannerService>();
builder.Services.AddScoped<IBacktestRepository, Kripteks.Infrastructure.Repositories.BacktestRepository>();
// Binance Client Ayarları (SSL bypass dahil)
builder.Services.AddSingleton<IBinanceRestClient>(sp => new BinanceRestClient());
builder.Services.AddSingleton<IBinanceSocketClient>(sp => new BinanceSocketClient());

builder.Services.AddTransient<IMailService, GmailMailService>(); // Eski referans ama Engine kullaniyor
builder.Services.AddScoped<INotificationService, Kripteks.Api.Services.NotificationService>();
builder.Services.AddScoped<IAnalyticsService, AnalyticsService>();
builder.Services.AddScoped<IMarketAnalysisService, MarketAnalysisService>();
builder.Services.AddScoped<IWhaleTrackerService, WhaleTrackerService>();
builder.Services.AddScoped<IArbitrageScannerService, ArbitrageScannerService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddSingleton<ILogService, LogService>(); // Singleton olabilir çünkü scope factory kullanıyor
builder.Services.AddSingleton<IAuditLogService, AuditLogService>();
builder.Services.AddScoped<IAlertService, AlertService>();
builder.Services.AddScoped<IPortfolioService, PortfolioService>();

// AI & Haber Servisleri
builder.Services.AddSingleton<IMarketSentimentState, MarketSentimentState>();
builder.Services.AddHttpClient<DeepSeekAiService>();
builder.Services.AddHttpClient<GeminiAiService>();
builder.Services.AddHttpClient<OpenAiService>();
builder.Services.AddHttpClient<CryptoPanicNewsService>();
builder.Services.AddHttpClient<ChatDevService>();

builder.Services.AddScoped<IChatDevService, ChatDevService>(sp => sp.GetRequiredService<ChatDevService>());

builder.Services.AddScoped<IAiProvider, DeepSeekAiService>(sp => sp.GetRequiredService<DeepSeekAiService>());
builder.Services.AddScoped<IAiProvider, GeminiAiService>(sp => sp.GetRequiredService<GeminiAiService>());
builder.Services.AddScoped<IAiProvider, OpenAiService>(sp => sp.GetRequiredService<OpenAiService>());

builder.Services.AddScoped<IAiService, AiOrchestratorService>();
builder.Services.AddScoped<INewsService, CryptoPanicNewsService>(sp => sp.GetRequiredService<CryptoPanicNewsService>());
builder.Services.AddHostedService<SentimentAnalysisJob>();

// Firebase Cloud Messaging
builder.Services.AddScoped<IFirebaseNotificationService, FirebaseNotificationService>();


// Stratejiler - Manuel test için temizlendi
builder.Services.AddScoped<IStrategy, Kripteks.Infrastructure.Strategies.Sma111BuySellStrategy>();
builder.Services.AddScoped<IStrategy, Kripteks.Infrastructure.Strategies.Sma111BreakoutStrategy>();
builder.Services.AddScoped<IStrategyFactory, Kripteks.Infrastructure.Strategies.StrategyFactory>();

// Arka Plan Servisleri (Bot Engine + Market Data Stream)
builder.Services.AddHostedService<BotEngineService>();
builder.Services.AddHostedService<BinanceWebSocketService>();
builder.Services.AddHostedService<AlertProcessingJob>();

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
    });

// .NET 9 Native OpenAPI Support
builder.Services.AddOpenApi();

// Rate Limiting — Brute force ve API abuse koruması
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    // Auth endpoint'leri için sıkı limit: IP başına 30 saniyede 5 istek
    options.AddPolicy("auth", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 5,
                Window = TimeSpan.FromSeconds(30),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 0
            }));

    // Genel API limiti: IP başına 1 dakikada 100 istek
    options.AddPolicy("api", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 100,
                Window = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 0
            }));
});

// CORS - Production ve Development için
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        corsBuilder =>
        {
            corsBuilder
                .WithOrigins(
                    "https://web-kripteks.runasp.net", // Production frontend
                    "http://localhost:3000", // Development frontend
                    "http://localhost:5173", // Vite dev server
                    "https://localhost:3000",
                    "https://localhost:5173"
                )
                .AllowAnyMethod()
                .AllowAnyHeader()
                .AllowCredentials(); // SignalR İçin Önemli
        });
});

builder.Services.AddSignalR(hubOptions => { hubOptions.EnableDetailedErrors = builder.Environment.IsDevelopment(); });

var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseMiddleware<Kripteks.Api.Middleware.GlobalExceptionHandlerMiddleware>();

app.MapOpenApi(); // Generates /openapi/v1.json
app.MapScalarApiReference(); // Serves Scalar UI at /scalar/v1

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseCors("AllowAll");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

// Seed Data
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        await SeedData.Initialize(services);
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "An error occurred while seeding the database.");
    }
}

app.MapControllers();
app.MapHub<Kripteks.Api.Hubs.BotHub>("/bot-hub");
app.MapHub<Kripteks.Api.Hubs.BacktestHub>("/backtest-hub");
app.MapHub<Kripteks.Infrastructure.Hubs.MarketDataHub>("/market-hub");

// Ana sayfaya gelenleri dökümantasyona yönlendir
app.MapGet("/", () => Results.Redirect("/scalar/v1"));

app.Run();
