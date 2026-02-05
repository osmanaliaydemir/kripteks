"use client";

import { useEffect, useState } from "react";
import { TrendingUp, TrendingDown, Activity } from "lucide-react";

interface SentimentPoint {
    score: number;
    action: string;
    recordedAt: string;
}

interface SentimentTrendChartProps {
    className?: string;
}

export default function SentimentTrendChart({ className = "" }: SentimentTrendChartProps) {
    const [data, setData] = useState<SentimentPoint[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchHistory = async () => {
            try {
                const token = localStorage.getItem("token");
                const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:5292"}/api/analytics/sentiment-history?hours=24`, {
                    headers: { Authorization: `Bearer ${token}` }
                });
                if (res.ok) {
                    const history = await res.json();
                    setData(history);
                }
            } catch (error) {
                console.error("Sentiment history fetch error:", error);
            } finally {
                setLoading(false);
            }
        };

        fetchHistory();
        const interval = setInterval(fetchHistory, 60000);
        return () => clearInterval(interval);
    }, []);

    // Simplified chart data logic - only use real data
    const chartData = data;

    const trend = chartData.length >= 2
        ? chartData[chartData.length - 1].score - chartData[0].score
        : 0;

    const avgScore = chartData.length > 0
        ? chartData.reduce((sum, d) => sum + d.score, 0) / chartData.length
        : 0;

    // Calculate min/max for chart scaling
    const scores = chartData.length > 0 ? chartData.map(d => d.score) : [0];
    const minScore = Math.min(...scores, -0.1);
    const maxScore = Math.max(...scores, 0.1);
    const range = Math.max(0.1, maxScore - minScore);

    return (
        <div className={`bg-slate-950/50 border border-white/5 rounded-2xl p-4 ${className}`}>
            <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                    <Activity size={16} className="text-indigo-400" />
                    <h4 className="text-sm font-bold text-white">Sentiment Trendi</h4>
                </div>
                {chartData.length >= 2 && (
                    <div className="flex items-center gap-1.5">
                        {trend > 0 ? (
                            <TrendingUp size={14} className="text-emerald-400" />
                        ) : trend < 0 ? (
                            <TrendingDown size={14} className="text-rose-400" />
                        ) : null}
                        <span className={`text-xs font-mono font-bold ${trend > 0 ? 'text-emerald-400' : trend < 0 ? 'text-rose-400' : 'text-amber-400'}`}>
                            {trend > 0 ? '+' : ''}{trend.toFixed(2)}
                        </span>
                    </div>
                )}
            </div>

            {/* Mini Chart */}
            <div className="relative h-16 mt-2">
                {loading || chartData.length < 2 ? (
                    <div className="flex flex-col items-center justify-center h-full gap-1">
                        <div className="w-full h-px bg-white/5 animate-pulse" />
                        <span className="text-[10px] text-slate-600 font-mono">
                            {loading ? "Veriler yükleniyor..." : "Yetersiz veri noktası"}
                        </span>
                    </div>
                ) : (
                    <svg className="w-full h-full" viewBox={`0 0 100 40`} preserveAspectRatio="none">
                        {/* Zero line */}
                        <line
                            x1="0"
                            y1={20 + (0 - (minScore + maxScore) / 2) * (40 / range)}
                            x2="100"
                            y2={20 + (0 - (minScore + maxScore) / 2) * (40 / range)}
                            stroke="rgba(255,255,255,0.1)"
                            strokeWidth="0.5"
                            strokeDasharray="2,2"
                        />

                        {/* Area under the line */}
                        <path
                            d={`M 0 ${40 - ((chartData[0]?.score || 0) - minScore) * (40 / range)} ${chartData.map((d, i) =>
                                `L ${(i / (chartData.length - 1)) * 100} ${40 - (d.score - minScore) * (40 / range)}`
                            ).join(' ')} L 100 40 L 0 40 Z`}
                            fill="url(#sentimentGradient)"
                            opacity="0.3"
                        />

                        {/* Line */}
                        <path
                            d={`M ${chartData.map((d, i) =>
                                `${(i / (chartData.length - 1)) * 100} ${40 - (d.score - minScore) * (40 / range)}`
                            ).join(' L ')}`}
                            fill="none"
                            stroke={avgScore > 0 ? "#10b981" : avgScore < 0 ? "#f43f5e" : "#f59e0b"}
                            strokeWidth="1.5"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                        />

                        {/* Gradient definition */}
                        <defs>
                            <linearGradient id="sentimentGradient" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="0%" stopColor={avgScore > 0 ? "#10b981" : "#f43f5e"} />
                                <stop offset="100%" stopColor="transparent" />
                            </linearGradient>
                        </defs>
                    </svg>
                )}
            </div>

            {/* Footer Stats */}
            <div className="flex justify-between items-center mt-3 pt-2 border-t border-white/5">
                <div className="text-[10px] text-slate-500">
                    {chartData.length > 0 ? `Son 24 saat • ${chartData.length} veri noktası` : "Veri bekleniyor..."}
                </div>
                {chartData.length > 0 && (
                    <div className={`text-xs font-mono font-bold ${avgScore > 0 ? 'text-emerald-400' : avgScore < 0 ? 'text-rose-400' : 'text-amber-400'}`}>
                        Ort: {avgScore.toFixed(2)}
                    </div>
                )}
            </div>
        </div>
    );
}

