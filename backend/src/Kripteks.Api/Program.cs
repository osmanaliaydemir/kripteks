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

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

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

                // Bot Hub'ına gelen isteklerde token varsa al
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) &&
                    (path.StartsWithSegments("/bot-hub")))
                {
                    context.Token = accessToken;
                }

                return Task.CompletedTask;
            }
        };
    });
// Servislerin Kaydı (Dependency Injection)
builder.Services.AddScoped<IBotService, BotService>();
builder.Services.AddSingleton<IMarketDataService, BinanceMarketService>();
builder.Services.AddScoped<BacktestService>();
builder.Services.AddSingleton<IBinanceRestClient, BinanceRestClient>();

builder.Services.AddTransient<IMailService, GmailMailService>(); // Eski referans ama Engine kullaniyor
builder.Services.AddScoped<INotificationService, Kripteks.Api.Services.NotificationService>();
builder.Services.AddScoped<IAnalyticsService, AnalyticsService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddSingleton<ILogService, LogService>(); // Singleton olabilir çünkü scope factory kullanıyor

// Arka Plan Servisleri (Bot Engine)
builder.Services.AddHostedService<BotEngineService>();

builder.Services.AddControllers();

// .NET 9 Native OpenAPI Support
builder.Services.AddOpenApi();

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        corsBuilder =>
        {
            corsBuilder.SetIsOriginAllowed(_ => true) // SignalR İçin Önemli
                .AllowAnyMethod()
                .AllowAnyHeader()
                .AllowCredentials(); // SignalR İçin Önemli
        });
});

builder.Services.AddSignalR(hubOptions => { hubOptions.EnableDetailedErrors = true; });

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi(); // Generates /openapi/v1.json

    // Basic Auth Removed for Local Development Ease
    app.MapScalarApiReference(); // Serves Scalar UI at /scalar/v1
}


// app.UseHttpsRedirection(); // Localhost'ta sorun çıkarabilir
app.UseCors("AllowAll"); // Keeping original CORS policy name as "AllowNextJs" was not defined.
app.UseAuthentication(); // KİMLİK DOĞRULAMA (Login oldun mu?)
app.UseAuthorization(); // YETKİLENDİRME (Yetkin var mı?)

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

// Ana sayfaya gelenleri dökümantasyona yönlendir
app.MapGet("/", () => Results.Redirect("/scalar/v1"));

app.Run();
