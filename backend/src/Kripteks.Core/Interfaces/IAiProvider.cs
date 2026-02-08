using Kripteks.Core.Entities;

namespace Kripteks.Core.Interfaces;

public interface IAiProvider
{
    string ProviderName { get; }
    Task<AiAnalysisResult> AnalyzeTextAsync(string text);
    Task<string> TranslateTextAsync(string text, string targetLanguage);
}
