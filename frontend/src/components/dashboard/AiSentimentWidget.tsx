"use client";

import { useEffect, useState } from "react";
import { AnalyticsService } from "@/lib/api";
import { Brain, RefreshCw, ChevronRight } from "lucide-react";
import AiDetailModal from "./AiDetailModal";

interface ProviderDetail {
    providerName: string;
    score: number;
    action: string;
    summary: string;
    reasoning: string;
}

interface SentimentData {
    sentimentScore: number;
    summary: string;
    recommendedAction: string;
    analyzedAt: string;
    providerDetails?: ProviderDetail[];
}

export default function AiSentimentWidget() {
    const [data, setData] = useState<SentimentData | null>(null);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);

    const fetchData = async () => {
        setLoading(true);
        try {
            const res = await AnalyticsService.getSentiment("BTC");
            setData(res);
        } catch (error) {
            console.error("AI Sentiment Error:", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
        const interval = setInterval(fetchData, 60000);
        return () => clearInterval(interval);
    }, []);

    const getScoreColor = (score: number) => {
        if (score > 0.3) return "text-emerald-400";
        if (score < -0.3) return "text-rose-400";
        return "text-amber-400";
    };

    const getActionColor = (action: string) => {
        if (action === "AL" || action === "BUY") return "bg-emerald-500/10 text-emerald-500 border-emerald-500/20";
        if (action === "PANİK SAT" || action === "PANIC SELL") return "bg-rose-500/10 text-rose-500 border-rose-500/20";
        if (action === "SAT" || action === "SELL") return "bg-orange-500/10 text-orange-500 border-orange-500/20";
        return "bg-amber-500/10 text-amber-500 border-amber-500/20";
    };

    const displayData = data || {
        sentimentScore: 0,
        summary: "Piyasa verileri analiz ediliyor veya API anahtarı bekleniyor...",
        recommendedAction: "BEKLEMEDE",
        analyzedAt: new Date().toISOString()
    };


    return (
        <>
            <div className="bg-slate-950/50 border border-white/5 rounded-2xl p-6 relative overflow-hidden group">
                {/* Background Glow */}
                <div className={`absolute top-0 right-0 w-64 h-64 bg-gradient-to-br ${displayData.sentimentScore > 0 ? 'from-emerald-500/5' : 'from-rose-500/5'} to-transparent rounded-full blur-3xl -translate-y-1/2 translate-x-1/2 pointer-events-none`} />

                <div className="flex justify-between items-start mb-4">
                    <div className="flex items-center gap-2">
                        <div className="p-2 bg-indigo-500/10 rounded-lg border border-indigo-500/20">
                            <Brain size={20} className="text-indigo-400" />
                        </div>
                        <div>
                            <h3 className="text-base font-bold text-white leading-none">AI Piyasa Analizi</h3>
                            <div className="flex items-center gap-1.5 mt-1">
                                <span className="flex h-1.5 w-1.5 rounded-full bg-indigo-500 animate-pulse" />
                                <p className="text-[10px] text-indigo-400 font-bold uppercase tracking-wider">Multi-AI Konsensüs</p>
                            </div>
                        </div>
                    </div>

                    <div className={`px-3 py-1 rounded-full border text-xs font-bold ${getActionColor(displayData.recommendedAction)}`}>
                        {displayData.recommendedAction}
                    </div>
                </div>

                <div className="space-y-4">
                    {/* Score Meter */}
                    <div>
                        <div className="flex justify-between text-xs font-mono text-slate-500 mb-1">
                            <span>BEARISH (-1)</span>
                            <span>BULLISH (+1)</span>
                        </div>
                        <div className="h-2 bg-slate-800 rounded-full overflow-hidden relative">
                            <div
                                className={`absolute top-0 bottom-0 w-2 h-full rounded-full transition-all duration-1000 ${getScoreColor(displayData.sentimentScore).replace('text-', 'bg-')}`}
                                style={{ left: `${((displayData.sentimentScore + 1) / 2) * 100}%`, transform: 'translateX(-50%)' }}
                            />
                            <div className="absolute top-0 bottom-0 left-1/2 w-px bg-white/20" />
                        </div>
                        <div className={`text-center mt-2 font-mono text-xl font-bold ${getScoreColor(displayData.sentimentScore)}`}>
                            {displayData.sentimentScore.toFixed(2)}
                        </div>
                    </div>

                    {/* Summary Text */}
                    <div className="bg-slate-900/40 backdrop-blur-md border border-white/5 rounded-2xl p-4 space-y-3 shadow-inner">
                        <div className="flex items-center justify-between pb-2 border-b border-white/5">
                            <div className="flex items-center gap-1.5">
                                <Brain size={12} className="text-indigo-400" />
                                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">AI İçgörü</span>
                            </div>
                            <span className="text-[9px] text-indigo-400/80 font-bold bg-indigo-500/5 px-2 py-0.5 rounded-full border border-indigo-500/10">
                                {displayData.providerDetails?.length || 0} Model
                            </span>
                        </div>
                        <p className="text-[13px] text-slate-200 leading-relaxed font-medium transition-all group-hover:text-white">
                            {displayData.summary}
                        </p>
                    </div>

                    <div className="flex justify-between items-center text-[10px] text-slate-600 font-mono pt-1">
                        <div className="flex items-center gap-1">
                            <span className="w-1 h-1 rounded-full bg-slate-700" />
                            <span suppressHydrationWarning>Son Güncelleme: {new Date(displayData.analyzedAt).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })}</span>
                        </div>
                        <div className="flex items-center gap-2">
                            <button
                                onClick={() => setIsModalOpen(true)}
                                className="flex items-center gap-1 px-2 py-1 rounded-lg bg-indigo-500/10 hover:bg-indigo-500/20 text-indigo-400 transition-all border border-indigo-500/20"
                            >
                                <span className="text-[10px] font-bold">Detay</span>
                                <ChevronRight size={10} />
                            </button>
                            <button
                                onClick={fetchData}
                                disabled={loading}
                                className={`hover:text-white transition-all p-1.5 rounded-lg hover:bg-white/5 ${loading ? 'opacity-50 cursor-not-allowed' : ''}`}
                            >
                                <RefreshCw size={12} className={loading ? "animate-spin" : ""} />
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            {/* AI Detail Modal */}
            <AiDetailModal
                isOpen={isModalOpen}
                onClose={() => setIsModalOpen(false)}
                providerDetails={displayData.providerDetails || []}
                consensusScore={displayData.sentimentScore}
                analyzedAt={displayData.analyzedAt}
            />

        </>
    );
}
