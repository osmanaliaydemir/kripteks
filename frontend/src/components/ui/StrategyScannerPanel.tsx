"use client";

import React, { useState, useMemo } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { BacktestService } from "@/lib/api";
import { toast } from "sonner";
import {
    Search, PlayCircle, Sliders, TrendingUp, BarChart2, Calendar,
    Clock, DollarSign, Activity, AlertCircle, Info, ChevronDown,
    Zap, Loader2, ListFilter, CheckCircle2, XCircle, ArrowUpDown
} from "lucide-react";
import { Coin, Strategy } from "@/types";

interface BatchResultItem {
    symbol: string;
    totalPnlPercent: number;
    winRate: number;
    totalTrades: number;
    maxDrawdown: number;
    profitFactor: number;
    sharpeRatio: number;
    success: boolean;
    errorMessage?: string;
}

interface StrategyScannerPanelProps {
    coins: Coin[];
    strategies: Strategy[];
    onRefreshCoins?: () => void;
    isCoinsLoading?: boolean;
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
    { value: "12h", label: "12 Saat" },
    { value: "1d", label: "1 Gün" },
];

const STRATEGY_PARAMS: Record<string, any[]> = {
    "strategy-golden-rose": [
        { key: "sma1", label: "SMA 1", type: "number", default: "111" },
        { key: "sma2", label: "SMA 2", type: "number", default: "350" },
        { key: "tp", label: "Kâr Al", type: "number", default: "1.618" },
        { key: "cycleTop", label: "Döngü", type: "number", default: "2" }
    ],
    "strategy-alpha-trend": [
        { key: "fastEma", label: "Fast EMA", type: "number", default: "20" },
        { key: "slowEma", label: "Slow EMA", type: "number", default: "50" },
        { key: "rsiBuy", label: "RSI Buy", type: "number", default: "65" }
    ]
};

