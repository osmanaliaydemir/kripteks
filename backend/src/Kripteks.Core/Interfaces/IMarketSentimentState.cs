using Kripteks.Core.Entities;

namespace Kripteks.Core.Interfaces;

public interface IMarketSentimentState
{
    AiAnalysisResult CurrentSentiment { get; }
    void UpdateSentiment(AiAnalysisResult sentiment);
}

public class MarketSentimentState : IMarketSentimentState
{
    public AiAnalysisResult CurrentSentiment { get; private set; } = new AiAnalysisResult 
    { 
        SentimentScore = 0, 
        Summary = "Piyasa analizi bekleniyor...", 
        RecommendedAction = "HOLD" 
    };

    public void UpdateSentiment(AiAnalysisResult sentiment)
    {
        CurrentSentiment = sentiment;
    }
}
