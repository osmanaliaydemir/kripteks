"use client";

import { useEffect, useState, useRef } from "react";
import { Bot, Strategy, Coin, Wallet, User, DashboardStats } from "@/types";
import { BotService, MarketService, WalletService, HUB_URL } from "@/lib/api";
import { motion, AnimatePresence } from "framer-motion";
import { Activity, TrendingUp, BarChart2, DollarSign, Wallet as WalletIcon, ChevronDown, Loader2, FlaskConical, History, Database, Settings, LogOut, User as UserIcon, Key, Zap, Cpu, Square, AlertTriangle, Info, Clock, X, Bot as BotIcon } from "lucide-react";
import SearchableSelect from "@/components/ui/SearchableSelect";
import TradingViewWidget from "@/components/ui/TradingViewWidget";
import BotLogs from "@/components/ui/BotLogs";
import WalletModal from "@/components/ui/WalletModal";
import confetti from "canvas-confetti";
import { toast } from "sonner";
import Link from "next/link";
import Navbar from "@/components/ui/Navbar";
import { useUI } from "@/context/UIContext";
import { useSignalR } from "@/context/SignalRContext";
import BotWizardModal from "@/components/wizard/BotWizardModal";


interface StatCardProps {
    title: string;
    value: string | number;
    icon: React.ReactNode;
    trend?: string;
    trendUp?: boolean;
    delay: number;
    highlight?: boolean;
    onClick?: () => void;
}

function StatCard({ title, value, icon, trend, trendUp, delay, highlight, onClick }: StatCardProps) {
    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay, duration: 0.5 }}
            onClick={onClick}
            className={`glass-card p-5 relative overflow-hidden group ${onClick ? 'cursor-pointer' : ''} ${highlight ? 'border-primary/20 bg-primary/5' : ''}`}
        >
            <div className="flex justify-between items-start mb-4 relative z-10">
                <div>
                    <p className="text-slate-400 text-xs font-bold uppercase tracking-widest mb-1">{title}</p>
                    <h3 className="text-2xl font-display font-bold text-white tracking-wide">{value}</h3>
                </div>
                <div className={`p-3 rounded-xl ${highlight ? 'bg-primary/20' : 'bg-slate-800/50'} border border-white/5`}>
                    {icon}
                </div>
            </div>
            {trend && (
                <div className={`flex items-center gap-2 text-xs font-medium ${trendUp ? 'text-emerald-400' : 'text-slate-500'}`}>
                    {trendUp && <TrendingUp size={14} />}
                    {trend}
                </div>
            )}
            <div className={`absolute -bottom-4 -right-4 w-24 h-24 rounded-full blur-2xl opacity-20 pointer-events-none group-hover:opacity-30 transition-opacity ${highlight ? 'bg-primary' : 'bg-white'}`}></div>
        </motion.div>
    );
}

interface TabButtonProps {
    id: 'active' | 'history';
    label: string;
    count?: number;
    activeTab: string;
    setActiveTab: (id: 'active' | 'history') => void;
    icon: React.ReactNode;
}

function TabButton({ id, label, count, activeTab, setActiveTab, icon }: TabButtonProps) {
    return (
        <button
            onClick={() => setActiveTab(id)}
            className={`px-4 py-2.5 rounded-lg text-xs font-bold transition-all flex items-center gap-2.5 ${activeTab === id
                ? 'bg-slate-800 text-white shadow-lg ring-1 ring-white/10'
                : 'text-slate-400 hover:text-white hover:bg-slate-800/50'
                }`}
        >
            {icon}
            {label}
            {count !== undefined && <span className={`px-1.5 py-0.5 rounded text-[10px] bg-slate-700 text-slate-300 ml-1`}>{count}</span>}
        </button>
    );
}

interface EmptyStateProps {
    title: string;
    description: string;
    icon: React.ReactNode;
}

function EmptyState({ title, description, icon }: EmptyStateProps) {
    return (
        <div className="flex flex-col items-center justify-center py-20 bg-slate-900/40 border border-dashed border-slate-800 rounded-3xl">
            <div className="w-16 h-16 bg-slate-800/50 rounded-full flex items-center justify-center mb-4 text-slate-600">
                {icon}
            </div>
            <h3 className="text-white font-display font-bold text-lg mb-2">{title}</h3>
            <p className="text-slate-500 text-sm max-w-xs text-center">{description}</p>
        </div>
    );
}

