"use client";

import { useEffect, useState, useRef } from "react";
import { Bot, Strategy, Coin, Wallet, User, DashboardStats } from "@/types";
import { BotService, MarketService, WalletService, HUB_URL } from "@/lib/api";
import { motion, AnimatePresence } from "framer-motion";
import {
    LayoutDashboard,
    Plus,
    Activity,
    History,
    Settings,
    LogOut,
    TrendingUp,
    Play,
    Square,
    ChevronDown,
    Zap,
    ExternalLink,
    AlertTriangle,
    Wallet as WalletIcon,
    FlaskConical,
    Cpu,
    BarChart2,
    Info,
    OctagonX,
    DollarSign,
    Loader2,
    Database,
    User as UserIcon,
    Key,
    Clock,
    X,
    Bot as BotIcon
} from "lucide-react";
import ConfirmationModal from "@/components/ui/ConfirmationModal";
import SearchableSelect from "@/components/ui/SearchableSelect";
import TradingViewWidget from "@/components/ui/TradingViewWidget";
import BotLogs from "@/components/ui/BotLogs";
import LoadingSkeleton from "@/components/ui/LoadingSkeleton";
import WalletModal from "@/components/ui/WalletModal";
import confetti from "canvas-confetti";
import { toast } from "sonner";
import Link from "next/link";
import Navbar from "@/components/ui/Navbar";
import { useUI } from "@/context/UIContext";
import { useSignalR } from "@/context/SignalRContext";
// Dashboard Components
import { StatCard } from "@/components/dashboard/StatCard";
import { TabButton } from "@/components/dashboard/TabButton";
import { EmptyState } from "@/components/dashboard/EmptyState";
import { BotCard } from "@/components/dashboard/BotCard";
import { StrategyModal } from "@/components/dashboard/StrategyModal";
import { InfoTooltip } from "@/components/dashboard/InfoTooltip";
import { StatCardSkeleton, BotCardSkeleton } from "@/components/ui/Skeletons";
import AiSentimentWidget from "@/components/dashboard/AiSentimentWidget";
import SentimentTrendChart from "@/components/dashboard/SentimentTrendChart";
import AiChatWidget from "@/components/dashboard/AiChatWidget";




