"use client";

import { useEffect, useState, useRef } from "react";
import { Bot, Strategy, Coin, Wallet, User, DashboardStats } from "@/types";
import { BotService, MarketService, WalletService, HUB_URL } from "@/lib/api";
import { motion, AnimatePresence } from "framer-motion";
import { Activity, TrendingUp, BarChart2, DollarSign, Wallet as WalletIcon, ChevronDown, Loader2, FlaskConical, History, Database, Settings, LogOut, User as UserIcon, Key, Zap, Cpu, Square, AlertTriangle } from "lucide-react";
import SearchableSelect from "@/components/ui/SearchableSelect";
import TradingViewWidget from "@/components/ui/TradingViewWidget";
import BotLogs from "@/components/ui/BotLogs";
import WalletModal from "@/components/ui/WalletModal";
import SettingsModal from "@/components/ui/SettingsModal";
import LogsDrawer from "@/components/ui/LogsDrawer";
import confetti from "canvas-confetti";
import { toast } from "sonner";
import { HubConnectionBuilder, HubConnection } from "@microsoft/signalr";
import BacktestPanel from "@/components/ui/BacktestPanel";
import AnalyticsDashboard from "@/components/ui/AnalyticsDashboard";

export default function Dashboard() {
    const [bots, setBots] = useState<Bot[]>([]);
    const [coins, setCoins] = useState<Coin[]>([]);
    const [strategies, setStrategies] = useState<Strategy[]>([]);
    const [wallet, setWallet] = useState<Wallet | null>(null);
    const [stats, setStats] = useState<DashboardStats | null>(null);
    const [user, setUser] = useState<User | null>(null);
    const [isProfileOpen, setIsProfileOpen] = useState(false);

    // Settings Modal States
    const [isSettingsOpen, setIsSettingsOpen] = useState(false);
    const [isLogsOpen, setIsLogsOpen] = useState(false);
    const [settingsTab, setSettingsTab] = useState<'api' | 'general' | 'users'>('api');

    const [activeTab, setActiveTab] = useState<'active' | 'history' | 'backtest' | 'analytics'>('active');
    const [isWalletModalOpen, setIsWalletModalOpen] = useState(false);
    const [isLoading, setIsLoading] = useState(true);
    const [isCoinsLoading, setIsCoinsLoading] = useState(false);
    const [activeChartBotId, setActiveChartBotId] = useState<string | null>(null);
    const [isSignalRConnected, setIsSignalRConnected] = useState(false);

    // Bot Status Tracking for Notifications
    const prevBotsRef = useRef<Bot[]>([]);

    // Form States
    const [selectedCoin, setSelectedCoin] = useState("BTC/USDT");
    const [selectedStrategy, setSelectedStrategy] = useState("");
    const [amount, setAmount] = useState(100);
    const [takeProfit, setTakeProfit] = useState("");
    const [stopLoss, setStopLoss] = useState("");
    const [selectedInterval, setSelectedInterval] = useState("1h");
    const [isStarting, setIsStarting] = useState(false);

    const connectionRef = useRef<HubConnection | null>(null);

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

        // SIGNALR CONNECTION
        const connection = new HubConnectionBuilder()
            .withUrl(HUB_URL, {
                accessTokenFactory: () => localStorage.getItem("token") || ""
            })
            .withAutomaticReconnect()
            .build();

        const startConnection = async () => {
            if (connection.state === "Connected") {
                if (isMounted) setIsSignalRConnected(true);
                return;
            }

            try {
                if (connection.state === "Disconnected") {
                    await connection.start();
                    if (isMounted) {
                        console.log("SignalR Connected!");
                        setIsSignalRConnected(true);
                    }
                }
            } catch (err: any) {
                // "stopped during negotiation" hatası React Strict Mode temizliği sırasında normaldir, konsola basma.
                const isNegotiationError = err.message?.includes("stopped during negotiation");
                if (!isNegotiationError) {
                    console.error("SignalR Connection Error: ", err);
                }

                if (isMounted && connection.state === "Disconnected") {
                    setTimeout(startConnection, isNegotiationError ? 100 : 5000);
                }
            }
        };

        startConnection();

        // Bağlantı durumlarını takip et
        connection.onclose(() => { if (isMounted) setIsSignalRConnected(false); });
        connection.onreconnecting(() => { if (isMounted) setIsSignalRConnected(false); });
        connection.onreconnected(() => { if (isMounted) setIsSignalRConnected(true); });

        // Listeners
        connection.on("BotUpdated", (updatedBot: Bot) => {
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
        });

        connection.on("LogAdded", (botId: string, log: any) => {
            if (!isMounted) return;
            setBots(prev => prev.map(b => {
                if (b.id === botId) {
                    const updatedLogs = b.logs ? [...b.logs, log] : [log];
                    if (updatedLogs.length > 50) updatedLogs.shift();
                    return { ...b, logs: updatedLogs };
                }
                return b;
            }));
        });

        connection.on("WalletUpdated", (updatedWallet: Wallet) => {
            if (isMounted) setWallet(updatedWallet);
        });

        return () => {
            isMounted = false;
            clearInterval(interval);
            connection.stop().catch(() => { });
            setIsSignalRConnected(false);
        };
    }, []);

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

    // Strateji değiştikçe varsayılan interval'i ayarla
    useEffect(() => {
        if (selectedStrategy === "strategy-market-buy") setSelectedInterval("1m");
        else if (selectedStrategy === "strategy-golden-rose") setSelectedInterval("1h");
        else if (selectedStrategy === "strategy-sma-crossover") setSelectedInterval("15m");
    }, [selectedStrategy]);

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
            if (strategiesData.length > 0) setSelectedStrategy(strategiesData[0].id);
        } catch (error) { console.error("Veri hatası", error); } finally { setIsLoading(false); }
    };

    const refreshCoins = async () => { setIsCoinsLoading(true); try { const coinsData = await MarketService.getCoins(); setCoins(coinsData); } catch (e) { console.error(e); } setIsCoinsLoading(false); };

    const fetchLiveUpdates = async () => {
        try {
            const [botsData, walletData, statsData] = await Promise.all([BotService.getAll(), WalletService.get(), MarketService.getStats()]);
            setBots(botsData); setWallet(walletData); setStats(statsData);
        } catch (e) { console.error(e) }
    };
    const handleStartBot = async () => {
        if (!selectedCoin || !selectedStrategy || amount <= 0) {
            toast.warning("Hatalı Giriş", { description: "Lütfen coin, strateji ve tutar alanlarını kontrol ediniz." });
            return;
        }

        setIsStarting(true);
        try {
            const payload = {
                symbol: selectedCoin,
                strategyId: selectedStrategy,
                amount: amount,
                interval: selectedInterval,
                takeProfit: takeProfit ? Number(takeProfit) : null,
                stopLoss: stopLoss ? Number(stopLoss) : null
            };

            await BotService.start(payload);
            toast.success("Bot Başlatıldı", { description: `${selectedCoin} üzerinde işlem başladı.` });
            await fetchLiveUpdates();

            // Formu Sıfırla
            setAmount(100);
            setTakeProfit("");
            setStopLoss("");
        } catch (error: unknown) {
            const msg = error instanceof Error ? error.message : "Bot başlatılamadı!";
            toast.error("Hata", { description: msg });
        } finally { setIsStarting(false); }
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

    const setAmountByPercent = (percent: number) => { if (wallet?.available_balance) { setAmount(Math.floor(wallet.available_balance * (percent / 100))); } };

    // Bakiye Kontrolü
    const isImmediate = selectedStrategy === "strategy-market-buy";
    const isInsufficientBalance = wallet && amount > wallet.available_balance;
    const shouldDisableButton = isStarting || (isImmediate && isInsufficientBalance);

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
            <header className="flex items-center justify-between mb-10">
                {/* Logo & Brand */}
                <div className="flex items-center gap-4">
                    <div className="relative group">
                        <div className="absolute inset-0 bg-primary/40 rounded-xl blur-lg group-hover:blur-xl transition-all"></div>
                        <div className="bg-slate-900 border border-white/10 p-2.5 rounded-xl shadow-lg relative">
                            <Activity className="text-secondary w-6 h-6" />
                        </div>
                    </div>
                    <div>
                        <div className="flex items-center gap-2">
                            <h1 className="text-2xl font-display font-bold text-white tracking-wide">
                                KRIP<span className="text-primary">TEKS</span>
                            </h1>
                        </div>
                        <p className="text-[10px] text-slate-400 font-mono tracking-widest uppercase opacity-80">Otonom Motor v2.1</p>
                    </div>
                </div>

                {/* Right Side: Status & Profile */}
                <div className="flex items-center gap-6">
                    {/* System Status */}
                    <div className="hidden md:flex items-center gap-3 px-4 py-2 bg-slate-900/40 rounded-full border border-white/5 backdrop-blur-sm">
                        <div className="relative flex h-2.5 w-2.5">
                            <span className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${isSignalRConnected ? 'bg-emerald-400' : 'bg-rose-500'}`}></span>
                            <span className={`relative inline-flex rounded-full h-2.5 w-2.5 ${isSignalRConnected ? 'bg-emerald-500' : 'bg-rose-500'}`}></span>
                        </div>
                        <span className="text-xs text-slate-300 font-medium tracking-wide">{isSignalRConnected ? 'SİSTEM ÇEVRİMİÇİ' : 'BAĞLANTI YOK'}</span>
                    </div>

                    {/* Profile */}
                    <div className="relative z-50">
                        <button
                            onClick={() => setIsProfileOpen(!isProfileOpen)}
                            className="flex items-center gap-3 glass-card px-2 py-1.5 pl-4 pr-1.5 transition-all group hover:bg-slate-800"
                        >
                            <div className="text-right hidden sm:block">
                                <p className="text-xs font-bold text-white leading-tight group-hover:text-primary transition-colors">
                                    {user?.firstName || "Misafir"}
                                </p>
                                <p className="text-[10px] text-slate-400 font-mono leading-tight">
                                    {(user?.role || user?.Role) === 'Admin' ? 'YÖNETİCİ' : ((user?.role || user?.Role)?.toUpperCase() || 'MİSAFİR')}
                                </p>
                            </div>
                            <div className="w-9 h-9 bg-linear-to-br from-primary to-primary-light rounded-lg flex items-center justify-center text-slate-900 font-bold text-sm shadow-lg">
                                {user?.firstName?.charAt(0) || "Y"}
                            </div>
                        </button>

                        <AnimatePresence>
                            {isProfileOpen && (
                                <>
                                    <div className="fixed inset-0 z-10" onClick={() => setIsProfileOpen(false)}></div>
                                    <motion.div
                                        initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                        animate={{ opacity: 1, y: 0, scale: 1 }}
                                        exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                        className="absolute right-0 mt-3 w-64 glass-card p-2 z-20 flex flex-col gap-1"
                                    >
                                        <div className="px-4 py-3 mb-2 bg-white/5 rounded-xl border border-white/5">
                                            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-0.5">Giriş Yapılan Hesap</p>
                                            <p className="text-sm font-bold text-white truncate">{user?.email || "admin@kripteks.com"}</p>
                                        </div>

                                        <MenuButton icon={<Key size={14} />} label="API Bağlantıları" onClick={() => { setSettingsTab('api'); setIsSettingsOpen(true); setIsProfileOpen(false); }} />
                                        <MenuButton icon={<Settings size={14} />} label="Sistem Ayarları" onClick={() => { setSettingsTab('general'); setIsSettingsOpen(true); setIsProfileOpen(false); }} />
                                        <MenuButton icon={<UserIcon size={14} />} label="Kullanıcı Yönetimi" onClick={() => { setSettingsTab('users'); setIsSettingsOpen(true); setIsProfileOpen(false); }} />
                                        <MenuButton icon={<Database size={14} />} label="İşlem Kayıtları" onClick={() => { setIsLogsOpen(true); setIsProfileOpen(false); }} />

                                        <div className="h-px bg-white/10 my-1"></div>

                                        <button onClick={handleLogout} className="w-full text-left px-3 py-2.5 text-xs font-bold text-rose-400 hover:bg-rose-500/10 hover:text-rose-300 rounded-lg flex items-center gap-3 transition-colors">
                                            <LogOut size={14} />
                                            Çıkış Yap
                                        </button>
                                    </motion.div>
                                </>
                            )}
                        </AnimatePresence>
                    </div>
                </div>
            </header>



            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
                {/* LEFT COLUMN - CREATE BOT */}
                <div className="lg:col-span-4 space-y-6 lg:sticky lg:top-8 h-fit">
                    <div className="glass-card p-1 relative overflow-hidden group">
                        <div className="absolute top-0 right-0 w-32 h-32 bg-primary/20 rounded-full blur-3xl -mr-16 -mt-16 pointer-events-none group-hover:bg-primary/30 transition-all duration-700"></div>

                        <div className="bg-slate-900/50 rounded-xl p-5 relative z-10">
                            <h2 className="text-lg font-display font-bold text-white mb-4 flex items-center gap-3">
                                <div className="p-2 bg-primary/10 rounded-lg text-primary">
                                    <Zap size={18} />
                                </div>
                                Yeni Bot Başlat
                            </h2>

                            <div className="space-y-3">
                                <div className="space-y-1">
                                    <label className="text-xs font-bold text-slate-500 uppercase tracking-widest pl-1">Kripto Varlık</label>
                                    <SearchableSelect options={coins.map(c => ({ id: c.symbol, label: c.symbol, ...c }))} value={selectedCoin} onChange={setSelectedCoin} placeholder="Coin Seçiniz..." onOpen={refreshCoins} isLoading={isCoinsLoading} />
                                </div>

                                <div className="grid grid-cols-3 gap-3">
                                    <div className="col-span-2 space-y-1">
                                        <label className="text-xs font-bold text-slate-500 uppercase tracking-widest pl-1">Strateji</label>
                                        <div className="relative">
                                            <select
                                                className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-secondary focus:ring-1 focus:ring-secondary transition-all appearance-none text-sm"
                                                value={selectedStrategy}
                                                onChange={(e) => setSelectedStrategy(e.target.value)}
                                            >
                                                {strategies.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                                            </select>
                                            <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none w-4 h-4" />
                                        </div>
                                    </div>
                                    <div className="space-y-1">
                                        <label className="text-xs font-bold text-slate-500 uppercase tracking-widest pl-1">Zaman</label>
                                        <div className="relative">
                                            <select
                                                className="w-full bg-slate-950/50 border border-white/10 rounded-xl pl-3 pr-8 py-2 text-slate-200 outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all appearance-none text-sm font-mono"
                                                value={selectedInterval}
                                                onChange={(e) => setSelectedInterval(e.target.value)}
                                            >
                                                {['1m', '3m', '5m', '15m', '30m', '1h', '2h', '4h', '1d'].map(t => <option key={t} value={t}>{t}</option>)}
                                            </select>
                                            <ChevronDown className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none w-4 h-4" />
                                        </div>
                                    </div>
                                </div>

                                <div className="space-y-2">
                                    <div className="flex justify-between items-center px-1">
                                        <label className="text-xs font-bold text-slate-500 uppercase tracking-widest">Tutar (USDT)</label>
                                        {wallet && (<span className={`text-[10px] font-mono ${isInsufficientBalance ? 'text-rose-400' : 'text-slate-500'}`}> Kullanılabilir: <span className="text-slate-300 font-bold">${wallet.available_balance?.toLocaleString('en-US', { maximumFractionDigits: 0 })}</span> </span>)}
                                    </div>
                                    <div className="relative group/input">
                                        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 font-bold group-focus-within/input:text-primary transition-colors">$</span>
                                        <input type="number" value={amount} onChange={(e) => setAmount(Number(e.target.value))} className={`w-full bg-slate-950/50 border rounded-xl pl-8 pr-4 py-2 text-white font-mono focus:ring-1 transition-all outline-none ${isInsufficientBalance ? 'border-rose-500/50 focus:border-rose-500 focus:ring-rose-500' : 'border-white/10 focus:border-primary focus:ring-primary'}`} />
                                    </div>
                                    <div className="flex gap-2"> {[25, 50, 75, 100].map(p => (<button key={p} onClick={() => setAmountByPercent(p)} className="flex-1 bg-slate-800/50 hover:bg-slate-700 text-[10px] font-bold py-1.5 rounded-lg text-slate-400 hover:text-white transition-colors border border-white/5">% {p}</button>))} </div>
                                </div>

                                <div className="grid grid-cols-2 gap-3 pt-1">
                                    <div className="space-y-1">
                                        <label className="block text-[10px] font-bold text-emerald-500/80 uppercase tracking-widest pl-1">Kar Al %</label>
                                        <input type="number" placeholder="İsteğe Bağlı" className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-2 text-slate-200 text-sm outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500/50 transition-all font-mono" value={takeProfit} onChange={(e) => setTakeProfit(e.target.value)} />
                                    </div>
                                    <div className="space-y-1">
                                        <label className="block text-[10px] font-bold text-rose-500/80 uppercase tracking-widest pl-1">Zarar Durdur %</label>
                                        <input type="number" placeholder="İsteğe Bağlı" className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-2 text-slate-200 text-sm outline-none focus:border-rose-500 focus:ring-1 focus:ring-rose-500/50 transition-all font-mono" value={stopLoss} onChange={(e) => setStopLoss(e.target.value)} />
                                    </div>
                                </div>

                                <div className="pt-3">
                                    <button
                                        onClick={handleStartBot}
                                        disabled={!!shouldDisableButton}
                                        className={`w-full font-bold font-display py-3 rounded-xl shadow-lg active:scale-[0.98] transition-all flex justify-center items-center gap-2 group/btn ${shouldDisableButton
                                            ? 'bg-slate-800 text-slate-500 cursor-not-allowed opacity-50'
                                            : 'bg-linear-to-r from-primary to-primary-light hover:to-amber-300 text-black shadow-primary/20'
                                            }`}
                                    >
                                        {isStarting ? (<Loader2 className="animate-spin w-5 h-5" />) : (<>Botu Başlat <TrendingUp className="w-5 h-5 group-hover/btn:translate-x-1 transition-transform" /></>)}
                                    </button>

                                    {isInsufficientBalance && !isImmediate && (<p className="text-center text-[10px] text-amber-500 mt-3 font-medium bg-amber-500/10 py-1 rounded-lg"> ⚠️ Yetersiz bakiye, sinyal geldiğinde tekrar kontrol edilecek. </p>)}
                                    {isImmediate && isInsufficientBalance && (<p className="text-center text-xs text-rose-500 mt-2 font-medium"> BAKİYE YETERSİZ ⚠️ </p>)}
                                </div>
                            </div>
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
                                onClick={() => setIsWalletModalOpen(true)}
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
                    <div className="glass-card p-1.5 flex gap-1 mb-6 w-fit bg-slate-900/60 sticky top-4 z-40 backdrop-blur-md">
                        <TabButton id="active" label="Aktif Botlar" count={activeBots.length} activeTab={activeTab} setActiveTab={setActiveTab} icon={<Activity size={16} />} />
                        <TabButton id="history" label="Geçmiş" activeTab={activeTab} setActiveTab={setActiveTab} icon={<History size={16} />} />
                        <TabButton id="backtest" label="Simülasyon" activeTab={activeTab} setActiveTab={setActiveTab} icon={<FlaskConical size={16} />} />
                        <TabButton id="analytics" label="Raporlar" activeTab={activeTab} setActiveTab={setActiveTab} icon={<BarChart2 size={16} />} />
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
                                            <BotCard key={bot.id} bot={bot} isActive={true} activeChartBotId={activeChartBotId} setActiveChartBotId={setActiveChartBotId} handleStopBot={handleStopBot} />
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
                                            <BotCard key={bot.id} bot={bot} isActive={false} activeChartBotId={activeChartBotId} setActiveChartBotId={setActiveChartBotId} handleStopBot={handleStopBot} />
                                        ))
                                    )}
                                </motion.div>
                            )}

                            {/* BACKTEST TAB */}
                            {activeTab === 'backtest' && (
                                <motion.div key="backtest" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
                                    <div className="glass-card p-6">
                                        <BacktestPanel
                                            coins={coins}
                                            strategies={strategies}
                                            onRefreshCoins={refreshCoins}
                                            isCoinsLoading={isCoinsLoading}
                                        />
                                    </div>
                                </motion.div>
                            )}

                            {/* ANALYTICS TAB */}
                            {activeTab === 'analytics' && (
                                <motion.div key="analytics" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
                                    <div className="glass-card p-6">
                                        <AnalyticsDashboard />
                                    </div>
                                </motion.div>
                            )}
                        </AnimatePresence>
                    </div>
                </div>
            </div>

            <WalletModal isOpen={isWalletModalOpen} onClose={() => setIsWalletModalOpen(false)} />
            <SettingsModal isOpen={isSettingsOpen} onClose={() => setIsSettingsOpen(false)} activeTab={settingsTab} />
            <LogsDrawer isOpen={isLogsOpen} onClose={() => setIsLogsOpen(false)} />
            {/* Confirmation Modal */}
            <AnimatePresence>
                {confirmStopId && (
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
                )}
            </AnimatePresence>

        </main>
    );
}

// --- SUB COMPONENTS ---

// --- SUB COMPONENTS ---

interface MenuButtonProps {
    icon: React.ReactNode;
    label: string;
    onClick: () => void;
}

function MenuButton({ icon, label, onClick }: MenuButtonProps) {
    return (
        <button onClick={onClick} className="w-full text-left px-3 py-2.5 text-xs font-medium text-slate-300 hover:bg-slate-800 hover:text-white rounded-lg flex items-center gap-3 transition-colors">
            <div className="p-1.5 bg-slate-800 rounded-md text-slate-400 group-hover:text-primary transition-colors">{icon}</div>
            {label}
        </button>
    );
}

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
    id: 'active' | 'history' | 'backtest' | 'analytics';
    label: string;
    count?: number;
    activeTab: string;
    setActiveTab: (id: 'active' | 'history' | 'backtest' | 'analytics') => void;
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
}

function BotCard({ bot, isActive, activeChartBotId, setActiveChartBotId, handleStopBot }: BotCardProps) {
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

                            <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-800 text-slate-400 border border-white/5 uppercase hidden sm:block">{bot.strategyName}</span>
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
            <AnimatePresence>
                {(isActive || activeChartBotId === bot.id) && (
                    <motion.div
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: "auto", opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        className="border-t border-white/5 bg-black/20"
                    >
                        {activeChartBotId === bot.id && (
                            <div className="p-4">
                                <TradingViewWidget symbol={bot.symbol} strategy={bot.strategyName} />
                            </div>
                        )}

                        {/* Logs Accordion */}
                        <div className="border-t border-white/5">
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
                    </motion.div>
                )}
            </AnimatePresence>
        </motion.div>
    );
}
