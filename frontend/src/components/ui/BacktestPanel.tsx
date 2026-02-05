"use client";

import React, { useState, useMemo } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { BacktestService } from "@/lib/api";
import { toast } from "sonner";
import { PlayCircle, Sliders, TrendingUp, BarChart2, Calendar, Clock, DollarSign, Activity, AlertCircle, Info, ChevronDown, Zap, Loader2, Dice6 } from "lucide-react";
import { ResponsiveContainer, ComposedChart, Area, XAxis, YAxis, Tooltip, CartesianGrid, Scatter, Cell } from "recharts";
import SearchableSelect from "./SearchableSelect";
import { useBacktestProgress } from "@/hooks/useBacktestProgress";
import MonteCarloVisualization from "./MonteCarloVisualization";

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

interface Trade {
    type: string;
    entryDate: string;
    exitDate: string;
    entryPrice: number;
    exitPrice: number;
    pnl: number;
}

interface Candle {
    time: string;
    open: number;
    high: number;
    low: number;
    close: number;
}

interface BacktestResult {
    totalPnl: number;
    totalPnlPercent: number;
    winRate: number;
    totalTrades: number;
    winningTrades: number;
    losingTrades: number;
    maxDrawdown: number;
    totalCommissionPaid: number;
    // Advanced Metrics (Phase 2)
    sharpeRatio: number;
    sortinoRatio: number;
    profitFactor: number;
    averageWin: number;
    averageLoss: number;
    maxConsecutiveWins: number;
    maxConsecutiveLosses: number;
    trades: Trade[];
    candles: Candle[];
}

interface OptimizationResult {
    bestParameters: Record<string, string>;
    bestPnlPercent: number;
    result: BacktestResult;
}

const intervals = [
    { value: "1m", label: "1 Dakika" },
    { value: "3m", label: "3 Dakika" },
    { value: "5m", label: "5 Dakika" },
    { value: "15m", label: "15 Dakika" },
    { value: "30m", label: "30 Dakika" },
    { value: "1h", label: "1 Saat" },
    { value: "2h", label: "2 Saat" },
    { value: "4h", label: "4 Saat" },
    { value: "6h", label: "6 Saat" },
    { value: "8h", label: "8 Saat" },
    { value: "12h", label: "12 Saat" },
    { value: "1d", label: "1 Gün" },
];

const STRATEGY_PARAMS: Record<string, any[]> = {
    "strategy-golden-rose": [
        { key: "sma1", label: "SMA 1 (Hızlı)", type: "number", default: "111", tooltip: "Kısa vadeli trendi belirleyen SMA periyodu." },
        { key: "sma2", label: "SMA 2 (Yavaş)", type: "number", default: "350", tooltip: "Uzun vadeli ana trendi belirleyen SMA periyodu." },
        { key: "tp", label: "Altın Oran Kâr", type: "number", default: "1.618", step: "0.001", tooltip: "SMA2 üzerinden Fibonacci kâr al çarpanı." },
        { key: "cycleTop", label: "Döngü Tepesi", type: "number", default: "2", step: "0.1", tooltip: "Piyasa doygunluğunu belirleyen çarpan." }
    ],
    "strategy-alpha-trend": [
        { key: "fastEma", label: "Hızlı EMA", type: "number", default: "20", tooltip: "Hızlı hareket eden ortalama periyodu." },
        { key: "slowEma", label: "Yavaş EMA", type: "number", default: "50", tooltip: "Trendin yönünü teyit eden yavaş ortalama." },
        { key: "rsiPeriod", label: "RSI Periyodu", type: "number", default: "14", tooltip: "RSI hesaplaması için kullanılacak mum sayısı." },
        { key: "rsiBuy", label: "Alım Eşiği", type: "number", default: "65", tooltip: "Kesişim olsa bile, RSI bu değerin altındaysa alım yapılır." },
        { key: "rsiSell", label: "Satış Eşiği", type: "number", default: "75", tooltip: "RSI bu değeri aşarsa kâr satışı tetiklenir." }
    ]
};

import { Coin, Strategy } from "@/types";

interface BacktestPanelProps {
    coins: Coin[];
    strategies: Strategy[];
    onRefreshCoins?: () => void;
    isCoinsLoading?: boolean;
}

