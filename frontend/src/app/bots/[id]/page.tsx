"use client";

export const dynamic = "force-dynamic";

import { useEffect, useState, use, useRef } from "react";
import { useRouter } from "next/navigation";
import { BotService } from "@/lib/api";
import { Bot, Log } from "@/types";
import { ArrowLeft, Activity, StopCircle, PlayCircle, Trash2, Clock, TrendingUp, DollarSign, BarChart2, Info, HelpCircle } from "lucide-react";
import { motion } from "framer-motion";
import Navbar from "@/components/ui/Navbar";
import { InfoTooltip } from "@/components/dashboard/InfoTooltip";
import { toast } from "sonner";
import { useSignalR } from "@/context/SignalRContext";
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
    const { connection } = useSignalR();
    const [bot, setBot] = useState<Bot | null>(null);
    const [user, setUser] = useState<any>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [activeTab, setActiveTab] = useState<'trades' | 'logs'>('logs');
    const logScrollRef = useRef<HTMLDivElement>(null);

    // Yeni log geldiğinde en üste kaydır (Çünkü en yeni en üstte)
    useEffect(() => {
        if (activeTab === 'logs' && logScrollRef.current) {
            logScrollRef.current.scrollTop = 0;
        }
    }, [bot?.logs, activeTab]);

    useEffect(() => {
        const storedUser = localStorage.getItem("user");
        if (storedUser) setUser(JSON.parse(storedUser));
    }, []);

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

        if (connection) {
            connection.on("ReceiveBotUpdate", (updatedBot: any) => {
                if (updatedBot.id === id) {
                    setBot(prev => prev ? { ...prev, ...updatedBot } : updatedBot);
                }
            });

            connection.on("ReceiveLog", (botId: string, log: any) => {
                if (botId === id) {
                    setBot(prev => {
                        if (!prev) return prev;
                        const logs = prev.logs || [];
                        if (logs.find(l => l.id === log.id)) return prev;
                        const newLogs = [...logs, log];
                        return {
                            ...prev,
                            logs: newLogs.slice(-100)
                        };
                    });
                }
            });
        }

        return () => {
            if (connection) {
                connection.off("ReceiveBotUpdate");
                connection.off("ReceiveLog");
            }
        };
    }, [id, connection]);

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
            <Navbar user={user} />

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
                        <div className="flex items-center gap-3 mt-2">
                            <div className="flex items-center gap-1.5 px-3 py-1 rounded-lg bg-primary/10 text-primary border border-primary/20 text-xs font-bold uppercase tracking-wider">
                                <Activity size={14} />
                                <span>{bot.strategyName}</span>
                            </div>
                            <div className="flex items-center gap-1.5 px-3 py-1 rounded-lg bg-slate-800 text-slate-400 border border-white/5 text-xs font-bold uppercase tracking-wider">
                                <Clock size={14} />
                                <span>{bot.interval}</span>
                            </div>
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
                <div className="glass-card p-6 border border-white/5 transition-all hover:bg-white/2 group">
                    <div className="flex items-center justify-between mb-1">
                        <p className="text-slate-500 text-[10px] font-bold uppercase tracking-widest">Toplam Yatırım</p>
                        <InfoTooltip text="Bota ayrılan toplam sermaye tutarı" />
                    </div>
                    <h3 className="text-2xl font-display font-bold text-white">${bot.amount.toLocaleString()}</h3>
                </div>
                <div className="glass-card p-6 border border-white/5 transition-all hover:bg-white/2 group">
                    <div className="flex items-center justify-between mb-1">
                        <p className="text-slate-500 text-[10px] font-bold uppercase tracking-widest">Anlık PnL</p>
                        <InfoTooltip text="Açık pozisyonun güncel kar/zarar durumu" />
                    </div>
                    <h3 className={`text-2xl font-mono font-bold ${bot.pnlPercent >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
                        {bot.pnlPercent >= 0 ? '+' : ''}%{bot.pnlPercent.toFixed(2)}
                    </h3>
                    <p className="text-xs text-slate-500 mt-1">${(bot.pnl || bot.currentPnl || 0).toFixed(2)}</p>
                </div>
                <div className="glass-card p-6 border border-white/5 transition-all hover:bg-white/2 group">
                    <div className="flex items-center justify-between mb-1">
                        <p className="text-slate-500 text-[10px] font-bold uppercase tracking-widest">Tepe Fiyat (Max)</p>
                        <InfoTooltip text="İşleme girişten beri görülen en yüksek fiyat (İz süren stop için baz alınır)" />
                    </div>
                    <h3 className="text-2xl font-mono font-bold text-white">${bot.maxPriceReached?.toFixed(4) || '-'}</h3>
                </div>
                <div className="glass-card p-6 border border-white/5 transition-all hover:bg-white/2 group">
                    <div className="flex items-center justify-between mb-1">
                        <p className="text-slate-500 text-[10px] font-bold uppercase tracking-widest">İz Süren Stop</p>
                        <InfoTooltip text="Fiyat yükseldikçe stop seviyesini yukarı taşıyan mekanizma" />
                    </div>
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
                                    {(bot.trades && bot.trades.length > 0) ? [...bot.trades].reverse().map((trade, i) => (
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
                        <div
                            ref={logScrollRef}
                            className="max-h-[600px] overflow-y-auto p-4 space-y-2 font-mono text-sm scrollbar-thin scrollbar-thumb-slate-700 scrollbar-track-transparent"
                        >
                            {(bot.logs && bot.logs.length > 0) ? [...bot.logs].sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()).map((log: Log) => (
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
