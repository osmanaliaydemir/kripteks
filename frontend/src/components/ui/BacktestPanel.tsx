"use client";

import React, { useState } from "react";
import { BacktestService } from "@/lib/api";
import { toast } from "sonner";
import { PlayCircle, Sliders, TrendingUp, BarChart2, Calendar, Clock, DollarSign, Activity, AlertCircle } from "lucide-react";
import SearchableSelect from "./SearchableSelect";

interface Trade {
    date: string;
    type: "BUY" | "SELL";
    price: number;
    amount: number;
    pnl: number;
}

interface BacktestResult {
    totalPnl: number;
    winRate: number;
    totalTrades: number;
    maxDrawdown: number;
    trades: Trade[];
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

import { Coin, Strategy } from "@/types";

interface BacktestPanelProps {
    coins: Coin[];
    strategies: Strategy[];
}

export default function BacktestPanel({ coins, strategies }: BacktestPanelProps) {
    const [symbol, setSymbol] = useState(coins.length > 0 ? coins[0].symbol : "BTCUSDT");
    const [interval, setInterval] = useState("1h");
    const [strategy, setStrategy] = useState("RSI_Strategy");
    const [startDate, setStartDate] = useState("2023-01-01");
    const [endDate, setEndDate] = useState("2023-12-31");
    const [balance, setBalance] = useState(1000);
    const [loading, setLoading] = useState(false);
    const [result, setResult] = useState<BacktestResult | null>(null);

    const handleRunBacktest = async () => {
        setLoading(true);
        setResult(null);
        try {
            const data = await BacktestService.runBacktest({
                symbol,
                interval,
                strategy,
                startDate,
                endDate,
                initialBalance: balance
            });

            if (data?.success && data.result) {
                setResult(data.result);
                toast.success("Backtest Tamamlandı", { description: "Sonuçlar aşağıda listelenmiştir." });
            } else {
                toast.error("Hata", { description: data?.message || "Backtest çalıştırılamadı." });
            }
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : "Bağlantı hatası oluştu.";
            toast.error("Hata", { description: errorMessage });
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="space-y-6">
            {/* --- PARAMETERS CARD --- */}
            <div className="glass-card p-6 border border-white/10 rounded-2xl relative overflow-hidden group">
                <div className="absolute top-0 right-0 w-64 h-64 bg-primary/5 rounded-full blur-3xl -mr-32 -mt-32 transition-all group-hover:bg-primary/10"></div>

                <div className="relative z-10">
                    <div className="flex items-center gap-3 mb-6">
                        <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center border border-primary/20">
                            <Sliders className="text-primary" size={20} />
                        </div>
                        <div>
                            <h2 className="text-lg font-display font-bold text-white">Backtest Ayarları</h2>
                            <p className="text-xs text-slate-400">Stratejinizi geçmiş verilerle test edin</p>
                        </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                        <div className="space-y-1.5">
                            <label className="text-[10px] uppercase font-bold text-slate-500 tracking-wider flex items-center gap-1">
                                <Activity size={12} /> Sembol
                            </label>
                            {/* Not: SearchableSelect daha önce güncellenmişti */}
                            <SearchableSelect
                                value={symbol}
                                onChange={setSymbol}
                                options={coins.map(c => ({ id: c.symbol, label: c.symbol, ...c }))}
                                placeholder="Seçiniz..."
                            />
                        </div>

                        <div className="space-y-1.5">
                            <label className="text-[10px] uppercase font-bold text-slate-500 tracking-wider flex items-center gap-1">
                                <Clock size={12} /> Zaman Dilimi (Interval)
                            </label>
                            <select
                                value={interval}
                                onChange={(e) => setInterval(e.target.value)}
                                className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-primary/50 appearance-none"
                            >
                                {intervals.map((int) => (
                                    <option key={int.value} value={int.value}>{int.label}</option>
                                ))}
                            </select>
                        </div>

                        <div className="space-y-1.5">
                            <label className="text-[10px] uppercase font-bold text-slate-500 tracking-wider flex items-center gap-1">
                                <TrendingUp size={12} /> Strateji
                            </label>
                            <select
                                value={strategy}
                                onChange={(e) => setStrategy(e.target.value)}
                                className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-primary/50 appearance-none"
                            >
                                {strategies.map((str) => (
                                    <option key={str.id} value={str.id}>{str.name}</option>
                                ))}
                            </select>
                        </div>

                        <div className="space-y-1.5">
                            <label className="text-[10px] uppercase font-bold text-slate-500 tracking-wider flex items-center gap-1">
                                <Calendar size={12} /> Başlangıç Tarihi
                            </label>
                            <input
                                type="date"
                                value={startDate}
                                onChange={(e) => setStartDate(e.target.value)}
                                className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-primary/50 uppercase"
                            />
                        </div>

                        <div className="space-y-1.5">
                            <label className="text-[10px] uppercase font-bold text-slate-500 tracking-wider flex items-center gap-1">
                                <Calendar size={12} /> Bitiş Tarihi
                            </label>
                            <input
                                type="date"
                                value={endDate}
                                onChange={(e) => setEndDate(e.target.value)}
                                className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-primary/50 uppercase"
                            />
                        </div>

                        <div className="space-y-1.5">
                            <label className="text-[10px] uppercase font-bold text-slate-500 tracking-wider flex items-center gap-1">
                                <DollarSign size={12} /> Başlangıç Bakiyesi ($)
                            </label>
                            <input
                                type="number"
                                value={balance}
                                onChange={(e) => setBalance(Number(e.target.value))}
                                className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-primary/50 font-mono"
                            />
                        </div>
                    </div>

                    <div className="mt-6 flex justify-end">
                        <button
                            onClick={handleRunBacktest}
                            disabled={loading}
                            className="px-6 py-3 rounded-xl bg-primary hover:bg-amber-400 text-black font-bold text-sm shadow-lg shadow-primary/20 flex items-center gap-2 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            {loading ? (
                                <div className="w-4 h-4 border-2 border-black/30 border-t-black rounded-full animate-spin"></div>
                            ) : (
                                <PlayCircle size={18} />
                            )}
                            {loading ? "Hesaplanıyor..." : "Testi Başlat"}
                        </button>
                    </div>
                </div>
            </div>

            {/* --- RESULTS AREA --- */}
            {result && (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 animate-in fade-in slide-in-from-bottom-4 duration-500">
                    <div className="glass-card p-5 rounded-xl border border-white/10 flex flex-col items-center justify-center text-center gap-2">
                        <span className="text-xs uppercase font-bold text-slate-500">Toplam Kâr/Zarar</span>
                        <span className={`text-2xl font-bold font-mono ${result.totalPnl >= 0 ? "text-emerald-400" : "text-rose-400"}`}>
                            {result.totalPnl >= 0 ? "+" : ""}{result.totalPnl}%
                        </span>
                    </div>

                    <div className="glass-card p-5 rounded-xl border border-white/10 flex flex-col items-center justify-center text-center gap-2">
                        <span className="text-xs uppercase font-bold text-slate-500">Başarılı İşlem</span>
                        <span className="text-2xl font-bold text-white font-mono">
                            {result.winRate}%
                        </span>
                    </div>

                    <div className="glass-card p-5 rounded-xl border border-white/10 flex flex-col items-center justify-center text-center gap-2">
                        <span className="text-xs uppercase font-bold text-slate-500">Toplam İşlem</span>
                        <span className="text-2xl font-bold text-white font-mono">
                            {result.totalTrades}
                        </span>
                    </div>

                    <div className="glass-card p-5 rounded-xl border border-white/10 flex flex-col items-center justify-center text-center gap-2">
                        <span className="text-xs uppercase font-bold text-slate-500">Maksimum Düşüş</span>
                        <span className="text-2xl font-bold text-rose-400 font-mono">
                            {result.maxDrawdown}%
                        </span>
                    </div>

                    <div className="col-span-1 md:col-span-2 lg:col-span-4 glass-card p-6 rounded-xl border border-white/10 mt-2">
                        <div className="flex items-center gap-2 mb-4">
                            <BarChart2 className="text-primary" size={20} />
                            <h3 className="text-lg font-bold text-white">İşlem Geçmişi</h3>
                        </div>

                        {result.trades && result.trades.length > 0 ? (
                            <div className="overflow-x-auto">
                                <table className="w-full text-left border-collapse">
                                    <thead>
                                        <tr className="text-[10px] uppercase text-slate-500 border-b border-white/10">
                                            <th className="px-4 py-3">Tarih</th>
                                            <th className="px-4 py-3">Tür</th>
                                            <th className="px-4 py-3">Fiyat</th>
                                            <th className="px-4 py-3 text-right">Miktar</th>
                                            <th className="px-4 py-3 text-right">Kâr/Zarar</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-white/5 text-sm">
                                        {result.trades.map((trade: Trade, idx: number) => (
                                            <tr key={idx} className="hover:bg-white/5 transition-colors">
                                                <td className="px-4 py-3 text-slate-400 font-mono">{trade.date}</td>
                                                <td className="px-4 py-3">
                                                    <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${trade.type === 'BUY' ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'bg-rose-500/10 text-rose-400 border border-rose-500/20'}`}>
                                                        {trade.type}
                                                    </span>
                                                </td>
                                                <td className="px-4 py-3 text-white font-mono">${trade.price}</td>
                                                <td className="px-4 py-3 text-right text-slate-300 font-mono">{trade.amount}</td>
                                                <td className={`px-4 py-3 text-right font-bold font-mono ${trade.pnl >= 0 ? "text-emerald-400" : "text-rose-400"}`}>
                                                    {trade.pnl >= 0 ? "+" : ""}{trade.pnl}
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        ) : (
                            <div className="text-center py-10 text-slate-500">
                                <AlertCircle size={32} className="mx-auto mb-2 opacity-50" />
                                <p>Hiç işlem bulunamadı.</p>
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
}
