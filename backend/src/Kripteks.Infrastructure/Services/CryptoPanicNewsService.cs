using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;

namespace Kripteks.Infrastructure.Services;

public class CryptoPanicNewsService : INewsService
{
    public async Task<List<NewsItem>> GetLatestNewsAsync(string symbol = "BTC")
    {
        // MOCK DATA FOR NOW
        // Gerçek entegrasyonda: https://cryptopanic.com/api/v1/posts/?auth_token=...&currencies=BTC
        
        await Task.Delay(100); 

        var news = new List<NewsItem>
        {
            new NewsItem
            {
                Title = "Bitcoin ETF Flows Turn Positive Again",
                Summary = "Institutional interest remains strong as ETFs see regular inflows.",
                Source = "CryptoPanic",
                PublishedAt = DateTime.UtcNow.AddMinutes(-15),
                SentimentScore = 0.8f,
                AiSummary = "Highly Bullish. Institutional demand is a key driver."
            },
            new NewsItem
            {
                Title = "SEC Delays Decision on Ethereum Options",
                Summary = "The regulatory body has pushed back the deadline for options trading on ETH ETFs.",
                Source = "Twitter",
                PublishedAt = DateTime.UtcNow.AddHours(-2),
                SentimentScore = -0.3f,
                AiSummary = "Slightly Bearish due to uncertainty, but expected."
            },
             new NewsItem
            {
                Title = $"{symbol} Breaks Key Resistance Level",
                Summary = "Technical analysis shows a breakout pattern forming on the 4H chart.",
                Source = "TradingView",
                PublishedAt = DateTime.UtcNow.AddMinutes(-5),
                SentimentScore = 0.6f,
                AiSummary = "Bullish momentum confirmed."
            }
        };

        return news;
    }
}
