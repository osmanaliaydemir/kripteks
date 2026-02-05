"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { BacktestService } from "@/lib/api";
import { toast } from "sonner";
import {
    Activity, TrendingUp, TrendingDown, Percent, AlertTriangle,
    BarChart3, Sparkles, Loader2, Dice6, Target, Shield, HelpCircle, Info
} from "lucide-react";
import {
    ResponsiveContainer, LineChart, Line, AreaChart, Area,
    BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid, Cell
} from "recharts";

function InfoTooltip({ text }: { text: string }) {
    const [isVisible, setIsVisible] = useState(false);
    return (
        <div className="relative inline-block ml-1.5 align-middle" onMouseEnter={() => setIsVisible(true)} onMouseLeave={() => setIsVisible(false)}>
            <div className="p-0.5 rounded-full hover:bg-white/10 transition-all cursor-help text-slate-500 hover:text-slate-300 active:scale-95">
                <Info size={12} strokeWidth={2.5} />
            </div>
            <AnimatePresence>
                {isVisible && (
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95, y: 10 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.95, y: 10 }}
                        className="absolute bottom-full left-1/2 -translate-x-1/2 mb-3 w-64 p-3.5 bg-slate-900 border border-white/20 rounded-xl shadow-[0_20px_50px_rgba(0,0,0,0.5)] z-9999 pointer-events-none ring-1 ring-white/5"
                    >
                        <p className="text-[11px] leading-relaxed text-slate-100 font-medium text-center drop-shadow-sm">{text}</p>
                        <div className="absolute top-full left-1/2 -translate-x-1/2 border-[7px] border-transparent border-t-slate-900"></div>
                        <div className="absolute top-[calc(100%+1px)] left-1/2 -translate-x-1/2 border-[7px] border-transparent border-t-white/10"></div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
}

interface MonteCarloResult {
    success: boolean;
    errorMessage?: string;
    simulationCount: number;
    tradesPerSimulation: number;
    initialBalance: number;
    medianReturn: number;
    percentile5Return: number;
    percentile25Return: number;
    percentile75Return: number;
    percentile95Return: number;
    averageReturn: number;
    worstCase: number;
    bestCase: number;
    probabilityOfProfit: number;
    probabilityOfRuin: number;
    averageMaxDrawdown: number;
    percentile95MaxDrawdown: number;
    sampleEquityCurves: number[][];
    returnDistribution: { rangeLow: number; rangeHigh: number; count: number; percentage: number }[];
}

interface MonteCarloVisualizationProps {
    backtestResult: any;
}

const COLORS = [
    '#22c55e', '#10b981', '#14b8a6', '#06b6d4', '#0ea5e9',
    '#3b82f6', '#6366f1', '#8b5cf6', '#a855f7', '#d946ef',
    '#ec4899', '#f43f5e', '#f97316', '#eab308', '#84cc16',
    '#22d3ee', '#34d399', '#a78bfa', '#fb923c', '#fbbf24'
];

export default function MonteCarloVisualization({ backtestResult }: MonteCarloVisualizationProps) {
    const [result, setResult] = useState<MonteCarloResult | null>(null);
    const [loading, setLoading] = useState(false);
    const [simCount, setSimCount] = useState(1000);
    const [showHelp, setShowHelp] = useState(false);

    const runSimulation = async () => {
        setLoading(true);
        try {
            const data = await BacktestService.runMonteCarlo(backtestResult, {
                simulationCount: simCount,
                tradesPerSimulation: Math.max(backtestResult.totalTrades, 100),
                initialBalance: backtestResult.initialBalance || 10000,
                ruinThreshold: 0.5
            });
            setResult(data);
            toast.success("Monte Carlo Tamamlandı 🎲", {
                description: `${simCount.toLocaleString()} simülasyon başarıyla çalıştırıldı.`
            });
        } catch (error: any) {
            toast.error("Hata", { description: error.message || "Simülasyon başarısız." });
        } finally {
            setLoading(false);
        }
    };

    // Transform equity curves for chart
    const equityChartData = result?.sampleEquityCurves?.[0]?.map((_, index) => {
        const point: any = { trade: index };
        result.sampleEquityCurves.forEach((curve, i) => {
            point[`curve${i}`] = curve[index];
        });
        return point;
    }) || [];

    // Transform distribution for bar chart
    const distributionData = result?.returnDistribution?.map(bucket => ({
        range: `$${(bucket.rangeLow / 1000).toFixed(1)}k`,
        count: bucket.count,
        percentage: bucket.percentage,
        isProfit: bucket.rangeLow >= (result.initialBalance || 10000)
    })) || [];

    return (
        <div className="space-y-6">
            {/* Control Panel */}
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="bg-linear-to-br from-violet-500/10 via-purple-500/5 to-fuchsia-500/10 border border-violet-500/20 rounded-2xl p-6 relative overflow-hidden"
            >
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6 relative z-10">
                    <div className="flex items-center gap-3">
                        <div className="p-2.5 bg-violet-500/20 rounded-xl">
                            <Dice6 className="w-5 h-5 text-violet-400" />
                        </div>
                        <div>
                            <h3 className="text-lg font-bold text-white">Monte Carlo Simülasyonu</h3>
                            <p className="text-xs text-slate-400">Binlerce rastgele senaryo ile risk analizi</p>
                        </div>
                    </div>

                    <button
                        onClick={() => setShowHelp(!showHelp)}
                        className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all border ${showHelp ? 'bg-violet-500/20 border-violet-500/40 text-violet-300' : 'bg-slate-900/50 border-white/5 text-slate-400 hover:text-slate-200'}`}
                    >
                        <HelpCircle size={14} />
                        Bu Nedir? Nasıl Çalışır?
                    </button>
                </div>

                <AnimatePresence>
                    {showHelp && (
                        <motion.div
                            initial={{ height: 0, opacity: 0 }}
                            animate={{ height: "auto", opacity: 1 }}
                            exit={{ height: 0, opacity: 0 }}
                            className="overflow-hidden mb-6"
                        >
                            <div className="p-5 bg-slate-950/40 border border-violet-500/10 rounded-2xl grid grid-cols-1 md:grid-cols-3 gap-6">
                                <div className="space-y-2">
                                    <div className="flex items-center gap-2 text-violet-400 mb-1">
                                        <Target size={14} />
                                        <span className="text-[10px] uppercase font-bold tracking-wider">Nedir?</span>
                                    </div>
                                    <p className="text-xs text-slate-300 leading-relaxed font-medium">
                                        Geçmiş işlemlerinizin (Backtest) yerleri rastgele değiştirilseydi sonuç ne olurdu? Monte Carlo, "şans" faktörünü simülasyona katarak stratejinizin sağlamlığını ölçer.
                                    </p>
                                </div>
                                <div className="space-y-2">
                                    <div className="flex items-center gap-2 text-violet-400 mb-1">
                                        <Activity size={14} />
                                        <span className="text-[10px] uppercase font-bold tracking-wider">Nasıl Çalışır?</span>
                                    </div>
                                    <p className="text-xs text-slate-300 leading-relaxed font-medium">
                                        Sizin gerçek işlemlerinizi bir torbaya koyup karıştırırız. Binlerce kez bu torbadan rastgele işlemler çekerek hayali "alternatif gelecekler" oluştururuz.
                                    </p>
                                </div>
                                <div className="space-y-2">
                                    <div className="flex items-center gap-2 text-violet-400 mb-1">
                                        <Shield size={14} />
                                        <span className="text-[10px] uppercase font-bold tracking-wider">Neden Kritik?</span>
                                    </div>
                                    <p className="text-xs text-slate-300 leading-relaxed font-medium">
                                        Stratejiniz sadece doğru zamanda doğru yerde olduğunuz için mi (şans) yoksa her koşulda mı (disiplin) kazanıyor? İflas riskinizi (Ruin Risk) bu panelde görürsünüz.
                                    </p>
                                </div>
                            </div>
                        </motion.div>
                    )}
                </AnimatePresence>

                <div className="flex flex-wrap items-end gap-4">
                    <div className="flex-1 min-w-[200px]">
                        <label className="text-xs text-slate-400 mb-2 block">Simülasyon Sayısı</label>
                        <input
                            type="range"
                            min={100}
                            max={5000}
                            step={100}
                            value={simCount}
                            onChange={(e) => setSimCount(Number(e.target.value))}
                            className="w-full h-2 bg-slate-700 rounded-full appearance-none cursor-pointer accent-violet-500"
                        />
                        <div className="flex justify-between text-[10px] text-slate-500 mt-1">
                            <span>100</span>
                            <span className="text-violet-400 font-bold">{simCount.toLocaleString()}</span>
                            <span>5000</span>
                        </div>
                    </div>

                    <button
                        onClick={runSimulation}
                        disabled={loading || !backtestResult?.trades?.length}
                        className="px-6 py-3 bg-linear-to-r from-violet-600 to-purple-600 hover:from-violet-500 hover:to-purple-500 disabled:opacity-50 disabled:cursor-not-allowed rounded-xl font-bold text-white text-sm transition-all shadow-lg shadow-violet-500/25 flex items-center gap-2"
                    >
                        {loading ? (
                            <>
                                <Loader2 className="w-4 h-4 animate-spin" />
                                Simülasyon...
                            </>
                        ) : (
                            <>
                                <Sparkles className="w-4 h-4" />
                                Simüle Et
                            </>
                        )}
                    </button>
                </div>
            </motion.div>

            {/* Results */}
            <AnimatePresence mode="wait">
                {result && result.success && (
                    <motion.div
                        initial={{ opacity: 0, y: 30 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: -30 }}
                        className="space-y-6"
                    >
                        {/* Key Metrics */}
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                            <MetricCard
                                icon={<Percent className="w-4 h-4" />}
                                label="Kâr Olasılığı"
                                value={`${result.probabilityOfProfit.toFixed(1)}%`}
                                color={result.probabilityOfProfit >= 50 ? "green" : "red"}
                                subtext={`${result.simulationCount.toLocaleString()} farklı gelecek senaryosu`}
                                tooltip="Belirlenen işlem sayısı sonunda kârat olma olasılığınızı gösterir."
                            />
                            <MetricCard
                                icon={<AlertTriangle className="w-4 h-4" />}
                                label="İflas Riski"
                                value={`${result.probabilityOfRuin.toFixed(1)}%`}
                                color={result.probabilityOfRuin <= 10 ? "green" : result.probabilityOfRuin <= 25 ? "yellow" : "red"}
                                subtext="50% drawdown kriteri"
                                tooltip="Bakiyenin simülasyon sırasında %50 veya daha fazla düşme (Ruin) olasılığıdır."
                            />
                            <MetricCard
                                icon={<Target className="w-4 h-4" />}
                                label="Medyan Getiri"
                                value={`$${result.medianReturn.toLocaleString()}`}
                                color={result.medianReturn >= result.initialBalance ? "green" : "red"}
                                subtext={`${result.tradesPerSimulation} İşlem Sonrası Tahmin`}
                                tooltip={`Mevcut performansınızla ${result.tradesPerSimulation} ardışık işlem yaparsanız, şans faktöründen bağımsız olarak ulaşmanız beklenen en muhtemel bakiye hedefidir.`}
                            />
                            <MetricCard
                                icon={<Shield className="w-4 h-4" />}
                                label="Maks. DD (95%)"
                                value={`${result.percentile95MaxDrawdown.toFixed(1)}%`}
                                color={result.percentile95MaxDrawdown <= 20 ? "green" : result.percentile95MaxDrawdown <= 35 ? "yellow" : "red"}
                                subtext="Kötü Senaryo Riski"
                                tooltip="En şanssız %5'lik dilimdeki simülasyonların gördüğü en büyük düşüş. Karşılaşabileceğiniz 'makul en kötü' riski simüle eder."
                            />
                        </div>

                        {/* Confidence Intervals */}
                        <div className="bg-slate-800/30 border border-white/5 rounded-2xl p-5">
                            <h4 className="text-sm font-bold text-white mb-4 flex items-center gap-2">
                                <BarChart3 className="w-4 h-4 text-cyan-400" />
                                Güven Aralıkları (Getiri Dağılımı)
                            </h4>
                            <div className="space-y-3">
                                <ConfidenceBar
                                    label="En Kötü"
                                    value={result.worstCase}
                                    initial={result.initialBalance}
                                    max={result.bestCase}
                                    color="red"
                                    tooltip="Tüm senaryolar arasındaki en kötü sonuç. 'Kıyamet senaryosu' olarak da adlandırılabilir."
                                />
                                <ConfidenceBar
                                    label="5. Yüzdelik"
                                    value={result.percentile5Return}
                                    initial={result.initialBalance}
                                    max={result.bestCase}
                                    color="orange"
                                    tooltip="Simülasyonların %5'i (en şanssız 50 senaryo) bu değerin altındadır. İşlerin ciddi şekilde ters gittiği bir geleceği temsil eder."
                                />
                                <ConfidenceBar
                                    label="25. Yüzdelik"
                                    value={result.percentile25Return}
                                    initial={result.initialBalance}
                                    max={result.bestCase}
                                    color="yellow"
                                    tooltip="Simülasyonların %25'i bu değerin altındadır. Piyasaların zorlayıcı olduğu 'kötü' bir dönemin muhafazakar sonucudur."
                                />
                                <ConfidenceBar
                                    label="Medyan (50)"
                                    value={result.medianReturn}
                                    initial={result.initialBalance}
                                    max={result.bestCase}
                                    color="cyan"
                                    highlight
                                    tooltip="Tüm sonuçların tam ortası. Stratejinizin şans faktöründen arındırılmış, en muhtemel 'yolun ortası' performansı."
                                />
                                <ConfidenceBar
                                    label="75. Yüzdelik"
                                    value={result.percentile75Return}
                                    initial={result.initialBalance}
                                    max={result.bestCase}
                                    color="green"
                                    tooltip="Senaryoların %75'i bu değerin altındadır. İşlerin ortalamadan daha akıcı ve iyi gittiği 'şanslı' bir dönem."
                                />
                                <ConfidenceBar
                                    label="95. Yüzdelik"
                                    value={result.percentile95Return}
                                    initial={result.initialBalance}
                                    max={result.bestCase}
                                    color="emerald"
                                    tooltip="En iyi %5'lik dilime giriş sınırı. Stratejinin ve piyasa koşullarının mükemmel uyum sağladığı 'altın' senaryo."
                                />
                                <ConfidenceBar
                                    label="En İyi"
                                    value={result.bestCase}
                                    initial={result.initialBalance}
                                    max={result.bestCase}
                                    color="teal"
                                    tooltip="Tüm senaryolar arasındaki en yüksek bakiye sonucudur."
                                />
                            </div>
                        </div>

                        {/* Equity Curves Chart */}
                        <div className="bg-slate-800/30 border border-white/5 rounded-2xl p-5">
                            <h4 className="text-sm font-bold text-white mb-4 flex items-center gap-2">
                                <Activity className="w-4 h-4 text-violet-400" />
                                Örnek Equity Eğrileri (20 Senaryo)
                            </h4>
                            <div className="h-64">
                                <ResponsiveContainer width="100%" height="100%">
                                    <LineChart data={equityChartData}>
                                        <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                                        <XAxis
                                            dataKey="trade"
                                            stroke="#64748b"
                                            fontSize={10}
                                            tickFormatter={(v) => `#${v}`}
                                        />
                                        <YAxis
                                            stroke="#64748b"
                                            fontSize={10}
                                            tickFormatter={(v) => `$${(v / 1000).toFixed(0)}k`}
                                        />
                                        <Tooltip
                                            contentStyle={{
                                                backgroundColor: '#1e293b',
                                                border: '1px solid #334155',
                                                borderRadius: '12px'
                                            }}
                                            formatter={(v: any) => [`$${Number(v || 0).toLocaleString()}`, '']}
                                        />
                                        {result.sampleEquityCurves.map((_, i) => (
                                            <Line
                                                key={i}
                                                type="monotone"
                                                dataKey={`curve${i}`}
                                                stroke={COLORS[i % COLORS.length]}
                                                strokeWidth={1.5}
                                                dot={false}
                                                opacity={0.7}
                                            />
                                        ))}
                                    </LineChart>
                                </ResponsiveContainer>
                            </div>
                        </div>

                        {/* Distribution Histogram */}
                        <div className="bg-slate-800/30 border border-white/5 rounded-2xl p-5">
                            <h4 className="text-sm font-bold text-white mb-4 flex items-center gap-2">
                                <BarChart3 className="w-4 h-4 text-fuchsia-400" />
                                Getiri Dağılımı Histogramı
                            </h4>
                            <div className="h-48">
                                <ResponsiveContainer width="100%" height="100%">
                                    <BarChart data={distributionData}>
                                        <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                                        <XAxis dataKey="range" stroke="#64748b" fontSize={10} />
                                        <YAxis stroke="#64748b" fontSize={10} />
                                        <Tooltip
                                            contentStyle={{
                                                backgroundColor: '#1e293b',
                                                border: '1px solid #334155',
                                                borderRadius: '12px'
                                            }}
                                            formatter={(v: any, name?: string) => [
                                                name === 'count' ? `${v || 0} simülasyon` : `${Number(v || 0).toFixed(1)}%`,
                                                name === 'count' ? 'Sayı' : 'Oran'
                                            ]}
                                        />
                                        <Bar dataKey="count" radius={[4, 4, 0, 0]}>
                                            {distributionData.map((entry, index) => (
                                                <Cell
                                                    key={index}
                                                    fill={entry.isProfit ? '#22c55e' : '#ef4444'}
                                                    opacity={0.8}
                                                />
                                            ))}
                                        </Bar>
                                    </BarChart>
                                </ResponsiveContainer>
                            </div>
                            <div className="flex justify-center gap-6 mt-3 text-xs">
                                <span className="flex items-center gap-1.5">
                                    <span className="w-3 h-3 rounded bg-red-500"></span>
                                    Zarar
                                </span>
                                <span className="flex items-center gap-1.5">
                                    <span className="w-3 h-3 rounded bg-green-500"></span>
                                    Kâr
                                </span>
                            </div>
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
}

function MetricCard({ icon, label, value, color, subtext, tooltip }: {
    icon: React.ReactNode;
    label: string;
    value: string;
    color: "green" | "red" | "yellow" | "cyan";
    subtext?: string;
    tooltip?: string;
}) {
    const colors = {
        green: "from-emerald-500/20 to-green-500/10 border-emerald-500/30 text-emerald-400",
        red: "from-red-500/20 to-rose-500/10 border-red-500/30 text-red-400",
        yellow: "from-amber-500/20 to-yellow-500/10 border-amber-500/30 text-amber-400",
        cyan: "from-cyan-500/20 to-blue-500/10 border-cyan-500/30 text-cyan-400"
    };

    return (
        <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className={`bg-linear-to-br ${colors[color]} border rounded-xl p-4`}
        >
            <div className="flex items-center gap-2 mb-2">
                {icon}
                <span className="text-[10px] uppercase font-bold tracking-wider text-slate-400">
                    {label}
                    {tooltip && <InfoTooltip text={tooltip} />}
                </span>
            </div>
            <div className="text-2xl font-black text-white">{value}</div>
            {subtext && <div className="text-[10px] text-slate-500 mt-1">{subtext}</div>}
        </motion.div>
    );
}

function ConfidenceBar({ label, value, initial, max, color, highlight, tooltip }: {
    label: string;
    value: number;
    initial: number;
    max: number;
    color: string;
    highlight?: boolean;
    tooltip?: string;
}) {
    const percentage = ((value - initial * 0.5) / (max - initial * 0.5)) * 100;
    const isProfit = value >= initial;

    const colorClasses: Record<string, string> = {
        red: "bg-red-500",
        orange: "bg-orange-500",
        yellow: "bg-yellow-500",
        cyan: "bg-cyan-500",
        green: "bg-green-500",
        emerald: "bg-emerald-500",
        teal: "bg-teal-500"
    };

    return (
        <div className={`flex items-center gap-3 ${highlight ? 'bg-cyan-500/10 -mx-2 px-2 py-1 rounded-lg' : ''}`}>
            <span className="w-24 text-xs text-slate-400 shrink-0">
                {label}
                {tooltip && <InfoTooltip text={tooltip} />}
            </span>
            <div className="flex-1 h-3 bg-slate-700/50 rounded-full overflow-hidden">
                <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${Math.max(5, Math.min(100, percentage))}%` }}
                    transition={{ duration: 0.8, ease: "easeOut" }}
                    className={`h-full ${colorClasses[color]} rounded-full`}
                />
            </div>
            <span className={`w-24 text-right text-xs font-bold ${isProfit ? 'text-emerald-400' : 'text-red-400'}`}>
                ${value.toLocaleString()}
            </span>
        </div>
    );
}