interface BotCardProps {
    bot: Bot;
    isActive: boolean;
    activeChartBotId: string | null;
    setActiveChartBotId: (id: string | null) => void;
    handleStopBot: (id: string) => void;
    onStrategyClick: (id: string) => void;
}

function BotCard({ bot, isActive, activeChartBotId, setActiveChartBotId, handleStopBot, onStrategyClick }: BotCardProps) {
    const [isLogsOpen, setIsLogsOpen] = useState(false);

    return (
        <motion.div
            layout
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95 }}
            className={`glass-card overflow-hidden group ${isActive
                ? 'bg-slate-800/40 border-l-4 border-l-emerald-500'
                : 'bg-slate-900/30 opacity-70 hover:opacity-100 border-l-4 border-l-slate-700'
                }`}
        >
            <div className="p-5 flex flex-col sm:flex-row items-center gap-6">

                {/* Symbol Icon */}
                <div className="relative">
                    <div className={`w-14 h-14 rounded-2xl flex items-center justify-center text-xl font-bold shadow-lg ${isActive
                        ? 'bg-linear-to-br from-slate-800 to-slate-900 text-white border border-white/5'
                        : 'bg-slate-800 text-slate-600'
                        }`}>
                        {bot.symbol.substring(0, 1)}
                    </div>
                    {isActive && <div className="absolute -bottom-1 -right-1 w-4 h-4 bg-emerald-500 border-2 border-slate-900 rounded-full animate-pulse"></div>}
                </div>

                {/* Info */}
                <div className="flex-1 w-full text-center sm:text-left">
                    <div className="flex flex-col sm:flex-row sm:items-center gap-2 mb-1">
                        <h3 className="text-white font-display font-bold text-xl tracking-wide">{bot.symbol}</h3>
                        <div className="flex items-center justify-center sm:justify-start gap-2">
                            {/* Status Badge */}
                            {bot.status === 'WaitingForEntry' && (
                                <span className="flex items-center gap-1.5 px-2 py-0.5 rounded text-[10px] font-bold bg-amber-500/10 text-amber-500 border border-amber-500/20 uppercase tracking-wider animate-pulse">
                                    <div className="w-1.5 h-1.5 rounded-full bg-amber-500"></div>
                                    Sinyal Bekleniyor
                                </span>
                            )}
                            {bot.status === 'Running' && (
                                <span className="flex items-center gap-1.5 px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/10 text-emerald-500 border border-emerald-500/20 uppercase tracking-wider">
                                    <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></div>
                                    Pozisyonda
                                </span>
                            )}
                            {bot.status === 'Stopped' && (
                                <span className="flex items-center gap-1.5 px-2 py-0.5 rounded text-[10px] font-bold bg-rose-500/10 text-rose-500 border border-rose-500/20 uppercase tracking-wider">
                                    <div className="w-1.5 h-1.5 rounded-full bg-rose-500"></div>
                                    Durduruldu
                                </span>
                            )}

                            <button onClick={() => onStrategyClick(bot.strategyId || bot.strategyName)} className="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-800 text-slate-400 border border-white/5 uppercase hidden sm:block hover:bg-slate-700 hover:text-white transition-colors">
                                {bot.strategyName}
                            </button>
                        </div>
                    </div>

                    {/* Dynamic Status Text */}
                    <div className="flex flex-col sm:flex-row items-center justify-center sm:justify-start gap-3 text-xs text-slate-500 font-mono mt-1 w-full">
                        <div className="flex items-center gap-3 shrink-0">
                            <span className="flex items-center gap-1"><DollarSign size={12} /> {bot.amount} Teminat</span>
                        </div>
                    </div>
                </div>

                {/* PNL Display */}
                <div className="flex flex-col items-center sm:items-end min-w-[100px]">
                    <span className={`text-2xl font-bold font-mono tracking-tight ${bot.pnl >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
                        {bot.pnl >= 0 ? '+' : ''}{bot.pnl?.toFixed(2)}$
                    </span>
                    <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${bot.pnl >= 0 ? 'bg-emerald-500/10 text-emerald-500' : 'bg-rose-500/10 text-rose-500'}`}>
                        %{bot.pnlPercent?.toFixed(2)} ROI
                    </span>
                </div>

                {/* Actions */}
                <div className="flex gap-2 w-full sm:w-auto mt-2 sm:mt-0 shrink-0">
                    <button
                        onClick={() => setActiveChartBotId(activeChartBotId === bot.id ? null : bot.id)}
                        className={`flex-1 sm:flex-none p-3 rounded-xl border transition-all ${activeChartBotId === bot.id ? 'bg-secondary text-white border-secondary shadow-lg shadow-secondary/20' : 'bg-slate-800 text-slate-400 border-white/5 hover:bg-secondary/10 hover:text-secondary hover:border-secondary/50'}`}
                    >
                        <Activity size={18} />
                    </button>

                    {isActive && (
                        <button
                            onClick={() => handleStopBot(bot.id)}
                            className="flex-1 sm:flex-none p-3 rounded-xl bg-rose-500/10 text-rose-400 border border-rose-500/20 hover:bg-rose-500 hover:text-white transition-all active:scale-95"
                            title="Acil Durdur"
                        >
                            <Square size={18} className="fill-current" />
                        </button>
                    )}
                </div>
            </div>

            {/* EXPANDED CONTENT */}
            {/* EXPANDED CONTENT */}
            <div className="border-t border-white/5 bg-black/20">
                <AnimatePresence>
                    {activeChartBotId === bot.id && (
                        <motion.div
                            initial={{ height: 0, opacity: 0 }}
                            animate={{ height: "auto", opacity: 1 }}
                            exit={{ height: 0, opacity: 0 }}
                            className="overflow-hidden"
                        >
                            <div className="p-4">
                                <TradingViewWidget symbol={bot.symbol} strategy={bot.strategyName} />
                            </div>
                        </motion.div>
                    )}
                </AnimatePresence>

                {/* Logs Accordion */}
                <div className={activeChartBotId === bot.id ? "border-t border-white/5" : ""}>
                    <button
                        onClick={() => setIsLogsOpen(!isLogsOpen)}
                        className="w-full flex items-center justify-between px-4 py-3 text-xs font-bold text-slate-400 hover:text-white hover:bg-white/5 transition-colors group/logs"
                    >
                        <span className="flex items-center gap-2 font-mono tracking-wider">
                            <span className="text-secondary">{'>_'}</span>
                            İŞLEM KAYITLARI
                        </span>
                        <ChevronDown size={14} className={`transition-transform duration-300 text-slate-500 group-hover/logs:text-white ${isLogsOpen ? 'rotate-180' : ''}`} />
                    </button>

                    <AnimatePresence>
                        {isLogsOpen && (
                            <motion.div
                                initial={{ height: 0, opacity: 0 }}
                                animate={{ height: "auto", opacity: 1 }}
                                exit={{ height: 0, opacity: 0 }}
                                className="overflow-hidden"
                            >
                                <div className="p-4 pt-0">
                                    <BotLogs logs={bot.logs || []} compact={!isActive} />
                                </div>
                            </motion.div>
                        )}
                    </AnimatePresence>
                </div>
            </div>
        </motion.div>
    );
}