export default function BacktestPanel({ coins, strategies, onRefreshCoins, isCoinsLoading }: BacktestPanelProps) {
    const [symbol, setSymbol] = useState("");
    const [interval, setInterval] = useState("1h");
    const [strategy, setStrategy] = useState("strategy-golden-rose");
    const [startDate, setStartDate] = useState(() => {
        const d = new Date();
        d.setMonth(d.getMonth() - 1);
        return d.toISOString().split('T')[0];
    });
    const [balance, setBalance] = useState(1000);
    const [strategyParams, setStrategyParams] = useState<Record<string, string>>({});
    const [loading, setLoading] = useState(false);
    const [result, setResult] = useState<BacktestResult | null>(null);
    const [optimizationResult, setOptimizationResult] = useState<OptimizationResult | null>(null);
    const [optimizing, setOptimizing] = useState(false);
    const [endDate, setEndDate] = useState<string>(new Date().toISOString().split('T')[0]);
    const [commissionRate, setCommissionRate] = useState(0.001); // 0.1% default
    const [slippageRate, setSlippageRate] = useState(0.0005); // 0.05% default

    // SignalR progress tracking
    const { progress, isConnected: isProgressConnected, startSession, endSession, resetProgress } = useBacktestProgress();

    // Result views state
    const [resultTab, setResultTab] = useState<"chart" | "trades">("chart");

    const selectedStrategyObj = useMemo(() => {
        return strategies.find(s => s.id === strategy) || strategies[0];
    }, [strategy, strategies]);

    const chartData = useMemo(() => {
        if (!result || !result.candles) return [];

        const startTimestamp = new Date(startDate).getTime();
        const sortedTrades = [...result.trades].sort((a, b) => new Date(a.entryDate).getTime() - new Date(b.entryDate).getTime());

        return result.candles
            .filter(candle => new Date(candle.time).getTime() >= startTimestamp)
            .map(candle => {
                const candleTime = new Date(candle.time).getTime();

                // Realized PnL up to this candle
                const totalRealizedSoFar = sortedTrades
                    .filter(t => new Date(t.exitDate).getTime() <= candleTime)
                    .reduce((sum, t) => sum + t.pnl, 0);

                let equity = balance + totalRealizedSoFar;

                // Unrealized PnL for currently open position
                const openTrade = sortedTrades.find(t =>
                    new Date(t.entryDate).getTime() <= candleTime &&
                    new Date(t.exitDate).getTime() > candleTime
                );

                if (openTrade) {
                    const realizedAtEntry = sortedTrades
                        .filter(t => new Date(t.exitDate).getTime() < new Date(openTrade.entryDate).getTime())
                        .reduce((sum, t) => sum + t.pnl, 0);
                    const qty = (balance + realizedAtEntry) / openTrade.entryPrice;
                    equity += (candle.close - openTrade.entryPrice) * qty;
                }

                const buyTrade = result.trades.find(t => new Date(t.entryDate).getTime() === candleTime);
                const sellTrade = result.trades.find(t => new Date(t.exitDate).getTime() === candleTime);

                return {
                    ...candle,
                    equity,
                    displayTime: new Date(candle.time).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' }),
                    displayDate: new Date(candle.time).toLocaleDateString('tr-TR'),
                    // Place signals on the equity line with small offsets
                    buySignal: buyTrade ? equity * 0.995 : null,
                    sellSignal: sellTrade ? equity * 1.005 : null,
                };
            });
    }, [result, startDate, balance]);

    const handleRunBacktest = async () => {
        if (!symbol) {
            toast.warning("Sembol Seçilmedi", { description: "Lütfen backtest yapmak istediğiniz bir parite seçiniz." });
            return;
        }

        setLoading(true);
        setResult(null);
        setOptimizationResult(null);
        try {
            const data = await BacktestService.run({
                symbol,
                interval,
                strategyId: strategy,
                startDate,
                endDate,
                initialBalance: balance,
                strategyParameters: strategyParams,
                commissionRate,
                slippageRate
            });

            if (data) {
                setResult(data);
                toast.success("Backtest Tamamlandı", { description: "Sonuçlar aşağıda listelenmiştir." });
            }
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : "Bağlantı hatası oluştu.";
            toast.error("Hata", { description: errorMessage });
        } finally {
            setLoading(false);
        }
    };

    const handleOptimize = async () => {
        if (!symbol) {
            toast.warning("Sembol Seçilmedi", { description: "Optimizasyon için sembol gereklidir." });
            return;
        }

        setOptimizing(true);
        setResult(null);
        setOptimizationResult(null);

        // Generate unique session ID and join SignalR group
        const sessionId = `opt-${Date.now()}`;

        try {
            // Try to use SignalR progress if connected
            if (isProgressConnected) {
                await startSession(sessionId);
                const data = await BacktestService.optimizeBacktestWithProgress(sessionId, {
                    symbol,
                    interval,
                    strategyId: strategy,
                    startDate,
                    endDate,
                    initialBalance: balance,
                    strategyParameters: strategyParams,
                    commissionRate,
                    slippageRate
                });
                await endSession(sessionId);

                if (data && data.result) {
                    setOptimizationResult(data);
                    setResult(data.result);
                    if (data.bestParameters) {
                        setStrategyParams(data.bestParameters);
                    }
                    toast.success("Optimizasyon Tamamlandı ✨", { description: "En kârlı 'Altın Ayarlar' bulundu ve uygulandı." });
                }
            } else {
                // Fallback to regular optimization
                const data = await BacktestService.optimizeBacktest({
                    symbol,
                    interval,
                    strategyId: strategy,
                    startDate,
                    endDate,
                    initialBalance: balance,
                    strategyParameters: strategyParams,
                    commissionRate,
                    slippageRate
                });

                if (data && data.result) {
                    setOptimizationResult(data);
                    setResult(data.result);
                    if (data.bestParameters) {
                        setStrategyParams(data.bestParameters);
                    }
                    toast.success("Optimizasyon Tamamlandı ✨", { description: "En kârlı 'Altın Ayarlar' bulundu ve uygulandı." });
                }
            }
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : "Optimizasyon hatası oluştu.";
            toast.error("Hata", { description: errorMessage });
        } finally {
            setOptimizing(false);
            resetProgress();
        }
    };

    return (
        <div className="space-y-6 pb-20">
            {/* --- PARAMETERS CARD --- */}
            <div className="glass-card p-8 border border-white/10 rounded-3xl relative overflow-hidden group">
                <div className="absolute top-0 right-0 w-64 h-64 bg-primary/5 rounded-full blur-3xl -mr-32 -mt-32 transition-all group-hover:bg-primary/10"></div>

                <div className="relative z-10">
                    <div className="flex items-center gap-4 mb-8">
                        <div className="w-12 h-12 rounded-2xl bg-primary/10 flex items-center justify-center border border-primary/20 shadow-inner">
                            <Sliders className="text-primary" size={24} />
                        </div>
                        <div>
                            <h2 className="text-xl font-display font-bold text-white tracking-tight">Backtest & Strateji Merkezi</h2>
                            <p className="text-xs text-slate-400 font-medium">Algoritmanızı geçmiş verilerle optimize edin</p>
                        </div>
                    </div>

                    <div className="grid grid-cols-1 lg:grid-cols-12 gap-10">
                        {/* Sol Taraf - Giriş Alanları (7 Birim) */}
                        <div className="lg:col-span-7 flex flex-col gap-8">
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                                <div className="space-y-2 text-left">
                                    <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-1.5 opacity-80 mt-1">
                                        <Activity size={12} className="text-primary/70" /> Sembol
                                        <InfoTooltip text="Test etmek istediğiniz kripto varlığı seçin. Veriler Binance üzerinden çekilir." />
                                    </label>
                                    <SearchableSelect
                                        value={symbol}
                                        onChange={setSymbol}
                                        options={coins.map(c => ({ id: c.symbol, label: c.symbol, ...c }))}
                                        placeholder="Parite Seçiniz..."
                                        onOpen={onRefreshCoins}
                                        isLoading={isCoinsLoading}
                                    />
                                </div>

                                <div className="space-y-2 text-left">
                                    <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-1.5 opacity-80 mt-1">
                                        <Clock size={12} className="text-primary/70" /> Zaman Dilimi
                                        <InfoTooltip text="Analizin yapılacağı mum grafiği periyodu. Kısa vade için 15m/1h, uzun vade için 4h/1d önerilir." />
                                    </label>
                                    <div className="relative">
                                        <select
                                            value={interval}
                                            onChange={(e) => setInterval(e.target.value)}
                                            className="w-full bg-slate-950/40 border border-white/5 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-primary/40 focus:bg-slate-950/60 transition-all appearance-none cursor-pointer"
                                        >
                                            {intervals.map((int) => (
                                                <option key={int.value} value={int.value}>{int.label}</option>
                                            ))}
                                        </select>
                                        <ChevronDown className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-slate-500 w-4 h-4" />
                                    </div>
                                </div>

                                <div className="space-y-2 text-left">
                                    <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-1.5 opacity-80 mt-1">
                                        <Calendar size={12} className="text-secondary/70" /> Başlangıç
                                        <InfoTooltip text="Backtest simülasyonunun ne kadar geriden başlayacağını belirler." />
                                    </label>
                                    <input
                                        type="date"
                                        value={startDate}
                                        onChange={(e) => setStartDate(e.target.value)}
                                        className="w-full bg-slate-950/40 border border-white/5 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-secondary/40 focus:bg-slate-950/60 transition-all uppercase cursor-pointer"
                                    />
                                </div>

                                <div className="space-y-2 text-left">
                                    <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-1.5 opacity-80 mt-1">
                                        <Calendar size={12} className="text-secondary/70" /> Bitiş
                                        <InfoTooltip text="Backtest simülasyonunun duracağı tarih. Boş bırakılırsa bugün kabul edilir." />
                                    </label>
                                    <input
                                        type="date"
                                        value={endDate}
                                        onChange={(e) => setEndDate(e.target.value)}
                                        className="w-full bg-slate-950/40 border border-white/5 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-secondary/40 focus:bg-slate-950/60 transition-all uppercase cursor-pointer"
                                    />
                                </div>

                                <div className="space-y-2 text-left">
                                    <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-1.5 opacity-80 mt-1">
                                        <DollarSign size={12} className="text-secondary/70" /> Bakiye ($)
                                        <InfoTooltip text="Testin en başında cüzdanınızda olduğu varsayılan sanal dolar miktarı." />
                                    </label>
                                    <input
                                        type="number"
                                        value={balance}
                                        onChange={(e) => setBalance(Number(e.target.value))}
                                        className="w-full bg-slate-950/40 border border-white/5 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-secondary/40 focus:bg-slate-950/60 transition-all font-mono"
                                    />
                                </div>

                                <div className="space-y-2 text-left">
                                    <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-1.5 opacity-80 mt-1">
                                        <TrendingUp size={12} className="text-primary/70" /> Strateji
                                        <InfoTooltip text="Geçmiş veriler üzerinde simüle edilecek alım-satım algoritması." />
                                    </label>
                                    <div className="relative">
                                        <select
                                            value={strategy}
                                            onChange={(e) => setStrategy(e.target.value)}
                                            className="w-full bg-slate-950/40 border border-white/5 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-primary/40 focus:bg-slate-950/60 transition-all appearance-none cursor-pointer"
                                        >
                                            {strategies.map((str) => (
                                                <option key={str.id} value={str.id}>{str.name}</option>
                                            ))}
                                        </select>
                                        <ChevronDown className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-slate-500 w-4 h-4" />
                                    </div>
                                </div>
                            </div>

                            {/* Buton Grubu */}
                            <div className="grid grid-cols-2 gap-6 pt-2">
                                <button
                                    onClick={handleRunBacktest}
                                    disabled={loading || optimizing || !symbol}
                                    className={`py-4 rounded-2xl font-bold text-sm shadow-2xl flex items-center justify-center gap-3 transition-all duration-300 scale-100 active:scale-95 ${loading || optimizing || !symbol
                                        ? "bg-slate-800/50 text-slate-500 cursor-not-allowed border border-white/5"
                                        : "bg-linear-to-r from-primary to-amber-400 text-black shadow-primary/20 hover:shadow-primary/40 hover:-translate-y-1 hover:brightness-110"
                                        }`}
                                >
                                    {loading ? (
                                        <div className="w-5 h-5 border-3 border-black/30 border-t-black rounded-full animate-spin"></div>
                                    ) : (
                                        <>
                                            <PlayCircle size={20} />
                                            <span>Normal Testi Başlat</span>
                                        </>
                                    )}
                                </button>

                                <button
                                    onClick={handleOptimize}
                                    disabled={loading || optimizing || !symbol}
                                    className={`py-4 rounded-2xl font-bold text-sm shadow-2xl flex items-center justify-center gap-3 transition-all duration-300 scale-100 active:scale-95 ${loading || optimizing || !symbol
                                        ? "bg-slate-800/50 text-slate-500 cursor-not-allowed border border-white/5"
                                        : "bg-linear-to-r from-emerald-400 to-cyan-400 text-black shadow-emerald-500/20 hover:shadow-emerald-500/40 hover:-translate-y-1 hover:brightness-110"
                                        }`}
                                >
                                    {optimizing ? (
                                        <div className="w-5 h-5 border-3 border-black/30 border-t-black rounded-full animate-spin"></div>
                                    ) : (
                                        <>
                                            <Zap size={20} />
                                            <span>Y.Z. Optimizasyon</span>
                                            <InfoTooltip text="Yapay Zeka modu, binlerce parametre kombinasyonunu test ederek seçtiğiniz tarih aralığında en çok kâr bırakan ayarları sizin yerinize bulur." />
                                        </>
                                    )}
                                </button>
                            </div>
                        </div>

                        {/* Sağ Taraf - Strateji Mantığı (5 Birim) */}
                        <div className="lg:col-span-5 flex flex-col">
                            <AnimatePresence mode="wait">
                                {selectedStrategyObj && (
                                    <motion.div
                                        key={selectedStrategyObj.id}
                                        initial={{ opacity: 0, x: 20 }}
                                        animate={{ opacity: 1, x: 0 }}
                                        exit={{ opacity: 0, x: -20 }}
                                        className="h-full p-8 bg-primary/5 border border-primary/10 rounded-3xl flex flex-col gap-5 items-start group/desc relative overflow-hidden"
                                    >
                                        <div className="absolute top-0 right-0 p-8 opacity-5">
                                            <Activity size={140} />
                                        </div>

                                        <div className="p-4 bg-primary/10 rounded-2xl text-primary shrink-0 transition-all group-hover/desc:bg-primary/20 group-hover/desc:scale-110 shadow-lg border border-primary/20">
                                            <Info size={28} />
                                        </div>

                                        <div className="space-y-4 relative z-10 w-full">
                                            <div className="space-y-2">
                                                <h3 className="text-[10px] font-bold text-primary/60 uppercase tracking-[0.2em] flex items-center gap-2">
                                                    Strateji Mantığı
                                                    <span className="w-1.5 h-1.5 rounded-full bg-primary animate-pulse"></span>
                                                </h3>
                                                <h4 className="text-2xl font-display font-bold text-white tracking-tight leading-tight">
                                                    {selectedStrategyObj.name}
                                                </h4>
                                            </div>
                                            <p className="text-sm text-slate-300 leading-relaxed font-medium">
                                                {selectedStrategyObj.description || "Bu strateji için açıklama bulunamadı."}
                                            </p>
                                            <div className="pt-4 flex flex-wrap gap-2">
                                                <span className="px-3 py-1.5 bg-white/5 rounded-xl text-[10px] font-bold text-slate-400 uppercase border border-white/5">Teknik Analiz</span>
                                                <span className="px-3 py-1.5 bg-white/5 rounded-xl text-[10px] font-bold text-slate-400 uppercase border border-white/5">HFT Hazır</span>
                                                <span className="px-3 py-1.5 bg-white/5 rounded-xl text-[10px] font-bold text-slate-400 uppercase border border-white/5">Düşük Gecikme</span>
                                            </div>
                                        </div>
                                    </motion.div>
                                )}
                            </AnimatePresence>
                        </div>
                    </div>

                    {/* Strateji Parametreleri - Alt Panel */}
                    {STRATEGY_PARAMS[strategy] && (
                        <div className="mt-10 p-6 bg-slate-950/30 border border-white/5 rounded-3xl space-y-6 shadow-inner">
                            <div className="flex items-center gap-3">
                                <div className="p-2 bg-secondary/10 rounded-xl text-secondary border border-secondary/20 shadow-md">
                                    <Sliders size={16} />
                                </div>
                                <h4 className="text-[11px] font-bold text-slate-400 uppercase tracking-[0.2em]">Parametre Konfigürasyonu</h4>
                                <InfoTooltip text="Stratejinin çalışma ayarlarını manuel olarak değiştirerek farklı hassasiyetlerde test yapabilirsiniz." />
                            </div>
                            <div className="grid grid-cols-2 lg:grid-cols-4 gap-8">
                                {STRATEGY_PARAMS[strategy].map((param) => (
                                    <div key={param.key} className="flex flex-col gap-2">
                                        <label className="text-[10px] font-bold text-slate-500 uppercase tracking-tight pl-1 flex items-center h-4">
                                            {param.label}
                                            <InfoTooltip text={param.tooltip || ""} />
                                        </label>
                                        <input
                                            type={param.type}
                                            step={param.step || "1"}
                                            value={strategyParams[param.key] ?? param.default}
                                            onChange={(e) => setStrategyParams(prev => ({
                                                ...prev,
                                                [param.key]: e.target.value
                                            }))}
                                            className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-sm text-secondary font-mono focus:border-secondary/40 focus:bg-slate-950/70 transition-all outline-none shadow-sm placeholder:text-slate-700"
                                        />
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}
                </div>
            </div>

            {/* --- RESULTS AREA --- */}
            {result && (
                <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
                    {/* Optimizasyon Bilgi Paneli */}
                    {optimizationResult && (
                        <div className="p-5 bg-emerald-500/10 border border-emerald-500/20 rounded-3xl flex flex-col md:flex-row items-center gap-6 shadow-lg shadow-emerald-500/5">
                            <div className="p-3 bg-emerald-500/20 rounded-2xl text-emerald-400 shadow-inner">
                                <Zap size={24} />
                            </div>
                            <div className="flex-1 text-center md:text-left">
                                <h4 className="text-base font-bold text-emerald-400">Y.Z. Altın Ayarlar Bulundu! ✨</h4>
                                <p className="text-xs text-emerald-400/70 font-medium">Sistem geçmiş veriyi tarayarak kârınızı maksimize eden en iyi parametreleri buldu ve panelinize uyguladı.</p>
                            </div>
                            <div className="flex flex-wrap justify-center gap-3">
                                {Object.entries(optimizationResult.bestParameters).map(([key, val]) => (
                                    <div key={key} className="px-3 py-1.5 bg-emerald-500/15 rounded-xl border border-emerald-500/20 shadow-sm">
                                        <span className="text-[10px] font-bold text-emerald-200 uppercase tracking-tight">{key}: <span className="text-white ml-0.5">{val}</span></span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                        <div className="glass-card p-6 rounded-2xl border border-white/10 flex flex-col items-center justify-center text-center gap-2 relative hover:brightness-110 transition-all shadow-lg">
                            <span className="text-xs uppercase font-bold text-slate-500 flex items-center gap-1.5 opacity-80">
                                Toplam Kâr/Zarar
                                <InfoTooltip text="Simülasyon süresince yapılan tüm işlemlerin net yüzde kazanç veya kaybı." />
                            </span>
                            <span className={`text-3xl font-bold font-mono tracking-tighter ${result.totalPnl >= 0 ? "text-emerald-400" : "text-rose-400"}`}>
                                {result.totalPnl >= 0 ? "+" : ""}{Number(result.totalPnl).toFixed(2)}%
                            </span>
                        </div>

                        <div className="glass-card p-6 rounded-2xl border border-white/10 flex flex-col items-center justify-center text-center gap-2 relative hover:brightness-110 transition-all shadow-lg">
                            <span className="text-xs uppercase font-bold text-slate-500 flex items-center gap-1.5 opacity-80">
                                Başarılı İşlem
                                <InfoTooltip text="Kârla sonuçlanan işlemlerin toplam işlem sayısına oranı (Win Rate)." />
                            </span>
                            <span className="text-3xl font-bold text-white font-mono tracking-tighter">
                                {Number(result.winRate).toFixed(2)}%
                            </span>
                        </div>

                        <div className="glass-card p-6 rounded-2xl border border-white/10 flex flex-col items-center justify-center text-center gap-2 relative hover:brightness-110 transition-all shadow-lg">
                            <span className="text-xs uppercase font-bold text-slate-500 flex items-center gap-1.5 opacity-80">
                                Toplam İşlem
                                <InfoTooltip text="Backtest süresince strateji tarafından açılan ve kapatılan toplam pozisyon sayısı." />
                            </span>
                            <span className="text-3xl font-bold text-white font-mono tracking-tighter">
                                {result.totalTrades}
                            </span>
                        </div>

                        <div className="glass-card p-6 rounded-2xl border border-white/10 flex flex-col items-center justify-center text-center gap-2 relative hover:brightness-110 transition-all shadow-lg">
                            <span className="text-xs uppercase font-bold text-slate-500 flex items-center gap-1.5 opacity-80">
                                Maksimum Düşüş
                                <InfoTooltip text="Bakiyenin gördüğü en yüksek seviyeden önceki en büyük düşüş oranı (Risk göstergesi)." />
                            </span>
                            <span className="text-3xl font-bold text-rose-400 font-mono tracking-tighter">
                                {Number(result.maxDrawdown).toFixed(2)}%
                            </span>
                        </div>

                        <div className="glass-card p-6 rounded-2xl border border-white/10 flex flex-col items-center justify-center text-center gap-2 relative hover:brightness-110 transition-all shadow-lg">
                            <span className="text-xs uppercase font-bold text-slate-500 flex items-center gap-1.5 opacity-80">
                                Toplam Komisyon
                                <InfoTooltip text="Tüm alım-satım işlemlerinde ödenen toplam komisyon tutarı." />
                            </span>
                            <span className="text-3xl font-bold text-amber-400 font-mono tracking-tighter">
                                ${Number(result.totalCommissionPaid || 0).toFixed(2)}
                            </span>
                        </div>

                        {/* Advanced Metrics Row */}
                        <div className="glass-card p-6 rounded-2xl border border-white/10 flex flex-col items-center justify-center text-center gap-2 relative hover:brightness-110 transition-all shadow-lg">
                            <span className="text-xs uppercase font-bold text-slate-500 flex items-center gap-1.5 opacity-80">
                                Sharpe Ratio
                                <InfoTooltip text="Risk-adjusted return metriği. >1 iyi, >2 çok iyi, >3 mükemmel kabul edilir." />
                            </span>
                            <span className={`text-3xl font-bold font-mono tracking-tighter ${(result.sharpeRatio || 0) > 1 ? "text-emerald-400" : "text-slate-400"}`}>
                                {Number(result.sharpeRatio || 0).toFixed(2)}
                            </span>
                        </div>

                        <div className="glass-card p-6 rounded-2xl border border-white/10 flex flex-col items-center justify-center text-center gap-2 relative hover:brightness-110 transition-all shadow-lg">
                            <span className="text-xs uppercase font-bold text-slate-500 flex items-center gap-1.5 opacity-80">
                                Profit Factor
                                <InfoTooltip text="Toplam kazanç / Toplam kayıp oranı. >1.5 iyi, >2 çok iyi kabul edilir." />
                            </span>
                            <span className={`text-3xl font-bold font-mono tracking-tighter ${(result.profitFactor || 0) > 1.5 ? "text-emerald-400" : "text-slate-400"}`}>
                                {Number(result.profitFactor || 0).toFixed(2)}
                            </span>
                        </div>

                        <div className="glass-card p-6 rounded-2xl border border-white/10 flex flex-col items-center justify-center text-center gap-2 relative hover:brightness-110 transition-all shadow-lg">
                            <span className="text-xs uppercase font-bold text-slate-500 flex items-center gap-1.5 opacity-80">
                                Ort. Kazanç
                                <InfoTooltip text="Kazançlı işlemlerin ortalama kâr miktarı." />
                            </span>
                            <span className="text-3xl font-bold text-emerald-400 font-mono tracking-tighter">
                                ${Number(result.averageWin || 0).toFixed(2)}
                            </span>
                        </div>

                        <div className="glass-card p-6 rounded-2xl border border-white/10 flex flex-col items-center justify-center text-center gap-2 relative hover:brightness-110 transition-all shadow-lg">
                            <span className="text-xs uppercase font-bold text-slate-500 flex items-center gap-1.5 opacity-80">
                                Maks. Seri Kazanç
                                <InfoTooltip text="Üst üste gelen en fazla kazançlı işlem sayısı." />
                            </span>
                            <span className="text-3xl font-bold text-cyan-400 font-mono tracking-tighter">
                                {result.maxConsecutiveWins || 0}
                            </span>
                        </div>

                    </div>
                    {/* --- CHART AREA --- */}
                    <div className="col-span-1 md:col-span-2 lg:col-span-4 glass-card p-8 rounded-3xl border border-white/10 mt-2 min-h-[500px] relative overflow-hidden group/chart shadow-xl">
                        <div className="absolute top-0 right-0 p-8 opacity-5 group-hover/chart:opacity-10 transition-opacity">
                            <TrendingUp size={200} />
                        </div>

                        <div className="flex flex-col md:flex-row items-center justify-between gap-6 mb-10 relative z-10">
                            <div className="flex items-center gap-4">
                                <div className="w-12 h-12 rounded-2xl bg-primary/10 flex items-center justify-center border border-primary/20 shadow-inner">
                                    <Activity className="text-primary" size={24} />
                                </div>
                                <div className="text-left">
                                    <h3 className="text-xl font-bold text-white tracking-tight">Performans Analizi</h3>
                                    <p className="text-xs text-slate-500 font-medium tracking-wide font-mono">STRETEJI SONUÇLARI & RİSK ANALİZİ</p>
                                </div>
                            </div>
                            <div className="flex items-center gap-1 p-1 bg-slate-900/50 border border-white/5 rounded-xl backdrop-blur-sm">
                                <button
                                    onClick={() => setResultTab("chart")}
                                    className={`px-4 py-2 rounded-lg text-xs font-bold transition-all flex items-center gap-2 ${resultTab === "chart" ? "bg-primary text-white shadow-lg shadow-primary/20" : "text-slate-500 hover:text-slate-300 hover:bg-white/5"}`}
                                >
                                    <TrendingUp size={14} /> Grafik
                                </button>
                                <button
                                    onClick={() => setResultTab("trades")}
                                    className={`px-4 py-2 rounded-lg text-xs font-bold transition-all flex items-center gap-2 ${resultTab === "trades" ? "bg-slate-700 text-white shadow-lg" : "text-slate-500 hover:text-slate-300 hover:bg-white/5"}`}
                                >
                                    <BarChart2 size={14} /> İşlemler
                                </button>
                            </div>
                        </div>

                        <AnimatePresence mode="wait">
                            {resultTab === "chart" && (
                                <motion.div
                                    key="chart-view"
                                    initial={{ opacity: 0, x: -20 }}
                                    animate={{ opacity: 1, x: 0 }}
                                    exit={{ opacity: 0, x: 20 }}
                                    className="h-[380px] w-full relative z-10"
                                >
                                    <ResponsiveContainer width="100%" height="100%">
                                        <ComposedChart data={chartData} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                                            <defs>
                                                <linearGradient id="chartGradient" x1="0" y1="0" x2="0" y2="1">
                                                    <stop offset="5%" stopColor="var(--color-primary, #3b82f6)" stopOpacity={0.3} />
                                                    <stop offset="95%" stopColor="var(--color-primary, #3b82f6)" stopOpacity={0} />
                                                </linearGradient>
                                            </defs>
                                            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.03)" vertical={false} />
                                            <XAxis
                                                dataKey="time"
                                                axisLine={false}
                                                tickLine={false}
                                                tick={{ fill: '#64748b', fontSize: 10, fontWeight: 700 }}
                                                tickFormatter={(val) => new Date(val).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })}
                                                minTickGap={60}
                                            />
                                            <YAxis
                                                domain={['auto', 'auto']}
                                                axisLine={false}
                                                tickLine={false}
                                                tick={{ fill: '#64748b', fontSize: 10, fontWeight: 700 }}
                                                orientation="right"
                                                tickFormatter={(val) => `$${Number(val).toLocaleString('tr-TR', { maximumFractionDigits: 0 })}`}
                                            />
                                            <Tooltip
                                                content={({ active, payload }) => {
                                                    if (active && payload && payload.length) {
                                                        const data = payload[0].payload;
                                                        return (
                                                            <div className="bg-slate-950/95 border border-white/20 p-5 rounded-2xl shadow-[0_25px_50px_rgba(0,0,0,0.5)] ring-1 ring-white/10 backdrop-blur-xl">
                                                                <div className="text-[10px] font-bold text-slate-500 uppercase tracking-widest mb-1.5 flex items-center gap-2">
                                                                    <Calendar size={10} /> {data.displayDate} <Clock size={10} className="ml-2" /> {data.displayTime}
                                                                </div>
                                                                <div className="text-2xl font-mono font-bold text-white mb-2 tracking-tighter">${Number(data.equity).toFixed(2)}</div>

                                                                <div className="flex flex-col gap-1.5 mb-3">
                                                                    <div className="flex justify-between items-center text-[10px] uppercase font-bold text-slate-500 tracking-tighter">
                                                                        <span>Portföy Değeri</span>
                                                                        <span className="text-white">${Number(data.equity).toLocaleString('tr-TR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</span>
                                                                    </div>
                                                                    <div className="flex justify-between items-center text-[10px] uppercase font-bold text-slate-500 tracking-tighter border-t border-white/5 pt-1.5">
                                                                        <span>Fiyat ({symbol})</span>
                                                                        <span className="text-slate-300">${Number(data.close).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 8 })}</span>
                                                                    </div>
                                                                </div>

                                                                {data.buySignal && (
                                                                    <div className="flex items-center gap-2.5 text-emerald-400 text-[10px] font-bold bg-emerald-400/15 px-3 py-2 rounded-xl border border-emerald-400/20">
                                                                        <div className="w-2 h-2 rounded-full bg-emerald-400 shadow-[0_0_8px_rgba(16,185,129,0.5)] animate-pulse"></div> SİNYAL: ALIŞ POSİZYONU
                                                                    </div>
                                                                )}
                                                                {data.sellSignal && (
                                                                    <div className="flex items-center gap-2.5 text-rose-400 text-[10px] font-bold bg-rose-400/15 px-3 py-2 rounded-xl border border-rose-400/20">
                                                                        <div className="w-2 h-2 rounded-full bg-rose-400 shadow-[0_0_8px_rgba(244,63,94,0.5)] animate-pulse"></div> SİNYAL: SATIŞ / ÇIKIŞ
                                                                    </div>
                                                                )}
                                                            </div>
                                                        );
                                                    }
                                                    return null;
                                                }}
                                            />
                                            <Area
                                                type="monotone"
                                                dataKey="equity"
                                                stroke="var(--color-primary, #3b82f6)"
                                                strokeWidth={3}
                                                fillOpacity={1}
                                                fill="url(#chartGradient)"
                                                animationDuration={1500}
                                                activeDot={{ r: 6, fill: "#fff", stroke: "var(--color-primary, #3b82f6)", strokeWidth: 2 }}
                                            />
                                            <Scatter dataKey="buySignal" fill="#10b981">
                                                {chartData.map((_entry, index) => (
                                                    <Cell key={`cell-buy-${index}`} fill="#10b981" />
                                                ))}
                                            </Scatter>
                                            <Scatter dataKey="sellSignal" fill="#f43f5e">
                                                {chartData.map((_entry, index) => (
                                                    <Cell key={`cell-sell-${index}`} fill="#f43f5e" />
                                                ))}
                                            </Scatter>
                                        </ComposedChart>
                                    </ResponsiveContainer>
                                </motion.div>
                            )}


                            {resultTab === "trades" && (
                                <motion.div
                                    key="trades-view"
                                    initial={{ opacity: 0, x: 20 }}
                                    animate={{ opacity: 1, x: 0 }}
                                    exit={{ opacity: 0, x: -20 }}
                                    className="relative z-10"
                                >
                                    <div className="flex items-center gap-3 mb-6 pt-4 border-t border-white/5">
                                        <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center border border-primary/20">
                                            <BarChart2 className="text-primary" size={20} />
                                        </div>
                                        <div className="text-left">
                                            <h3 className="text-lg font-bold text-white tracking-tight">Algoritmik İşlem Günlüğü</h3>
                                            <p className="text-[10px] text-slate-500 uppercase font-bold tracking-widest">Tüm Geçmiş İşlemler</p>
                                        </div>
                                    </div>

                                    {result.trades && result.trades.length > 0 ? (
                                        <div className="overflow-x-auto custom-scrollbar">
                                            <table className="w-full text-left border-collapse">
                                                <thead>
                                                    <tr className="text-[10px] uppercase text-slate-500 border-b border-white/5">
                                                        <th className="px-5 py-4 font-bold tracking-widest">Giriş Zamanı</th>
                                                        <th className="px-5 py-4 font-bold tracking-widest">Çıkış Zamanı</th>
                                                        <th className="px-5 py-4 font-bold tracking-widest">Strateji Türü</th>
                                                        <th className="px-5 py-4 font-bold tracking-widest text-center">İşlem ($)</th>
                                                        <th className="px-5 py-4 text-right font-bold tracking-widest">Net PnL (%)</th>
                                                    </tr>
                                                </thead>
                                                <tbody className="divide-y divide-white/5 text-sm">
                                                    {result.trades.map((trade: Trade, idx: number) => (
                                                        <tr key={idx} className="hover:bg-white/5 transition-all group/row">
                                                            <td className="px-5 py-4 text-slate-400 font-mono text-xs group-hover/row:text-slate-200">
                                                                {new Date(trade.entryDate).toLocaleString('tr-TR')}
                                                            </td>
                                                            <td className="px-5 py-4 text-slate-400 font-mono text-xs group-hover/row:text-slate-200">
                                                                {new Date(trade.exitDate).toLocaleString('tr-TR')}
                                                            </td>
                                                            <td className="px-5 py-4">
                                                                <span className={`px-2.5 py-1 rounded-lg text-[10px] font-bold tracking-wide uppercase ${trade.pnl > 0 ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 shadow-[0_0_10px_rgba(16,185,129,0.1)]' : 'bg-rose-500/10 text-rose-400 border border-rose-500/20 shadow-[0_0_10px_rgba(244,63,94,0.1)]'}`}>
                                                                    {trade.type}
                                                                </span>
                                                            </td>
                                                            <td className="px-5 py-4 text-white font-mono text-xs text-center">
                                                                <div className="flex flex-col items-center gap-0.5">
                                                                    <span className="opacity-40 text-[8px] uppercase">Giriş: {Number(trade.entryPrice).toFixed(2)}</span>
                                                                    <span className="opacity-40 text-[8px] uppercase">Çıkış: {Number(trade.exitPrice).toFixed(2)}</span>
                                                                </div>
                                                            </td>
                                                            <td className={`px-5 py-4 text-right font-bold font-mono text-xs ${trade.pnl >= 0 ? "text-emerald-400" : "text-rose-400"}`}>
                                                                {trade.pnl >= 0 ? "+" : ""}{Number(trade.pnl).toFixed(2)}%
                                                            </td>
                                                        </tr>
                                                    ))}
                                                </tbody>
                                            </table>
                                        </div>
                                    ) : (
                                        <div className="text-center py-16 text-slate-600 bg-slate-950/20 rounded-2xl border border-white/5 border-dashed">
                                            <AlertCircle size={40} className="mx-auto mb-4 opacity-20" />
                                            <p className="font-medium">Seçilen tarihlerde strateji kriterlerine uygun işlem oluşmadı.</p>
                                        </div>
                                    )}
                                </motion.div>
                            )}
                        </AnimatePresence>
                    </div>

                    {/* --- MONTE CARLO AREA --- */}
                    <div className="mt-8">
                        <MonteCarloVisualization backtestResult={result} />
                    </div>
                </div>
            )}
        </div>
    );
}
