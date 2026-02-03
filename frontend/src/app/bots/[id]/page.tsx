"use client";

import { useEffect, useState, use } from "react";
import { useRouter } from "next/navigation";
import { BotService } from "@/lib/api";
import { Bot, Log } from "@/types";
import { ArrowLeft, Activity, StopCircle, PlayCircle, Trash2, Clock, TrendingUp, DollarSign, BarChart2 } from "lucide-react";
import { motion } from "framer-motion";
import Navbar from "@/components/ui/Navbar";
import { toast } from "sonner";
import { StatCardSkeleton, TableSkeleton } from "@/components/ui/Skeletons";
import {
    AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer
} from 'recharts';

// Helper for status colors
const getStatusColor = (status: string) => {
    switch (status) {
        case 'Running': return 'text-emerald-400 bg-emerald-500/10 border-emerald-500/20';
        case 'Stopped': return 'text-rose-400 bg-rose-500/10 border-rose-500/20';
        case 'WaitingForEntry': return 'text-amber-400 bg-amber-500/10 border-amber-500/20';
        default: return 'text-slate-400 bg-slate-500/10 border-slate-500/20';
    }
};

const getStatusLabel = (status: string) => {
    switch (status) {
        case 'Running': return 'AKTİF';
        case 'Stopped': return 'DURDURULDU';
        case 'WaitingForEntry': return 'PUSUDA';
        default: return status;
    }
};