function InfoTooltip({ text }: { text: string }) {
    const [isVisible, setIsVisible] = useState(false);
    return (
        <div className="relative inline-block ml-1" onMouseEnter={() => setIsVisible(true)} onMouseLeave={() => setIsVisible(false)}>
            <div className="p-0.5 rounded-full hover:bg-white/10 transition-colors cursor-help text-slate-500 hover:text-slate-300">
                <Info size={12} />
            </div>
            <AnimatePresence>
                {isVisible && (
                    <motion.div
                        initial={{ opacity: 0, scale: 0.9, y: 5 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.9, y: 5 }}
                        className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-56 p-3 bg-slate-900/95 backdrop-blur-md border border-white/10 rounded-xl shadow-2xl z-50 pointer-events-none"
                    >
                        <p className="text-[10px] leading-relaxed text-slate-300 font-semibold">{text}</p>
                        <div className="absolute top-full left-1/2 -translate-x-1/2 border-[6px] border-transparent border-t-slate-900/95"></div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
}
const STRATEGY_DETAILS: Record<string, { title: string; description: string; timeline: { title: string; desc: string; icon: any; color: string }[] }> = {
    "strategy-golden-rose": {
        title: "Golden Rose Trend Strategy",
        description: "SMA 111-200-350 trend takibi ve Fibonacci 1.618 kar al hedefli özel strateji. Bitcoin halving döngüleri için optimize edilmiştir.",
        timeline: [
            { title: "Trend Analizi", desc: "SMA 111, SMA 200 ve SMA 350 indikatörleri taranarak uzun vadeli trend yönü ve gücü belirlenir.", icon: Activity, color: "text-slate-400 border-slate-500/20 bg-slate-500/10" },
            { title: "Giriş Sinyali", desc: "Fiyat, belirlenen hareketli ortalamaların (SMA) üzerine çıktığında ve trend onayı alındığında ALIM emri girilir.", icon: TrendingUp, color: "text-emerald-400 border-emerald-500/20 bg-emerald-500/10" },
            { title: "Döngü Tepesi", desc: "Bitcoin halving döngülerine göre hesaplanan tepe noktaları (x2) hedef alınır.", icon: BarChart2, color: "text-blue-400 border-blue-500/20 bg-blue-500/10" },
            { title: "Altın Oran Çıkış", desc: "Fibonacci 1.618 seviyesine ulaşıldığında 'Altın Oran Kar' realizasyonu yapılır ve pozisyon kapatılır.", icon: DollarSign, color: "text-amber-400 border-amber-500/20 bg-amber-500/10" }
        ]
    },
    "strategy-market-buy": {
        title: "Market Maker (Hızlı Al-Sat)",
        description: "Anlık fiyat hareketlerinden yararlanarak kısa vadeli (scalping) işlemler açar.",
        timeline: [
            { title: "Fırsat Yakalama", desc: "Ani fiyat düşüşlerinde (Dip Noktalar) tepki alımları hedeflenir.", icon: Activity, color: "text-slate-400 border-slate-500/20 bg-slate-500/10" },
            { title: "Hızlı Giriş", desc: "Destek noktasına temas edildiğinde milisaniyeler içinde ALIM yapılır.", icon: TrendingUp, color: "text-emerald-400 border-emerald-500/20 bg-emerald-500/10" },
            { title: "Kısa Bekleme", desc: "Pozisyon süresi minimumda tutulur, küçük karlar hedeflenir.", icon: Clock, color: "text-blue-400 border-blue-500/20 bg-blue-500/10" },
            { title: "Çıkış", desc: "%1-%2 gibi hedeflerde anında kar satışı gerçekleştirilir.", icon: DollarSign, color: "text-amber-400 border-amber-500/20 bg-amber-500/10" }
        ]
    },
    "strategy-sma-crossover": {
        title: "SMA Kesişimi (Trend)",
        description: "İki farklı hareketli ortalamanın (Örn: SMA 9 ve SMA 21) kesişimlerini takip eden klasik trend stratejisi.",
        timeline: [
            { title: "Veri Analizi", desc: "Kısa ve uzun vadeli ortalamalar sürekli hesaplanır.", icon: Activity, color: "text-slate-400 border-slate-500/20 bg-slate-500/10" },
            { title: "Golden Cross", desc: "Kısa vadeli ortalama, uzun vadeli ortalamayı yukarı kestiğinde ALIM sinyali üretilir.", icon: TrendingUp, color: "text-emerald-400 border-emerald-500/20 bg-emerald-500/10" },
            { title: "Trend Sürüşü", desc: "Kesişim devam ettiği sürece pozisyon korunur.", icon: Activity, color: "text-blue-400 border-blue-500/20 bg-blue-500/10" },
            { title: "Death Cross", desc: "Kısa vade, uzun vadeyi aşağı kestiğinde SATIŞ sinyali ile çıkılır.", icon: LogOut, color: "text-rose-400 border-rose-500/20 bg-rose-500/10" }
        ]
    }
};

function StrategyModal({ isOpen, onClose, strategyId }: { isOpen: boolean; onClose: () => void; strategyId: string | null }) {
    if (!isOpen || !strategyId) return null;

    const details = STRATEGY_DETAILS[strategyId] || {
        title: strategyId,
        description: "Bu strateji için detaylı bilgi bulunamadı.",
        timeline: []
    };

    return (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={onClose}></div>
            <motion.div
                initial={{ opacity: 0, scale: 0.95, y: 20 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.95, y: 20 }}
                className="relative bg-slate-900 border border-white/10 rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl"
            >
                {/* Header */}
                <div className="p-6 pb-4 border-b border-white/5 flex items-start justify-between bg-slate-800/30">
                    <div>
                        <div className="flex items-center gap-2 mb-2">
                            <span className="p-1.5 rounded-lg bg-primary/10 text-primary"><Activity size={18} /></span>
                            <h2 className="text-lg font-bold text-white">{details.title}</h2>
                        </div>
                        <p className="text-xs text-slate-400 leading-relaxed max-w-sm">{details.description}</p>
                    </div>
                    <button onClick={onClose} className="p-2 -mr-2 -mt-2 text-slate-500 hover:text-white hover:bg-white/5 rounded-lg transition-colors">
                        <X size={20} />
                    </button>
                </div>

                {/* Timeline */}
                <div className="p-6 space-y-6 max-h-[60vh] overflow-y-auto">
                    {details.timeline.map((step, index) => (
                        <div key={index} className="relative pl-8 group">
                            {/* Vertical Line */}
                            {index !== details.timeline.length - 1 && (
                                <div className="absolute left-[15px] top-8 bottom-[-24px] w-0.5 bg-slate-800 group-hover:bg-slate-700 transition-colors"></div>
                            )}

                            {/* Node */}
                            <div className={`absolute left-0 top-1 w-8 h-8 rounded-xl flex items-center justify-center border transition-all shadow-lg ${step.color}`}>
                                <step.icon size={14} />
                            </div>

                            {/* Content */}
                            <div>
                                <h3 className="text-sm font-bold text-white mb-1 group-hover:text-primary transition-colors">{step.title}</h3>
                                <p className="text-xs text-slate-400 leading-relaxed bg-slate-950/50 p-3 rounded-lg border border-white/5">
                                    {step.desc}
                                </p>
                            </div>
                        </div>
                    ))}

                    {details.timeline.length === 0 && (
                        <div className="text-center py-8 text-slate-500">
                            <BotIcon size={32} className="mx-auto mb-2 opacity-50" />
                            <p className="text-xs">Strateji detayları hazırlanıyor...</p>
                        </div>
                    )}
                </div>

                {/* Footer */}
                <div className="p-4 bg-slate-950/50 border-t border-white/5 text-center">
                    <p className="text-[10px] text-slate-500">
                        * Piyasa koşullarına göre sinyal süreleri değişiklik gösterebilir.
                    </p>
                </div>
            </motion.div>
        </div>
    );
}

export default function Dashboard() {
    const [bots, setBots] = useState<Bot[]>([]);
    const [selectedStrategyId, setSelectedStrategyId] = useState<string | null>(null);
    const [coins, setCoins] = useState<Coin[]>([]);
    const [strategies, setStrategies] = useState<Strategy[]>([]);
    const [wallet, setWallet] = useState<Wallet | null>(null);
    const [stats, setStats] = useState<DashboardStats | null>(null);
    const [user, setUser] = useState<User | null>(null);

    const [activeTab, setActiveTab] = useState<'active' | 'history'>('active');
    const [isLoading, setIsLoading] = useState(true);
    const [isCoinsLoading, setIsCoinsLoading] = useState(false);
    const [activeChartBotId, setActiveChartBotId] = useState<string | null>(null);
    const { connection } = useSignalR();

    const { openWallet } = useUI();

    // Bot Status Tracking for Notifications
    const prevBotsRef = useRef<Bot[]>([]);

    // Wizard State
    const [isWizardOpen, setIsWizardOpen] = useState(false);



    // --- API HANDLERS (Moved UP) ---
    const fetchInitialData = async () => {
        try {
            const [botsData, strategiesData, walletData, statsData] = await Promise.all([
                BotService.getAll(),
                MarketService.getStrategies(),
                WalletService.get(),
                MarketService.getStats()
            ]);
            setBots(botsData);
            setStrategies(strategiesData);
            setWallet(walletData);
            setStats(statsData);

        } catch (error) { console.error("Veri hatası", error); } finally { setIsLoading(false); }
    };

    const refreshCoins = async () => { setIsCoinsLoading(true); try { const coinsData = await MarketService.getCoins(); setCoins(coinsData); } catch (e) { console.error(e); } setIsCoinsLoading(false); };

    const fetchLiveUpdates = async () => {
        try {
            const [botsData, walletData, statsData] = await Promise.all([BotService.getAll(), WalletService.get(), MarketService.getStats()]);
            setBots(botsData); setWallet(walletData); setStats(statsData);
        } catch (e) { console.error(e) }
    };

    useEffect(() => {
        // Token Check
        const token = localStorage.getItem("token");
        if (!token) {
            window.location.href = '/login';
            return;
        }

        try {
            const userData = localStorage.getItem("user");
            if (userData) setUser(JSON.parse(userData));
        } catch (e) {
            console.error(e);
        }

        // Initial Data
        fetchInitialData();

        let isMounted = true;

        // Polling (Yedek olarak 10sn)
        const interval = setInterval(() => {
            if (isMounted) fetchLiveUpdates();
        }, 10000);
    }, []);

    useEffect(() => {
        if (!connection) return;

        let isMounted = true;

        // Listeners
        const handleBotUpdated = (updatedBot: Bot) => {
            if (!isMounted) return;
            setBots(prev => {
                const index = prev.findIndex(b => b.id === updatedBot.id);
                if (index > -1) {
                    const newBots = [...prev];
                    newBots[index] = updatedBot;
                    return newBots;
                }
                return [updatedBot, ...prev];
            });
        };

        const handleLogAdded = (botId: string, log: any) => {
            if (!isMounted) return;
            setBots(prev => prev.map(b => {
                if (b.id === botId) {
                    const updatedLogs = b.logs ? [...b.logs, log] : [log];
                    if (updatedLogs.length > 50) updatedLogs.shift();
                    return { ...b, logs: updatedLogs };
                }
                return b;
            }));
        };

        const handleWalletUpdated = (updatedWallet: Wallet) => {
            if (isMounted) setWallet(updatedWallet);
        };

        connection.on("BotUpdated", handleBotUpdated);
        connection.on("LogAdded", handleLogAdded);
        connection.on("WalletUpdated", handleWalletUpdated);

        return () => {
            isMounted = false;
            connection.off("BotUpdated", handleBotUpdated);
            connection.off("LogAdded", handleLogAdded);
            connection.off("WalletUpdated", handleWalletUpdated);
        };
    }, [connection]);

    // Check for Bot Status Changes
    useEffect(() => {
        if (prevBotsRef.current.length === 0) {
            prevBotsRef.current = bots;
            return;
        }

        bots.forEach(bot => {
            const prevBot = prevBotsRef.current.find(b => b.id === bot.id);

            if (prevBot && prevBot.status === 'Running' && bot.status !== 'Running') {
                if (bot.status === 'Completed') {
                    confetti({ particleCount: 150, spread: 70, origin: { y: 0.6 }, colors: ['#22c55e', '#ffffff', '#fbbf24'] });
                    toast.success(`KAR AL HEDEFİNE ULAŞILDI! 🚀`, { description: `${bot.symbol} botu %${bot.pnlPercent.toFixed(2)} kar ile kapandı.`, duration: 5000 });
                } else if (bot.status === 'Stopped') {
                    toast.error(`ZARAR DURDUR TETİKLENDİ ⚠️`, { description: `${bot.symbol} botu %${bot.pnlPercent.toFixed(2)} zarar ile durduruldu.`, duration: 5000 });
                }
            }
        });
        prevBotsRef.current = bots;
    }, [bots]);

    // Wizard Handler
    const handleBotCreate = async (payload: any) => {
        try {
            await BotService.create(payload);
            toast.success("Bot Başlatıldı", { description: `${payload.symbol} üzerinde işlem başladı.` });
            await fetchLiveUpdates();
        } catch (error: unknown) {
            const msg = error instanceof Error ? error.message : "Bot başlatılamadı!";
            toast.error("Hata", { description: msg });
        }
    };

    // Stop Confirmation Logic
    const [confirmStopId, setConfirmStopId] = useState<string | null>(null);

    const handleStopBot = (id: string) => {
        setConfirmStopId(id);
    };

    const executeStopBot = async () => {
        if (!confirmStopId) return;
        try {
            await BotService.stop(confirmStopId);
            await fetchLiveUpdates();
            toast.info("Bot Durduruldu", { description: "Manuel olarak işlem sonlandırıldı." });
        } catch (error) {
            console.error(error);
            toast.error("Hata", { description: "Bot durdurulamadı." });
        } finally {
            setConfirmStopId(null);
        }
    };
    const handleLogout = () => {
        localStorage.removeItem("token");
        localStorage.removeItem("user");
        window.location.href = '/login';
    };

    // Bot Listesi Filtreleme
    const activeBots = bots.filter(b => b.status === 'Running' || b.status === 'WaitingForEntry');
    const historyBots = bots.filter(b => b.status !== 'Running' && b.status !== 'WaitingForEntry');

    return (
        <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-20">

            {/* HEADER BAR */}
            <Navbar user={user} />



            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
                {/* LEFT COLUMN - CREATE BOT */}
                <div className="lg:col-span-4 space-y-6 lg:sticky lg:top-8 h-fit">
                    <div className="glass-card p-1 relative overflow-hidden group">
                        <div className="absolute top-0 right-0 w-32 h-32 bg-primary/20 rounded-full blur-3xl -mr-16 -mt-16 pointer-events-none group-hover:bg-primary/30 transition-all duration-700"></div>

                        <div className="bg-slate-900/50 rounded-xl p-8 relative z-10 text-center">
                            <div className="w-20 h-20 bg-gradient-to-br from-primary to-amber-500 rounded-3xl mx-auto flex items-center justify-center shadow-lg shadow-primary/20 mb-6 group-hover:scale-110 transition-transform duration-500">
                                <Zap size={40} className="text-white fill-white" />
                            </div>

                            <h2 className="text-2xl font-display font-bold text-white mb-2">Yeni Bot Başlat</h2>
                            <p className="text-sm text-slate-400 mb-8 leading-relaxed max-w-[250px] mx-auto">
                                Yapay zeka destekli otonom alım-satım botunu saniyeler içinde kurun ve kazanmaya başlayın.
                            </p>

                            <button
                                onClick={() => setIsWizardOpen(true)}
                                className="w-full bg-linear-to-r from-primary to-amber-500 hover:to-amber-400 text-slate-900 font-display font-bold py-4 rounded-xl shadow-lg shadow-primary/20 active:scale-[0.98] transition-all flex justify-center items-center gap-2 group/btn"
                            >
                                <Zap className="fill-current w-5 h-5 group-hover/btn:scale-110 transition-transform" />
                                Bot Sihirbazını Aç
                            </button>
                        </div>
                    </div>
                </div>

                {/* RIGHT COLUMN - TABS & CONTENT */}
                <div className="lg:col-span-8">
                    {/* STATS BAR (Moved from top) */}
                    {stats && wallet && (
                        <div className="grid grid-cols-3 gap-4 mb-6">
                            <div className="glass-card p-4 flex flex-col justify-between relative overflow-hidden group">
                                <div className="flex justify-between items-start z-10">
                                    <div>
                                        <p className="text-slate-400 text-[10px] font-bold uppercase tracking-widest mb-1">Aktif Botlar</p>
                                        <h3 className="text-xl font-display font-bold text-white">{stats.active_bots}</h3>
                                    </div>
                                    <div className="p-2 rounded-lg bg-emerald-500/10 text-emerald-400">
                                        <Activity size={18} />
                                    </div>
                                </div>
                                <div className="absolute bottom-0 right-0 w-16 h-16 bg-emerald-500/10 rounded-full blur-xl -mr-4 -mb-4 pointer-events-none"></div>
                            </div>

                            <div
                                onClick={() => openWallet()}
                                className="glass-card p-4 flex flex-col justify-between relative overflow-hidden group cursor-pointer border-primary/20 bg-primary/5 hover:bg-primary/10 transition-colors"
                            >
                                <div className="flex justify-between items-start z-10">
                                    <div>
                                        <p className="text-primary/60 text-[10px] font-bold uppercase tracking-widest mb-1">Toplam Bakiye</p>
                                        <h3 className="text-xl font-display font-bold text-white">${wallet.current_balance?.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</h3>
                                    </div>
                                    <div className="p-2 rounded-lg bg-primary/20 text-primary">
                                        <WalletIcon size={18} />
                                    </div>
                                </div>
                                <div className="absolute bottom-0 right-0 w-16 h-16 bg-primary/20 rounded-full blur-xl -mr-4 -mb-4 pointer-events-none"></div>
                            </div>

                            <div className="glass-card p-4 flex flex-col justify-between relative overflow-hidden group">
                                <div className="flex justify-between items-start z-10">
                                    <div>
                                        <p className="text-slate-400 text-[10px] font-bold uppercase tracking-widest mb-1">İşlem Hacmi</p>
                                        <h3 className="text-xl font-display font-bold text-white">${stats.total_volume}</h3>
                                    </div>
                                    <div className="p-2 rounded-lg bg-secondary/10 text-secondary">
                                        <BarChart2 size={18} />
                                    </div>
                                </div>
                                <div className="absolute bottom-0 right-0 w-16 h-16 bg-secondary/10 rounded-full blur-xl -mr-4 -mb-4 pointer-events-none"></div>
                            </div>
                        </div>
                    )}
                    {/* TAB NAVIGATION */}
                    <div className="glass-card p-1.5 flex gap-1 mb-6 w-fit bg-slate-900/60">
                        <TabButton id="active" label="Aktif Botlar" count={activeBots.length} activeTab={activeTab} setActiveTab={setActiveTab} icon={<Activity size={16} />} />
                        <TabButton id="history" label="Geçmiş" activeTab={activeTab} setActiveTab={setActiveTab} icon={<History size={16} />} />
                    </div>

                    {/* CONTENT AREA */}
                    <div className="min-h-[500px]">
                        <AnimatePresence mode="wait">
                            {/* ACTIVE BOTS TAB */}
                            {activeTab === 'active' && (
                                <motion.div key="active" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }} className="space-y-4">
                                    {activeBots.length === 0 ? (
                                        <EmptyState title="Sistem Boşta" description="İşlem yapmak için sol panelden yeni bir bot başlatın." icon={<Cpu size={48} />} />
                                    ) : (
                                        activeBots.map((bot) => (
                                            <BotCard key={bot.id} bot={bot} isActive={true} activeChartBotId={activeChartBotId} setActiveChartBotId={setActiveChartBotId} handleStopBot={handleStopBot} onStrategyClick={setSelectedStrategyId} />
                                        ))
                                    )}
                                </motion.div>
                            )}

                            {/* HISTORY BOTS TAB */}
                            {activeTab === 'history' && (
                                <motion.div key="history" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }} className="space-y-4">
                                    {historyBots.length === 0 ? (
                                        <EmptyState title="Geçmiş Yok" description="Tamamlanan işlemler burada görünecektir." icon={<History size={48} />} />
                                    ) : (
                                        historyBots.map((bot) => (
                                            <BotCard key={bot.id} bot={bot} isActive={false} activeChartBotId={activeChartBotId} setActiveChartBotId={setActiveChartBotId} handleStopBot={handleStopBot} onStrategyClick={setSelectedStrategyId} />
                                        ))
                                    )}
                                </motion.div>
                            )}



                        </AnimatePresence>
                    </div>


                    {/* Confirmation Modal */}
                    <AnimatePresence>
                        {
                            confirmStopId && (
                                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
                                    <motion.div
                                        initial={{ opacity: 0, scale: 0.95 }}
                                        animate={{ opacity: 1, scale: 1 }}
                                        exit={{ opacity: 0, scale: 0.95 }}
                                        className="bg-slate-900 border border-white/10 rounded-2xl p-6 max-w-sm w-full shadow-2xl"
                                    >
                                        <div className="flex flex-col items-center text-center gap-4">
                                            <div className="w-16 h-16 bg-amber-500/10 rounded-full flex items-center justify-center text-amber-500 mb-2">
                                                <AlertTriangle size={32} />
                                            </div>

                                            <div>
                                                <h3 className="text-white font-bold text-xl mb-2">Bot Durdurma Onayı</h3>
                                                <p className="text-slate-400 text-sm">
                                                    Bu botu ve açık olan pozisyonu kapatmak istediğinize emin misiniz? <br />
                                                    <span className="text-rose-400 font-bold">Bu işlem geri alınamaz.</span>
                                                </p>
                                            </div>

                                            <div className="flex gap-3 w-full mt-2">
                                                <button
                                                    onClick={() => setConfirmStopId(null)}
                                                    className="flex-1 py-3 rounded-xl bg-slate-800 text-slate-300 hover:bg-slate-700 font-bold transition-colors"
                                                >
                                                    Vazgeç
                                                </button>
                                                <button
                                                    onClick={executeStopBot}
                                                    className="flex-1 py-3 rounded-xl bg-rose-600 text-white hover:bg-rose-500 font-bold transition-colors shadow-lg shadow-rose-600/20"
                                                >
                                                    Evet, Durdur
                                                </button>
                                            </div>
                                        </div>
                                    </motion.div>
                                </div>
                            )
                        }
                    </AnimatePresence >

                    {/* Strategy Details Modal */}
                    {/* Strategy Details Modal */}
                    <StrategyModal
                        isOpen={!!selectedStrategyId}
                        onClose={() => setSelectedStrategyId(null)}
                        strategyId={selectedStrategyId}
                    />

                    {/* Bot Wizard Modal */}
                    <BotWizardModal
                        isOpen={isWizardOpen}
                        onClose={() => setIsWizardOpen(false)}
                        coins={coins}
                        strategies={strategies}
                        wallet={wallet}
                        onBotCreate={handleBotCreate}
                        isCoinsLoading={isCoinsLoading}
                        refreshCoins={refreshCoins}
                    />

                </div>
            </div>
        </main>
    );
}