export default function Dashboard() {
    const [bots, setBots] = useState<Bot[]>([]);
    const [selectedStrategyId, setSelectedStrategyId] = useState<string | null>(null);
    const [coins, setCoins] = useState<Coin[]>([]);
    const [strategies, setStrategies] = useState<Strategy[]>([]);
    const [wallet, setWallet] = useState<Wallet | null>(null);
    const [stats, setStats] = useState<DashboardStats | null>(null);
    const [user, setUser] = useState<User | null>(null);

    const [activeTab, setActiveTab] = useState<'active' | 'history'>('active');
    const [botFilter, setBotFilter] = useState<'all' | 'position' | 'waiting'>('all');
    const [isLoading, setIsLoading] = useState(true);
    const [isCoinsLoading, setIsCoinsLoading] = useState(false);
    const [activeChartBotId, setActiveChartBotId] = useState<string | null>(null);
    const { connection } = useSignalR();

    const { openWallet } = useUI();

    // Bot Status Tracking for Notifications
    const prevBotsRef = useRef<Bot[]>([]);

    // Wizard State
    const [isStopAllConfirmOpen, setIsStopAllConfirmOpen] = useState(false);
    const [isClearHistoryConfirmOpen, setIsClearHistoryConfirmOpen] = useState(false);



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

    const handleStopAllBots = async () => {
        setIsStopAllConfirmOpen(false);
        try {
            await BotService.stopAll();
            toast.success("Tüm botlar durduruldu ve pozisyonlar kapatıldı.");
            await fetchLiveUpdates();
        } catch (error) {
            console.error(error);
            toast.error("İşlem başarısız oldu.");
        }
    };

    const handleClearHistory = async () => {
        setIsClearHistoryConfirmOpen(false);
        try {
            const res = await BotService.clearHistory();
            if (res?._unauthorized) return;
            toast.success("İşlem geçmişi temizlendi.");
            await fetchLiveUpdates();
        } catch (error) {
            console.error(error);
            toast.error("Geçmiş temizlenemedi.");
        }
    };
    const handleLogout = () => {
        localStorage.removeItem("token");
        localStorage.removeItem("user");
        window.location.href = '/login';
    };

    // Bot Listesi Filtreleme ve Sıralama (En yeni en üstte)
    const sortedBots = [...bots].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    const activeBotsRaw = sortedBots.filter(b => b.status === 'Running' || b.status === 'WaitingForEntry');

    // Filtrelenmiş aktif botlar
    const activeBots = activeBotsRaw.filter(b => {
        if (botFilter === 'all') return true;
        if (botFilter === 'position') return b.status === 'Running';
        if (botFilter === 'waiting') return b.status === 'WaitingForEntry';
        return true;
    });

    const historyBots = sortedBots.filter(b => b.status !== 'Running' && b.status !== 'WaitingForEntry');

    return (
        <>
            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-20">

                {/* HEADER BAR */}
                <Navbar user={user} />



                <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
                    {/* LEFT COLUMN - CREATE BOT */}
                    <div className="lg:col-span-4 space-y-6 lg:sticky lg:top-8 h-fit hidden lg:block">
                        <div className="glass-card p-1 relative overflow-hidden group">
                            <div className="absolute top-0 right-0 w-32 h-32 bg-primary/20 rounded-full blur-3xl -mr-16 -mt-16 pointer-events-none group-hover:bg-primary/30 transition-all duration-700"></div>

                            <div className="bg-slate-900/50 rounded-xl p-8 relative z-10 text-center">
                                <div className="w-20 h-20 bg-linear-to-br from-primary to-amber-500 rounded-3xl mx-auto flex items-center justify-center shadow-lg shadow-primary/20 mb-6 group-hover:scale-110 transition-transform duration-500">
                                    <Zap size={40} className="text-white fill-white" />
                                </div>

                                <h2 className="text-2xl font-display font-bold text-white mb-2">Yeni Bot Başlat</h2>
                                <p className="text-sm text-slate-400 mb-8 leading-relaxed max-w-[250px] mx-auto">
                                    Yapay zeka destekli otonom alım-satım botunu saniyeler içinde kurun ve kazanmaya başlayın.
                                </p>

                                <Link
                                    href="/bots/new"
                                    className="w-full bg-linear-to-r from-primary to-amber-500 hover:to-amber-400 text-slate-900 font-display font-bold py-4 rounded-xl shadow-lg shadow-primary/20 active:scale-[0.98] transition-all flex justify-center items-center gap-2 group/btn"
                                >
                                    <Zap className="fill-current w-5 h-5 group-hover/btn:scale-110 transition-transform" />
                                    Yeni Bot Oluştur
                                </Link>
                            </div>
                        </div>

                        {/* AI Sentiment Widget */}
                        {/* <AiSentimentWidget /> */}

                        {/* Sentiment Trend Chart */}
                        {/* <SentimentTrendChart /> */}
                    </div>

                    {/* RIGHT COLUMN - TABS & CONTENT */}
                    <div className="lg:col-span-8">
                        {/* STATS BAR */}
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                            {isLoading ? (
                                <>
                                    <StatCardSkeleton />
                                    <StatCardSkeleton />
                                    <StatCardSkeleton />
                                </>
                            ) : (
                                <>
                                    <StatCard
                                        title="Aktif Botlar"
                                        value={stats?.active_bots || 0}
                                        icon={<Activity size={20} />}
                                        delay={0.1}
                                        description="Şu anda piyasada aktif olarak işlem yapan veya sinyal bekleyen bot sayısı"
                                    />
                                    <StatCard
                                        title="Toplam Bakiye"
                                        value={`$${wallet?.current_balance?.toLocaleString('en-US', { minimumFractionDigits: 2 })}`}
                                        icon={<WalletIcon size={20} />}
                                        delay={0.2}
                                        highlight
                                        onClick={() => openWallet()}
                                        description="Cüzdanınızdaki toplam varlıkların güncel dolar değeri"
                                    />
                                    <StatCard
                                        title="İşlem Hacmi"
                                        value={`$${stats?.total_volume?.toLocaleString() || 0}`}
                                        icon={<BarChart2 size={20} />}
                                        delay={0.3}
                                        description="Botlar tarafından gerçekleştirilen toplam alım-satım miktarının dolar karşılığı"
                                    />
                                </>
                            )}
                        </div>
                        {/* TAB NAVIGATION & ACTIONS */}
                        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 mb-6">
                            <div className="flex flex-col gap-4 w-full sm:w-auto overflow-hidden">
                                <div className="glass-card p-1.5 flex gap-1 w-full sm:w-fit bg-slate-900/60 overflow-x-auto scrollbar-hide">
                                    <TabButton id="active" label="Aktif Botlar" count={activeBotsRaw.length} activeTab={activeTab} setActiveTab={setActiveTab} icon={<Activity size={16} />} />
                                    <TabButton id="history" label="Geçmiş" count={historyBots.length} activeTab={activeTab} setActiveTab={setActiveTab} icon={<History size={16} />} />
                                </div>

                                {activeTab === 'active' && activeBotsRaw.length > 0 && (
                                    <div className="flex items-center gap-2 p-1 bg-slate-900/40 rounded-xl border border-white/5 w-full sm:w-fit overflow-x-auto scrollbar-hide">
                                        <button
                                            onClick={() => setBotFilter('all')}
                                            className={`px-3 py-1.5 rounded-lg text-[10px] font-bold transition-all uppercase tracking-wider flex items-center gap-1.5 shrink-0 ${botFilter === 'all' ? 'bg-primary/20 text-primary border border-primary/20' : 'text-slate-500 hover:text-slate-300'}`}
                                        >
                                            Hepsi
                                            <span className={`px-1 rounded ${botFilter === 'all' ? 'bg-primary/20' : 'bg-slate-800'}`}>{activeBotsRaw.length}</span>
                                        </button>
                                        <button
                                            onClick={() => setBotFilter('position')}
                                            className={`px-3 py-1.5 rounded-lg text-[10px] font-bold transition-all uppercase tracking-wider flex items-center gap-1.5 shrink-0 ${botFilter === 'position' ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/20' : 'text-slate-500 hover:text-slate-300'}`}
                                        >
                                            <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]" />
                                            Pozisyonda
                                            <span className={`px-1 rounded ${botFilter === 'position' ? 'bg-emerald-500/20' : 'bg-slate-800'}`}>{activeBotsRaw.filter(b => b.status === 'Running').length}</span>
                                        </button>
                                        <button
                                            onClick={() => setBotFilter('waiting')}
                                            className={`px-3 py-1.5 rounded-lg text-[10px] font-bold transition-all uppercase tracking-wider flex items-center gap-1.5 shrink-0 ${botFilter === 'waiting' ? 'bg-amber-500/20 text-amber-400 border border-amber-500/20' : 'text-slate-500 hover:text-slate-300'}`}
                                        >
                                            <div className="w-1.5 h-1.5 rounded-full bg-amber-500 shadow-[0_0_8px_rgba(245,158,11,0.5)]" />
                                            Sinyal Bekleniyor
                                            <span className={`px-1 rounded ${botFilter === 'waiting' ? 'bg-amber-500/20' : 'bg-slate-800'}`}>{activeBotsRaw.filter(b => b.status === 'WaitingForEntry').length}</span>
                                        </button>
                                    </div>
                                )}
                            </div>

                            <div className="flex items-center gap-3 w-full sm:w-auto sm:justify-end">
                                {activeTab === 'active' && activeBotsRaw.length > 0 && (
                                    <button
                                        onClick={() => setIsStopAllConfirmOpen(true)}
                                        className="flex items-center gap-0 hover:gap-2 px-3 hover:px-4 py-2 bg-rose-500/10 text-rose-500 border border-rose-500/20 rounded-xl hover:bg-rose-600 hover:text-white transition-all text-xs font-bold uppercase tracking-wider group relative"
                                        title="Tüm İşlemleri Durdur"
                                    >
                                        <OctagonX size={16} className="shrink-0 group-hover:animate-pulse" />
                                        <div className="max-w-0 group-hover:max-w-xs overflow-hidden transition-all duration-300 ease-in-out whitespace-nowrap">
                                            <span className="pl-1">Tüm İşlemleri Durdur</span>
                                        </div>
                                    </button>
                                )}

                                {activeTab === 'history' && historyBots.length > 0 && (
                                    <button
                                        onClick={() => setIsClearHistoryConfirmOpen(true)}
                                        className="flex items-center gap-2 px-4 py-2 bg-slate-800 text-slate-400 border border-white/5 rounded-xl hover:bg-slate-700 hover:text-white transition-all text-xs font-bold uppercase tracking-wider group"
                                    >
                                        <History size={16} />
                                        Geçmişi Temizle
                                    </button>
                                )}
                            </div>
                        </div>

                        {/* CONTENT AREA */}
                        <div className="min-h-[500px]">
                            <AnimatePresence mode="wait">
                                {isLoading ? (
                                    <motion.div key="loading" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="space-y-4">
                                        <BotCardSkeleton />
                                        <BotCardSkeleton />
                                        <BotCardSkeleton />
                                    </motion.div>
                                ) : (
                                    <>
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
                                    </>
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

                        {/* Mobile FAB */}
                        <Link
                            href="/bots/new"
                            className="fixed bottom-6 right-6 z-40 lg:hidden w-14 h-14 bg-linear-to-r from-primary to-amber-500 text-slate-900 rounded-full shadow-xl shadow-primary/20 flex items-center justify-center active:scale-95 transition-transform hover:scale-110"
                        >
                            <Plus size={28} className="font-bold" />
                        </Link>

                        {/* Strategy Details Modal */}
                        <StrategyModal
                            isOpen={!!selectedStrategyId}
                            onClose={() => setSelectedStrategyId(null)}
                            strategyId={selectedStrategyId}
                        />

                        {/* Stop All Confirmation Modal */}
                        <ConfirmationModal
                            isOpen={isStopAllConfirmOpen}
                            title="ACİL DURDURMA"
                            message="DİKKAT! Bu işlem çalışan TÜM botları durduracak ve açık olan tüm pozisyonları piyasa fiyatından kapatacaktır. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?"
                            onConfirm={handleStopAllBots}
                            onCancel={() => setIsStopAllConfirmOpen(false)}
                            confirmText="Evet, Her Şeyi Kapat"
                            isDangerous={true}
                        />

                        {/* Clear History Confirmation Modal */}
                        <ConfirmationModal
                            isOpen={isClearHistoryConfirmOpen}
                            title="GEÇMİŞİ TEMİZLE"
                            message="İşlem geçmişinizi temizlemek istediğinize emin misiniz? Bu işlem sadece bu listeden kaldırır, veritabanında kayıtlı kalmaya devam eder."
                            onConfirm={handleClearHistory}
                            onCancel={() => setIsClearHistoryConfirmOpen(false)}
                            confirmText="Evet, Temizle"
                            isDangerous={false}
                        />
                    </div>
                </div>
            </main>

            {/* AI Chat Widget - Floating */}
            {/* <AiChatWidget /> */}
        </>
    );
}


