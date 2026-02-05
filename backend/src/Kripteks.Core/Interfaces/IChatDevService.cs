using Kripteks.Core.Entities;

namespace Kripteks.Core.Interfaces;

public interface IChatDevService
{
    /// <summary>
    /// Belirli bir iş akışını (workflow) ChatDev üzerinden çalıştırır.
    /// </summary>
    /// <param name="workflowYaml">Çalıştırılacak YAML dosyasının adı.</param>
    /// <param name="taskPrompt">Ajanlara verilecek görev açıklaması.</param>
    /// <param name="variables">Opsiyonel değişkenler.</param>
    Task<AiAnalysisResult> RunWorkflowAsync(string workflowYaml, string taskPrompt, Dictionary<string, string>? variables = null);

    /// <summary>
    /// Piyasa duygu analizi için özelleşmiş bir ChatDev iş akışı çalıştırır.
    /// </summary>
    Task<AiAnalysisResult> AnalyzeMarketSentimentAsync(string newsSummary);
}