export default function StrategyScannerPanel({ coins, strategies, onRefreshCoins, isCoinsLoading }: StrategyScannerPanelProps) {
    const [selectedSymbols, setSelectedSymbols] = useState<string[]>([]);
    const [interval, setInterval] = useState("1h");
    const [strategy, setStrategy] = useState("strategy-golden-rose");
    const [startDate, setStartDate] = useState(() => {
        const d = new Date();
        d.setMonth(d.getMonth() - 1);
        return d.toISOString().split('T')[0];
    });
    const [endDate, setEndDate] = useState<string>(new Date().toISOString().split('T')[0]);
    const [balance, setBalance] = useState(1000);
    const [strategyParams, setStrategyParams] = useState<Record<string, string>>({});
    const [loading, setLoading] = useState(false);
    const [results, setResults] = useState<BatchResultItem[]>([]);
    const [searchTerm, setSearchTerm] = useState("");
    const [sortConfig, setSortConfig] = useState<{ key: keyof BatchResultItem; direction: 'asc' | 'desc' } | null>(null);

    const filteredCoins = useMemo(() => {
        return coins.filter(c => c.symbol.toLowerCase().includes(searchTerm.toLowerCase()));
    }, [coins, searchTerm]);

    const handleToggleSymbol = (symbol: string) => {
        setSelectedSymbols(prev =>
            prev.includes(symbol) ? prev.filter(s => s !== symbol) : [...prev, symbol]
        );
    };

    const handleSelectTop = (count: number) => {
        const topSymbols = coins.slice(0, count).map(c => c.symbol);
        setSelectedSymbols(topSymbols);
    };

    const handleRunScanner = async () => {
        if (selectedSymbols.length === 0) {
            toast.warning("Sembol Seçilmedi", { description: "Lütfen tarama yapılacak pariteleri seçiniz." });
            return;
        }

        setLoading(true);
        setResults([]);
        try {
            const data = await BacktestService.scan({
                symbols: selectedSymbols,
                interval,
                strategyId: strategy,
                startDate,
                endDate,
                initialBalance: balance,
                strategyParameters: strategyParams,
                commissionRate: 0.001,
                slippageRate: 0.0005
            });

            if (data && data.results) {
                setResults(data.results);
                toast.success("Tarama Tamamlandı", { description: `${data.results.length} parite başarıyla tarandı.` });
            }
        } catch (error: any) {
            toast.error("Hata", { description: error.message || "Bağlantı hatası oluştu." });
        } finally {
            setLoading(false);
        }
    };

    const sortedResults = useMemo(() => {
        if (!sortConfig) return results;
        return [...results].sort((a, b) => {
            const aValue = a[sortConfig.key];
            const bValue = b[sortConfig.key];
            if (aValue === undefined || bValue === undefined) return 0;
            if (aValue < bValue) return sortConfig.direction === 'asc' ? -1 : 1;
            if (aValue > bValue) return sortConfig.direction === 'asc' ? 1 : -1;
            return 0;
        });
    }, [results, sortConfig]);

    const requestSort = (key: keyof BatchResultItem) => {
        let direction: 'asc' | 'desc' = 'desc';
        if (sortConfig && sortConfig.key === key && sortConfig.direction === 'desc') {
            direction = 'asc';
        }
        setSortConfig({ key, direction });
    };

    const selectedStrategyObj = useMemo(() => {
        return strategies.find(s => s.id === strategy) || strategies[0];
    }, [strategy, strategies]);

    return (
        <div className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                {/* Sol Panel - Seçim ve Ayarlar */}
                <div className="lg:col-span-4 space-y-6">
                    <div className="glass-card p-6 rounded-3xl border border-white/10 space-y-6">
                        <div className="flex items-center gap-3">
                            <div className="p-2 bg-primary/10 rounded-xl text-primary border border-primary/20">
                                <Activity size={18} />
                            </div>
                            <h3 className="font-bold text-white">Strateji Tarayıcı</h3>
                        </div>

                        <div className="space-y-4">
                            <div className="space-y-2">
                                <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center justify-between">
                                    <span>Parite Seçimi ({selectedSymbols.length})</span>
                                    <div className="flex gap-2">
                                        <button onClick={() => handleSelectTop(20)} className="text-primary hover:underline transition-all font-bold">Top 20</button>
                                        <button onClick={() => setSelectedSymbols([])} className="text-rose-400 hover:underline transition-all font-bold">Temizle</button>
                                    </div>
                                </label>

                                {/* Seçili Pariteler Etiketleri */}
                                {selectedSymbols.length > 0 && (
                                    <div className="flex flex-wrap gap-1.5 p-3 bg-slate-950/40 rounded-xl border border-white/5 max-h-24 overflow-y-auto custom-scrollbar">
                                        {selectedSymbols.map(s => (
                                            <button
                                                key={s}
                                                onClick={() => handleToggleSymbol(s)}
                                                className="px-2 py-1 bg-primary/20 hover:bg-rose-500/20 text-primary hover:text-rose-400 border border-primary/20 hover:border-rose-500/30 rounded-lg text-[10px] font-bold transition-all flex items-center gap-1 group"
                                            >
                                                {s} <XCircle size={10} className="opacity-50 group-hover:opacity-100" />
                                            </button>
                                        ))}
                                    </div>
                                )}
                                <div className="relative">
                                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 w-4 h-4" />
                                    <input
                                        type="text"
                                        placeholder="Sembol ara..."
                                        value={searchTerm}
                                        onChange={(e) => setSearchTerm(e.target.value)}
                                        className="w-full bg-slate-950/40 border border-white/5 rounded-xl pl-10 pr-4 py-2 text-xs text-white focus:outline-none focus:border-primary/40 focus:bg-slate-950/60 transition-all font-mono"
                                    />
                                </div>
                                <div className="max-h-40 overflow-y-auto pr-2 custom-scrollbar grid grid-cols-2 gap-2 mt-2">
                                    {isCoinsLoading ? (
                                        <div className="col-span-2 text-center py-4 text-xs text-slate-500 animate-pulse">Yükleniyor...</div>
                                    ) : filteredCoins.map(coin => (
                                        <button
                                            key={coin.symbol}
                                            onClick={() => handleToggleSymbol(coin.symbol)}
                                            className={`px-3 py-2 rounded-lg text-[10px] font-bold text-left transition-all border ${selectedSymbols.includes(coin.symbol)
                                                ? "bg-primary text-white border-primary shadow-[0_0_15px_rgba(59,130,246,0.3)] scale-[1.02] z-10"
                                                : "bg-white/5 border-white/5 text-slate-400 hover:bg-white/10"
                                                }`}
                                        >
                                            {coin.symbol}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div className="space-y-2">
                                    <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest">Strateji</label>
                                    <select
                                        value={strategy}
                                        onChange={(e) => setStrategy(e.target.value)}
                                        className="w-full bg-slate-950/40 border border-white/5 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-primary/40 appearance-none cursor-pointer"
                                    >
                                        {strategies.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                                    </select>
                                </div>
                                <div className="space-y-2">
                                    <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest">Zaman</label>
                                    <select
                                        value={interval}
                                        onChange={(e) => setInterval(e.target.value)}
                                        className="w-full bg-slate-950/40 border border-white/5 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-primary/40 appearance-none cursor-pointer"
                                    >
                                        {intervals.map(i => <option key={i.value} value={i.value}>{i.label}</option>)}
                                    </select>
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div className="space-y-2">
                                    <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest">Başlangıç</label>
                                    <input
                                        type="date"
                                        value={startDate}
                                        onChange={(e) => setStartDate(e.target.value)}
                                        className="w-full bg-slate-950/40 border border-white/5 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-primary/40"
                                    />
                                </div>
                                <div className="space-y-2">
                                    <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest">Bakiye</label>
                                    <input
                                        type="number"
                                        value={balance}
                                        onChange={(e) => setBalance(Number(e.target.value))}
                                        className="w-full bg-slate-950/40 border border-white/5 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-primary/40 font-mono"
                                    />
                                </div>
                            </div>

                            <button
                                onClick={handleRunScanner}
                                disabled={loading || selectedSymbols.length === 0}
                                className="w-full py-4 bg-linear-to-r from-primary to-indigo-500 rounded-2xl font-bold text-sm text-white shadow-lg shadow-primary/20 hover:shadow-primary/40 transition-all active:scale-95 flex items-center justify-center gap-3 disabled:opacity-50 disabled:cursor-not-allowed group"
                            >
                                {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : <><PlayCircle className="w-5 h-5 group-hover:scale-110 transition-transform" /> <span>Analizi Başlat</span></>}
                            </button>
                        </div>
                    </div>
                </div>

                {/* Sağ Panel - Sonuç Tablosu */}
                <div className="lg:col-span-8">
                    <div className="glass-card min-h-[500px] rounded-3xl border border-white/10 overflow-hidden flex flex-col">
                        <div className="p-6 border-b border-white/5 flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="p-2 bg-emerald-500/10 rounded-xl text-emerald-400 border border-emerald-500/20">
                                    <TrendingUp size={18} />
                                </div>
                                <h3 className="font-bold text-white">Analiz Sonuçları</h3>
                            </div>
                            <div className="text-[10px] text-slate-500 font-mono">
                                {results.length > 0 && `${results.length} Sonuç Bulundu`}
                            </div>
                        </div>

                        <div className="flex-1 overflow-x-auto overflow-y-auto max-h-[600px] custom-scrollbar">
                            <table className="w-full text-left border-collapse">
                                <thead className="sticky top-0 bg-slate-900 border-b border-white/5 z-10">
                                    <tr className="bg-slate-900/80 backdrop-blur-md">
                                        <th className="p-4 text-[10px] font-bold text-slate-500 uppercase tracking-wider cursor-pointer group" onClick={() => requestSort('symbol')}>
                                            <div className="flex items-center gap-2">Sembol <ArrowUpDown size={10} className="opacity-0 group-hover:opacity-100 transition-opacity" /></div>
                                        </th>
                                        <th className="p-4 text-[10px] font-bold text-slate-500 uppercase tracking-wider cursor-pointer group" onClick={() => requestSort('totalPnlPercent')}>
                                            <div className="flex items-center gap-2">Kâr/Zarar (%) <ArrowUpDown size={10} className="opacity-0 group-hover:opacity-100 transition-opacity" /></div>
                                        </th>
                                        <th className="p-4 text-[10px] font-bold text-slate-500 uppercase tracking-wider cursor-pointer group" onClick={() => requestSort('winRate')}>
                                            <div className="flex items-center gap-2">Başarı Oranı <ArrowUpDown size={10} className="opacity-0 group-hover:opacity-100 transition-opacity" /></div>
                                        </th>
                                        <th className="p-4 text-[10px] font-bold text-slate-500 uppercase tracking-wider cursor-pointer group" onClick={() => requestSort('totalTrades')}>
                                            <div className="flex items-center gap-2">İşlem <ArrowUpDown size={10} className="opacity-0 group-hover:opacity-100 transition-opacity" /></div>
                                        </th>
                                        <th className="p-4 text-[10px] font-bold text-slate-500 uppercase tracking-wider cursor-pointer group" onClick={() => requestSort('maxDrawdown')}>
                                            <div className="flex items-center gap-2">Max DD <ArrowUpDown size={10} className="opacity-0 group-hover:opacity-100 transition-opacity" /></div>
                                        </th>
                                        <th className="p-4 text-[10px] font-bold text-slate-500 uppercase tracking-wider">Durum</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <AnimatePresence>
                                        {sortedResults.length > 0 ? (
                                            sortedResults.map((res, idx) => (
                                                <motion.tr
                                                    key={res.symbol}
                                                    initial={{ opacity: 0, y: 10 }}
                                                    animate={{ opacity: 1, y: 0 }}
                                                    transition={{ delay: idx * 0.03 }}
                                                    className="border-b border-white/5 hover:bg-white/5 transition-colors group cursor-default"
                                                >
                                                    <td className="p-4">
                                                        <span className="text-sm font-bold text-white group-hover:text-primary transition-colors">{res.symbol}</span>
                                                    </td>
                                                    <td className="p-4">
                                                        <span className={`text-sm font-mono font-bold ${res.totalPnlPercent >= 0 ? "text-emerald-400" : "text-rose-400"}`}>
                                                            {res.totalPnlPercent >= 0 ? "+" : ""}{res.totalPnlPercent.toFixed(2)}%
                                                        </span>
                                                    </td>
                                                    <td className="p-4">
                                                        <span className="text-sm font-mono text-slate-300">{(res.winRate || 0).toFixed(1)}%</span>
                                                    </td>
                                                    <td className="p-4">
                                                        <span className="text-sm font-mono text-slate-300">{res.totalTrades}</span>
                                                    </td>
                                                    <td className="p-4">
                                                        <span className="text-sm font-mono text-rose-400/80">{(res.maxDrawdown || 0).toFixed(1)}%</span>
                                                    </td>
                                                    <td className="p-4">
                                                        {res.success ? (
                                                            <div className="flex items-center gap-2 text-[10px] font-bold text-emerald-500">
                                                                <CheckCircle2 size={12} /> OK
                                                            </div>
                                                        ) : (
                                                            <div className="flex items-center gap-2 text-[10px] font-bold text-rose-500 group/err relative" title={res.errorMessage}>
                                                                <XCircle size={12} /> HATA
                                                            </div>
                                                        )}
                                                    </td>
                                                </motion.tr>
                                            ))
                                        ) : (
                                            <tr>
                                                <td colSpan={6} className="p-20 text-center">
                                                    <div className="flex flex-col items-center gap-4">
                                                        {loading ? (
                                                            <div className="relative">
                                                                <div className="w-16 h-16 border-4 border-primary/20 border-t-primary rounded-full animate-spin"></div>
                                                                <Activity className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-primary animate-pulse" size={24} />
                                                            </div>
                                                        ) : (
                                                            <>
                                                                <div className="w-16 h-16 bg-slate-800/50 rounded-2xl flex items-center justify-center text-slate-500">
                                                                    <Activity size={32} />
                                                                </div>
                                                                <div className="space-y-1">
                                                                    <p className="text-slate-400 font-bold">Henüz Sonuç Yok</p>
                                                                    <p className="text-xs text-slate-500">Strateji taraması yapmak için sol panelden pariteleri seçip başlatın.</p>
                                                                </div>

                                                                {selectedStrategyObj && (
                                                                    <motion.div
                                                                        initial={{ opacity: 0, scale: 0.95 }}
                                                                        animate={{ opacity: 1, scale: 1 }}
                                                                        className="mt-8 max-w-md p-6 bg-primary/5 border border-primary/10 rounded-3xl relative overflow-hidden group/strat"
                                                                    >
                                                                        <div className="absolute top-0 right-0 p-4 opacity-[0.03] group-hover/strat:opacity-[0.05] transition-opacity">
                                                                            <Activity size={80} />
                                                                        </div>
                                                                        <div className="relative z-10 flex flex-col items-center text-center gap-3">
                                                                            <h4 className="text-xs font-bold text-primary uppercase tracking-widest flex items-center gap-2">
                                                                                <Info size={14} className="text-primary/70" /> {selectedStrategyObj.name}
                                                                            </h4>
                                                                            <p className="text-xs text-slate-400 leading-relaxed font-medium">
                                                                                {selectedStrategyObj.description || "Bu strateji için açıklama bulunamadı."}
                                                                            </p>
                                                                            <div className="flex gap-2 pt-2">
                                                                                <span className="px-2 py-1 bg-white/5 rounded-lg text-[8px] font-bold text-slate-500 border border-white/5 uppercase">Algoritmik</span>
                                                                                <span className="px-2 py-1 bg-white/5 rounded-lg text-[8px] font-bold text-slate-500 border border-white/5 uppercase">Hızlı Analiz</span>
                                                                            </div>
                                                                        </div>
                                                                    </motion.div>
                                                                )}
                                                            </>
                                                        )}
                                                    </div>
                                                </td>
                                            </tr>
                                        )}
                                    </AnimatePresence>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