export default function BotDetailPage({ params }: { params: Promise<{ id: string }> }) {
    const { id } = use(params);
    const router = useRouter();
    const [bot, setBot] = useState<Bot | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [activeTab, setActiveTab] = useState<'trades' | 'logs'>('trades');

    const fetchBot = async () => {
        try {
            const data = await BotService.getById(id);
            setBot(data);
        } catch (error) {
            toast.error("Bot bilgileri alınamadı.");
            router.push('/');
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchBot();
    }, [id]);

    const handleStopBot = async () => {
        if (!confirm("Bu botu durdurmak istediğinize emin misiniz?")) return;
        try {
            await BotService.stop(id);
            toast.success("Bot durduruldu.");
            fetchBot();
        } catch (error) {
            toast.error("İşlem başarısız.");
        }
    };

    // Calculate PnL Chart Data (Cumulative)
    const getChartData = () => {
        if (!bot || !bot.trades) return [];
        let runningPnl = 0;
        // Sort trades ascending for chart
        const sortedTrades = [...bot.trades].sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());
        return sortedTrades
            .filter(t => t.type === 1) // Only sells/closes have realized PnL usually, or calculate based on flow
            // Note: backend trade model might need check. Assuming 'total' includes PnL logic or simple exit - entry.
            // For now, let's just map each trade's realized PnL if available.
            // If Trade model doesn't have explicit PnL, we might need to derive it.
            // Let's assume Trade model has Quantity & Price.
            // Simplification: Just show a mocked curve or real one if 'Trade' has pnl.
            // Checking backend Trade entity... It has Total.
            // Let's use 0 for now if complex.
            .map(t => ({
                date: new Date(t.timestamp).toLocaleTimeString(),
                pnl: t.total // Placeholder
            }));
    };

    if (isLoading) {
        return (
            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-20">
                <Navbar user={null} />

                {/* Header Skeleton */}
                <div className="mb-8 flex justify-between items-center animate-pulse">
                    <div className="flex items-center gap-4">
                        <div className="w-10 h-10 bg-slate-800/50 rounded-xl"></div>
                        <div className="space-y-2">
                            <div className="w-32 h-8 bg-slate-800/50 rounded-lg"></div>
                            <div className="w-48 h-4 bg-slate-800/20 rounded-lg"></div>
                        </div>
                    </div>
                </div>

                {/* KPIs Skeleton */}
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
                    <StatCardSkeleton />
                    <StatCardSkeleton />
                    <StatCardSkeleton />
                    <StatCardSkeleton />
                </div>

                {/* Table Skeleton */}
                <div className="glass-card p-6 border border-white/5">
                    <TableSkeleton rows={8} />
                </div>
            </main>
        );
    }

    if (!bot) return null;

    return (
        <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-20">
            <Navbar user={null} />

            {/* BACK BUTTON & HEADER */}
            <div className="mb-8 flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div className="flex items-center gap-4">
                    <button
                        onClick={() => router.push('/')}
                        className="p-2 rounded-xl bg-slate-900 border border-white/5 text-slate-400 hover:text-white hover:bg-white/5 transition-colors"
                    >
                        <ArrowLeft size={20} />
                    </button>
                    <div>
                        <div className="flex items-center gap-3">
                            <h1 className="text-3xl font-display font-bold text-white">{bot.symbol}</h1>
                            <span className={`px-3 py-1 rounded-lg text-xs font-bold border ${getStatusColor(bot.status)}`}>
                                {getStatusLabel(bot.status)}
                            </span>
                        </div>
                        <div className="flex items-center gap-2 text-slate-400 text-sm mt-1">
                            <Activity size={14} />
                            <span>{bot.strategyName}</span>
                            <span className="w-1 h-1 bg-slate-700 rounded-full"></span>
                            <Clock size={14} />
                            <span>{bot.interval}</span>
                        </div>
                    </div>
                </div>

                <div className="flex gap-3">
                    {bot.status !== 'Stopped' && (
                        <button
                            onClick={handleStopBot}
                            className="px-4 py-2 bg-rose-500/10 text-rose-400 border border-rose-500/20 hover:bg-rose-500/20 rounded-xl font-bold flex items-center gap-2 transition-all"
                        >
                            <StopCircle size={18} />
                            Botu Durdur
                        </button>
                    )}
                </div>
            </div>

            {/* KPIS */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
                <div className="glass-card p-6 border border-white/5 transition-all hover:bg-white/2">
                    <p className="text-slate-500 text-[10px] font-bold uppercase tracking-widest mb-1">Toplam Yatırım</p>
                    <h3 className="text-2xl font-display font-bold text-white">${bot.amount.toLocaleString()}</h3>
                </div>
                <div className="glass-card p-6 border border-white/5 transition-all hover:bg-white/2">
                    <p className="text-slate-500 text-[10px] font-bold uppercase tracking-widest mb-1">Anlık PnL</p>
                    <h3 className={`text-2xl font-mono font-bold ${bot.pnlPercent >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
                        {bot.pnlPercent >= 0 ? '+' : ''}%{bot.pnlPercent.toFixed(2)}
                    </h3>
                    <p className="text-xs text-slate-500 mt-1">${bot.currentPnl.toFixed(2)}</p>
                </div>
                <div className="glass-card p-6 border border-white/5 transition-all hover:bg-white/2">
                    <p className="text-slate-500 text-[10px] font-bold uppercase tracking-widest mb-1">Max Fiyat</p>
                    <h3 className="text-2xl font-mono font-bold text-white">${bot.maxPriceReached?.toFixed(4) || '-'}</h3>
                </div>
                <div className="glass-card p-6 border border-white/5 transition-all hover:bg-white/2">
                    <p className="text-slate-500 text-[10px] font-bold uppercase tracking-widest mb-1">İz Süren Stop</p>
                    <div className="flex items-center gap-2">
                        <span className={`w-2 h-2 rounded-full ${bot.isTrailingStop ? 'bg-emerald-500' : 'bg-slate-700'}`}></span>
                        <h3 className="text-lg font-bold text-white">{bot.isTrailingStop ? 'Aktif' : 'Pasif'}</h3>
                    </div>
                    {bot.isTrailingStop && <p className="text-xs text-slate-500 mt-1">Mesafe: %{bot.trailingStopDistance}</p>}
                </div>
            </div>

            {/* TABS & CONTENT */}
            <div className="glass-card overflow-hidden min-h-[500px]">
                <div className="flex border-b border-white/5 bg-slate-900/50 px-4 md:px-6">
                    <button
                        onClick={() => setActiveTab('trades')}
                        className={`px-4 py-4 text-sm font-bold border-b-2 transition-colors flex items-center gap-2 ${activeTab === 'trades' ? 'border-primary text-white' : 'border-transparent text-slate-500 hover:text-slate-300'}`}
                    >
                        <TrendingUp size={16} />
                        İşlem Geçmişi
                    </button>
                    <button
                        onClick={() => setActiveTab('logs')}
                        className={`px-4 py-4 text-sm font-bold border-b-2 transition-colors flex items-center gap-2 ${activeTab === 'logs' ? 'border-primary text-white' : 'border-transparent text-slate-500 hover:text-slate-300'}`}
                    >
                        <Activity size={16} />
                        Log Kayıtları
                    </button>
                </div>

                <div className="p-0">
                    {activeTab === 'trades' && (
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="border-b border-white/5 bg-white/2">
                                        <th className="p-4 text-xs font-bold text-slate-500 uppercase tracking-wider">Tarih</th>
                                        <th className="p-4 text-xs font-bold text-slate-500 uppercase tracking-wider">İşlem</th>
                                        <th className="p-4 text-xs font-bold text-slate-500 uppercase tracking-wider">Fiyat</th>
                                        <th className="p-4 text-xs font-bold text-slate-500 uppercase tracking-wider">Miktar</th>
                                        <th className="p-4 text-xs font-bold text-slate-500 uppercase tracking-wider">Tutar</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-white/5">
                                    {(bot.trades && bot.trades.length > 0) ? bot.trades.map((trade, i) => (
                                        <tr key={i} className="hover:bg-white/2 transition-colors">
                                            <td className="p-4 text-sm text-slate-300 font-mono">{new Date(trade.timestamp).toLocaleString()}</td>
                                            <td className="p-4">
                                                <span className={`px-2 py-1 rounded text-[10px] font-bold uppercase ${trade.type === 0 ? 'bg-emerald-500/10 text-emerald-400' : 'bg-rose-500/10 text-rose-400'}`}>
                                                    {trade.type === 0 ? 'ALIŞ' : 'SATIŞ'}
                                                </span>
                                            </td>
                                            <td className="p-4 text-sm text-white font-mono">${trade.price}</td>
                                            <td className="p-4 text-sm text-slate-300 font-mono">{trade.quantity}</td>
                                            <td className="p-4 text-sm text-white font-bold font-mono">${trade.total.toFixed(2)}</td>
                                        </tr>
                                    )) : (
                                        <tr>
                                            <td colSpan={5} className="p-12 text-center text-slate-500 text-sm">Henüz işlem bulunmuyor.</td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    )}

                    {activeTab === 'logs' && (
                        <div className="max-h-[600px] overflow-y-auto p-4 space-y-2 font-mono text-sm">
                            {(bot.logs && bot.logs.length > 0) ? bot.logs.map((log: Log) => (
                                <div key={log.id} className="flex gap-3 text-xs p-2 hover:bg-white/5 rounded-lg transition-colors">
                                    <span className="text-slate-500 shrink-0 select-none">
                                        {new Date(log.timestamp).toLocaleTimeString()}
                                    </span>
                                    {(() => {
                                        const l = String(log.level);
                                        let lbl = 'INFO';
                                        let col = 'text-emerald-500';
                                        if (l === '2' || l === 'Error' || l === 'ERROR') { lbl = 'ERROR'; col = 'text-rose-500'; }
                                        else if (l === '1' || l === 'Warning' || l === 'WARNING') { lbl = 'WARNING'; col = 'text-amber-500'; }
                                        return <span className={`font-bold shrink-0 ${col}`}>[{lbl}]</span>;
                                    })()}
                                    <span className="text-slate-300 break-all">{log.message}</span>
                                </div>
                            )) : (
                                <p className="text-slate-500 text-center py-8">Log kaydı bulunamadı.</p>
                            )}
                        </div>
                    )}
                </div>
            </div>
        </main>
    );
}
