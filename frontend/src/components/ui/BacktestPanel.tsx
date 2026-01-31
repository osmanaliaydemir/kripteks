"use client";

import { useState } from "react";
import { Coin, Strategy } from "@/types";
import { Play, TrendingUp, TrendingDown, Clock, BarChart3, RotateCcw } from "lucide-react";
import SearchableSelect from "@/components/ui/SearchableSelect";
import { API_URL } from "@/lib/api"; // Endpoint için

interface BacktestResult {
    totalTrades: number;
    winningTrades: number;
    losingTrades: number;
    totalPnl: number;
    totalPnlPercent: number;
    winRate: number;
    maxDrawdown: number;
    trades: any[]; // Detaylı işlem listesi
}

export default function BacktestPanel({ coins, strategies }: { coins: Coin[], strategies: Strategy[] }) {
    const [selectedCoin, setSelectedCoin] = useState("BTC/USDT");
    const [selectedStrategy, setSelectedStrategy] = useState(strategies[0]?.id || "");
    const [period, setPeriod] = useState("7d"); // 7d, 30d, 90d
    const [interval, setInterval] = useState("15m"); // Varsayılan 15dk
    const [amount, setAmount] = useState(1000);

    const [isLoading, setIsLoading] = useState(false);
    const [result, setResult] = useState<BacktestResult | null>(null);

    const handleRunBacktest = async () => {
        setIsLoading(true);
        setResult(null);
        try {
            // BACKEND ENDPOINT: POST /api/Backtest/run
            const res = await fetch(`${API_URL}/Backtest/run`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    symbol: selectedCoin,
                    strategyId: selectedStrategy,
                    period: period,
                    interval: interval,
                    initialBalance: amount
                })
            });

            if (!res.ok) throw new Error("Backtest başarısız");
            const data = await res.json();
            setResult(data);

        } catch (error) {
            console.error(error);
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 bg-slate-800/40 p-6 rounded-3xl border border-slate-700/50">

                {/* SETTINGS CARD */}
                <div className="space-y-4">
                    <h3 className="text-white font-bold flex items-center gap-2">
                        <Clock className="text-cyan-400" size={18} />
                        Simülasyon Ayarları
                    </h3>

                    <div>
                        <label className="text-xs text-slate-400 uppercase font-bold mb-1.5 block">Parite</label>
                        <SearchableSelect
                            options={coins.map(c => ({ id: c.symbol, label: c.symbol, ...c }))}
                            value={selectedCoin}
                            onChange={setSelectedCoin}
                            placeholder="Coin Seç..."
                        />
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="text-xs text-slate-400 uppercase font-bold mb-1.5 block">Süre (Geçmiş)</label>
                            <select
                                value={period}
                                onChange={(e) => setPeriod(e.target.value)}
                                className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2.5 text-slate-200 text-sm outline-none focus:border-cyan-500 transition-all"
                            >
                                <option value="1d">Son 24 Saat</option>
                                <option value="7d">Son 1 Hafta</option>
                                <option value="30d">Son 1 Ay</option>
                                <option value="90d">Son 3 Ay</option>
                                <option value="180d">Son 6 Ay</option>
                                <option value="365d">Son 1 Yıl</option>
                            </select>
                        </div>
                        <div>
                            <label className="text-xs text-slate-400 uppercase font-bold mb-1.5 block">Grafik (Mum)</label>
                            <select
                                value={interval}
                                onChange={(e) => setInterval(e.target.value)}
                                className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2.5 text-slate-200 text-sm outline-none focus:border-cyan-500 transition-all font-mono"
                            >
                                <option value="3m">3dk</option>
                                <option value="5m">5dk</option>
                                <option value="15m">15dk</option>
                                <option value="30m">30dk</option>
                                <option value="1h">1sa</option>
                                <option value="2h">2sa</option>
                                <option value="4h">4sa</option>
                                <option value="1d">1 Gün</option>
                            </select>
                        </div>
                    </div>

                    <div>
                        <label className="text-xs text-slate-400 uppercase font-bold mb-1.5 block">Başlangıç Bakiyesi</label>
                        <input
                            type="number"
                            value={amount}
                            onChange={(e) => setAmount(Number(e.target.value))}
                            className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2.5 text-slate-200 text-sm outline-none focus:border-cyan-500 transition-all"
                        />
                    </div>

                    <div>
                        <label className="text-xs text-slate-400 uppercase font-bold mb-1.5 block">Strateji</label>
                        <select className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2.5 text-slate-200 text-sm outline-none focus:border-cyan-500 transition-all" value={selectedStrategy} onChange={(e) => setSelectedStrategy(e.target.value)}>
                            {strategies.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                        </select>
                    </div>

                    <button
                        onClick={handleRunBacktest}
                        disabled={isLoading}
                        className="w-full mt-2 bg-indigo-600 hover:bg-indigo-500 text-white font-bold py-3 rounded-xl transition-all shadow-lg flex justify-center items-center gap-2"
                    >
                        {isLoading ? <span className="animate-spin">⏳</span> : <Play size={18} fill="currentColor" />}
                        Simülasyonu Başlat
                    </button>
                </div>

                {/* VISUAL / INFO AREA */}
                <div className="flex flex-col items-center justify-center p-6 bg-slate-900/50 rounded-2xl border border-slate-800 text-center relative overflow-hidden">
                    {!result && !isLoading && (
                        <>
                            <div className="w-20 h-20 bg-slate-800 rounded-full flex items-center justify-center mb-4">
                                <BarChart3 className="text-slate-600" size={32} />
                            </div>
                            <h4 className="text-slate-300 font-bold mb-2">Backtest Nedir?</h4>
                            <p className="text-slate-500 text-sm">
                                Seçtiğiniz stratejiyi geçmiş piyasa verileri üzerinde test ederek, stratejinin başarısını risk almadan ölçebilirsiniz.
                            </p>
                        </>
                    )}

                    {isLoading && (
                        <div className="flex flex-col items-center animate-pulse">
                            <div className="w-16 h-16 border-4 border-indigo-500/30 border-t-indigo-500 rounded-full animate-spin mb-4"></div>
                            <p className="text-indigo-400 font-bold">Veriler Analiz Ediliyor...</p>
                            <p className="text-slate-500 text-xs mt-2">Binance geçmiş verileri taranıyor...</p>
                        </div>
                    )}

                    {/* RESULT SUMMARY */}
                    {result && !isLoading && (
                        <div className="w-full h-full flex flex-col justify-between animate-in fade-in zoom-in duration-300">
                            <div className="text-center mb-4">
                                <span className="text-slate-400 text-xs uppercase tracking-wider font-bold">Toplam Sonuç</span>
                                <div className={`text-4xl font-bold font-mono my-1 ${result.totalPnl >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                                    {result.totalPnl >= 0 ? '+' : ''}${result.totalPnl.toFixed(2)}
                                </div>
                                <span className={`text-sm font-bold px-2 py-0.5 rounded ${result.totalPnl >= 0 ? 'bg-green-500/20 text-green-400' : 'bg-red-500/20 text-red-400'}`}>
                                    %{result.totalPnlPercent.toFixed(2)}
                                </span>
                            </div>

                            <div className="grid grid-cols-2 gap-3 w-full">
                                <div className="bg-slate-800 p-3 rounded-lg text-center">
                                    <span className="block text-slate-500 text-[10px] uppercase">Kazanma Oranı</span>
                                    <span className="text-white font-bold text-lg">%{result.winRate.toFixed(1)}</span>
                                </div>
                                <div className="bg-slate-800 p-3 rounded-lg text-center">
                                    <span className="block text-slate-500 text-[10px] uppercase">İşlem Sayısı</span>
                                    <span className="text-white font-bold text-lg">{result.totalTrades}</span>
                                </div>
                                <div className="bg-green-500/10 p-3 rounded-lg text-center border border-green-500/20">
                                    <span className="block text-green-500/70 text-[10px] uppercase">Başarılı</span>
                                    <span className="text-green-400 font-bold text-lg">{result.winningTrades}</span>
                                </div>
                                <div className="bg-red-500/10 p-3 rounded-lg text-center border border-red-500/20">
                                    <span className="block text-red-500/70 text-[10px] uppercase">Başarısız</span>
                                    <span className="text-red-400 font-bold text-lg">{result.losingTrades}</span>
                                </div>
                            </div>
                        </div>
                    )}
                </div>

            </div>

            {/* TRADE LIST */}
            {result && result.trades.length > 0 && (
                <div className="bg-slate-800/40 border border-slate-700/50 rounded-3xl overflow-hidden">
                    <div className="p-4 border-b border-slate-700/50 bg-slate-800/50">
                        <h4 className="text-white font-bold text-sm">İşlem Detayları</h4>
                    </div>
                    <div className="max-h-80 overflow-y-auto">
                        <table className="w-full text-left text-sm text-slate-400">
                            <thead className="text-xs uppercase bg-slate-900/50 text-slate-500 sticky top-0">
                                <tr>
                                    <th className="px-4 py-3">Tip</th>
                                    <th className="px-4 py-3">Giriş Fiyatı</th>
                                    <th className="px-4 py-3">Çıkış Fiyatı</th>
                                    <th className="px-4 py-3 text-right">PNL</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-700/50">
                                {result.trades.map((trade, i) => (
                                    <tr key={i} className="hover:bg-slate-700/30 transition-colors">
                                        <td className="px-4 py-3 flex items-center gap-2">
                                            {trade.pnl >= 0 ? <TrendingUp size={14} className="text-green-500" /> : <TrendingDown size={14} className="text-red-500" />}
                                            <span className={trade.pnl >= 0 ? "text-green-400" : "text-red-400"}>{trade.type}</span>
                                        </td>
                                        <td className="px-4 py-3 font-mono">
                                            ${trade.entryPrice < 1 ? trade.entryPrice.toFixed(8) : trade.entryPrice.toFixed(2)}
                                        </td>
                                        <td className="px-4 py-3 font-mono">
                                            ${trade.exitPrice < 1 ? trade.exitPrice.toFixed(8) : trade.exitPrice.toFixed(2)}
                                        </td>
                                        <td className={`px-4 py-3 font-mono font-bold text-right ${trade.pnl >= 0 ? "text-green-400" : "text-red-400"}`}>
                                            {trade.pnl >= 0 ? "+" : ""}{trade.pnl.toFixed(2)}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>
            )}
        </div>
    );
}
