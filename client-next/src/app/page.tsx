"use client";

import { useEffect, useState, useRef } from "react";
import { Bot, Strategy, Coin } from "@/types";
import { BotService, MarketService, WalletService, HUB_URL } from "@/lib/api";
import { motion, AnimatePresence } from "framer-motion";
import { Play, Square, Activity, TrendingUp, BarChart2, DollarSign, Wallet as WalletIcon, ChevronDown, Check, Loader2, ArrowUpRight, ArrowDownLeft, FlaskConical, History, Database, Settings, LogOut, User, Key, Bell } from "lucide-react";
import SearchableSelect from "@/components/ui/SearchableSelect";
import TradingViewWidget from "@/components/ui/TradingViewWidget";
import BotLogs from "@/components/ui/BotLogs";
import WalletModal from "@/components/ui/WalletModal";
import SettingsModal from "@/components/ui/SettingsModal";
import LogsDrawer from "@/components/ui/LogsDrawer"; // <--- Import eklendi
import confetti from "canvas-confetti";
import { toast } from "sonner";
import { HubConnectionBuilder } from "@microsoft/signalr";
import BacktestPanel from "@/components/ui/BacktestPanel";
import AnalyticsDashboard from "@/components/ui/AnalyticsDashboard";

export default function Dashboard() {
    const [bots, setBots] = useState<Bot[]>([]);
    const [coins, setCoins] = useState<Coin[]>([]);
    const [strategies, setStrategies] = useState<Strategy[]>([]);
    const [wallet, setWallet] = useState<any>(null);
    const [stats, setStats] = useState<any>(null);
    const [user, setUser] = useState<any>(null);
    const [isProfileOpen, setIsProfileOpen] = useState(false);

    // Settings Modal States
    const [isSettingsOpen, setIsSettingsOpen] = useState(false);
    const [isLogsOpen, setIsLogsOpen] = useState(false); // <--- State eklendi
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

    const connectionRef = useRef<any>(null);

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
        if (!connectionRef.current) {
            connectionRef.current = new HubConnectionBuilder()
                .withUrl(HUB_URL, {
                    accessTokenFactory: () => localStorage.getItem("token") || ""
                })
                .withAutomaticReconnect()
                .build();
        }

        const connection = connectionRef.current;

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
                if (!err.message?.includes("stopped during negotiation")) {
                    console.error("SignalR Connection Error: ", err);
                }

                if (isMounted && connection.state === "Disconnected") {
                    setTimeout(startConnection, 5000);
                }
            }
        };

        // Bağlantı durumlarını takip et (Daha güvenli senkronizasyon için)
        connection.onclose(() => { if (isMounted) setIsSignalRConnected(false); });
        connection.onreconnecting(() => { if (isMounted) setIsSignalRConnected(false); });
        connection.onreconnected(() => { if (isMounted) setIsSignalRConnected(true); });

        // Listeners (Önce temizle sonra ekle ki çift kayıt olmasın)
        connection.off("BotUpdated");
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

        connection.off("LogAdded");
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

        connection.off("WalletUpdated");
        connection.on("WalletUpdated", (updatedWallet: any) => {
            if (isMounted) setWallet(updatedWallet);
        });

        startConnection();

        return () => {
            isMounted = false;
            clearInterval(interval);
            // Bağlantıyı hemen kesme, müzakere hatasına yol açıyor. 
            // Sadece gerçekten bağlıysa ve uygulama unmount oluyorsa kapat.
            if (connection.state === "Connected") {
                connection.stop().catch(() => { });
                setIsSignalRConnected(false);
            }
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
        if (!selectedCoin || !selectedStrategy || amount <= 0) { toast.error("Eksik Bilgi", { description: "Lütfen tüm alanları doldurun." }); return; }

        setIsStarting(true);
        try {
            await BotService.start({
                symbol: selectedCoin,
                strategyId: selectedStrategy,
                amount: Number(amount),
                interval: selectedInterval,
                takeProfit: takeProfit ? Number(takeProfit) : undefined,
                stopLoss: stopLoss ? Number(stopLoss) : undefined
            });
            await fetchLiveUpdates();
            toast.success("Bot Başlatıldı", { description: `${selectedCoin} üzerinde işlem başladı.` });
        } catch (error: any) { toast.error("Hata", { description: error.message || "Bot başlatılamadı!" }); } finally { setIsStarting(false); }
    };

    const handleStopBot = async (id: string) => {
        try { await BotService.stop(id); await fetchLiveUpdates(); toast.info("Bot Durduruldu", { description: "Manuel olarak işlem sonlandırıldı." }); } catch (error) { console.error(error); }
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
            <div className="flex items-center justify-between mb-8">
                {/* Logo & Brand */}
                <div className="flex items-center gap-4">
                    <div className="bg-linear-to-br from-cyan-600 to-blue-600 p-2.5 rounded-xl shadow-lg shadow-cyan-500/20">
                        <Activity className="text-white w-6 h-6" />
                    </div>
                    <div>
                        <div className="flex items-center gap-2">
                            <h1 className="text-2xl font-bold bg-clip-text text-transparent bg-linear-to-r from-white to-slate-400">
                                Kripteks
                            </h1>
                            {/* <span className="px-2 py-0.5 rounded-md bg-cyan-500/10 border border-cyan-500/20 text-[10px] font-bold text-cyan-400 uppercase tracking-widest">
                                NEXT.GEN
                            </span> */}
                        </div>
                        <p className="text-[10px] text-slate-500 font-mono tracking-wide">Otomatik Alım Satım Motoru v2.0</p>
                    </div>
                </div>

                {/* Right Side: Status & Profile */}
                <div className="flex items-center gap-6">
                    {/* System Status */}
                    <div className="hidden md:flex items-center gap-2 px-3 py-1.5 bg-slate-800/50 rounded-full border border-slate-700/50">
                        <div className={`w-2 h-2 rounded-full ${isSignalRConnected ? 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.5)] animate-pulse' : 'bg-red-500'}`}></div>
                        <span className="text-xs text-slate-300 font-medium">{isSignalRConnected ? 'Sistem Çevrimiçi' : 'Bağlantı Yok'}</span>
                    </div>

                    {/* Profile */}
                    <div className="relative">
                        <button
                            onClick={() => setIsProfileOpen(!isProfileOpen)}
                            className="flex items-center gap-3 bg-slate-800/50 hover:bg-slate-800 border border-slate-700/50 hover:border-slate-600 rounded-xl p-1.5 pl-4 transition-all group"
                        >
                            <div className="text-right hidden sm:block">
                                <p className="text-xs font-bold text-white leading-tight group-hover:text-cyan-400 transition-colors">
                                    {user?.firstName || "Admin"} {user?.lastName}
                                </p>
                                <p className="text-[10px] text-slate-400 font-mono leading-tight">Yönetici</p>
                            </div>
                            <div className="w-9 h-9 bg-linear-to-tr from-purple-600 to-pink-600 rounded-lg flex items-center justify-center text-white font-bold text-sm shadow-inner ring-2 ring-slate-900 group-hover:ring-slate-700 transition-all">
                                {user?.firstName?.charAt(0) || "A"}
                            </div>
                        </button>

                        {isProfileOpen && (
                            <>
                                <div className="fixed inset-0 z-10" onClick={() => setIsProfileOpen(false)}></div>
                                <div className="absolute right-0 mt-2 w-56 bg-slate-900 border border-slate-800 rounded-xl shadow-xl z-20 py-1 overflow-hidden animate-in fade-in zoom-in-95 duration-200">

                                    {/* User Info Header */}
                                    <div className="px-4 py-3 border-b border-slate-800/50 bg-slate-800/20">
                                        <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-0.5">Aktif Hesap</p>
                                        <p className="text-sm font-bold text-white truncate">{user?.email || "admin@kripteks.com"}</p>
                                    </div>

                                    {/* Menu Items */}
                                    <div className="p-1.5 flex flex-col gap-0.5">
                                        <button onClick={() => { setSettingsTab('api'); setIsSettingsOpen(true); setIsProfileOpen(false); }} className="w-full text-left px-3 py-2 text-xs font-medium text-slate-300 hover:bg-slate-800 hover:text-white rounded-lg flex items-center gap-2.5 transition-colors">
                                            <div className="p-1 bg-blue-500/10 rounded text-blue-400"><Key size={14} /></div>
                                            API Bağlantıları
                                        </button>

                                        <button onClick={() => { setSettingsTab('general'); setIsSettingsOpen(true); setIsProfileOpen(false); }} className="w-full text-left px-3 py-2 text-xs font-medium text-slate-300 hover:bg-slate-800 hover:text-white rounded-lg flex items-center gap-2.5 transition-colors">
                                            <div className="p-1 bg-cyan-500/10 rounded text-cyan-400"><Settings size={14} /></div>
                                            Sistem Ayarları
                                        </button>

                                        <button onClick={() => { setSettingsTab('users'); setIsSettingsOpen(true); setIsProfileOpen(false); }} className="w-full text-left px-3 py-2 text-xs font-medium text-slate-300 hover:bg-slate-800 hover:text-white rounded-lg flex items-center gap-2.5 transition-colors">
                                            <div className="p-1 bg-purple-500/10 rounded text-purple-400"><User size={14} /></div>
                                            Kullanıcı Yönetimi
                                        </button>

                                        <button onClick={() => { setIsLogsOpen(true); setIsProfileOpen(false); }} className="w-full text-left px-3 py-2 text-xs font-medium text-slate-300 hover:bg-slate-800 hover:text-white rounded-lg flex items-center gap-2.5 transition-colors">
                                            <div className="p-1 bg-orange-500/10 rounded text-orange-400"><Database size={14} /></div>
                                            Sistem Logları
                                        </button>
                                    </div>

                                    {/* Logout */}
                                    <div className="border-t border-slate-800/50 p-1.5 mt-1">
                                        <button onClick={handleLogout} className="w-full text-left px-3 py-2 text-xs font-bold text-red-400 hover:bg-red-500/10 hover:text-red-300 rounded-lg flex items-center gap-2.5 transition-colors">
                                            <div className="p-1 bg-red-500/10 rounded"><LogOut size={14} /></div>
                                            Çıkış Yap
                                        </button>
                                    </div>
                                </div>
                            </>
                        )}
                    </div>
                </div>
            </div>



            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">

                {/* LEFT COLUMN - CREATE BOT */}
                <div className="lg:col-span-4 space-y-6 lg:sticky lg:top-24 h-fit">
                    <div className="bg-slate-800/50 backdrop-blur-xl border border-slate-700/50 rounded-3xl p-6 shadow-xl relative overflow-hidden">
                        <div className="absolute top-0 right-0 w-32 h-32 bg-cyan-500/10 rounded-full blur-3xl -mr-16 -mt-16 pointer-events-none"></div>

                        <h2 className="text-lg font-bold text-white mb-6 flex items-center gap-2">
                            <Play className="w-5 h-5 text-cyan-400 fill-cyan-400/20" />
                            Yeni Bot Başlat
                        </h2>

                        <div className="space-y-5">
                            <div>
                                <label className="block text-xs font-semibold text-slate-400 mb-2 uppercase tracking-wider">Kripto Varlık</label>
                                <SearchableSelect options={coins.map(c => ({ id: c.symbol, label: c.symbol, ...c }))} value={selectedCoin} onChange={setSelectedCoin} placeholder="Coin Ara..." onOpen={refreshCoins} isLoading={isCoinsLoading} />
                            </div>
                            <div className="flex gap-4">
                                <div className="w-3/4">
                                    <label className="block text-xs font-semibold text-slate-400 mb-2 uppercase tracking-wider">İşlem Stratejisi</label>
                                    <div className="relative">
                                        <select
                                            className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-slate-200 outline-none focus:border-purple-500 focus:ring-1 focus:ring-purple-500 transition-all appearance-none pr-10"
                                            value={selectedStrategy}
                                            onChange={(e) => setSelectedStrategy(e.target.value)}
                                        >
                                            {strategies.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                                        </select>
                                        <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none w-4 h-4" />
                                    </div>
                                </div>
                                <div className="w-1/4">
                                    <label className="block text-xs font-semibold text-slate-400 mb-2 uppercase tracking-wider">Grafik</label>
                                    <div className="relative">
                                        <select
                                            className="w-full bg-slate-900/50 border border-slate-700 rounded-xl pl-3 pr-8 py-3 text-slate-200 outline-none focus:border-cyan-500 focus:ring-1 focus:ring-cyan-500 transition-all appearance-none font-mono text-sm"
                                            value={selectedInterval}
                                            onChange={(e) => setSelectedInterval(e.target.value)}
                                        >
                                            <option value="1m">1m</option>
                                            <option value="3m">3m</option>
                                            <option value="5m">5m</option>
                                            <option value="15m">15m</option>
                                            <option value="30m">30m</option>
                                            <option value="1h">1h</option>
                                            <option value="2h">2h</option>
                                            <option value="4h">4h</option>
                                            <option value="1d">1d</option>
                                        </select>
                                        <ChevronDown className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none w-4 h-4" />
                                    </div>
                                </div>
                            </div>
                            <div>
                                <div className="flex justify-between items-center mb-2">
                                    <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">İşlem Miktarı (USDT)</label>
                                    {wallet && (<span className={`text-[10px] font-mono ${isInsufficientBalance ? 'text-red-400' : 'text-slate-500'}`}> Kullanılabilir: <span className="text-white font-bold">${wallet.available_balance?.toLocaleString('en-US', { maximumFractionDigits: 2 })}</span> </span>)}
                                </div>
                                <div className="relative">
                                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 font-bold">$</span>
                                    <input type="number" value={amount} onChange={(e) => setAmount(Number(e.target.value))} className={`w-full bg-slate-900/50 border rounded-xl pl-8 pr-4 py-3 text-white font-mono focus:ring-1 transition-all outline-none ${isInsufficientBalance ? 'border-red-500 focus:border-red-500 focus:ring-red-500' : 'border-slate-700 focus:border-cyan-500 focus:ring-cyan-500'}`} />
                                </div>
                                <div className="flex gap-2 mt-2"> {[25, 50, 75, 100].map(p => (<button key={p} onClick={() => setAmountByPercent(p)} className="flex-1 bg-slate-700/30 hover:bg-slate-700 text-xs py-1 rounded text-slate-400 hover:text-white transition-colors">%{p}</button>))} </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div> <label className="block text-[10px] font-bold text-green-500/80 mb-2 uppercase tracking-wider">Kar Al (%)</label> <input type="number" placeholder="Opsiyonel" className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-slate-200 text-sm outline-none focus:border-green-500 transition-all" value={takeProfit} onChange={(e) => setTakeProfit(e.target.value)} /> </div>
                                <div> <label className="block text-[10px] font-bold text-red-500/80 mb-2 uppercase tracking-wider">Zarar Durdur (%)</label> <input type="number" placeholder="Opsiyonel" className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-slate-200 text-sm outline-none focus:border-red-500 transition-all" value={stopLoss} onChange={(e) => setStopLoss(e.target.value)} /> </div>
                            </div>
                            <div className="pt-2">
                                <button onClick={handleStartBot} disabled={shouldDisableButton} className={`w-full font-bold py-4 rounded-xl shadow-lg active:scale-[0.98] transition-all flex justify-center items-center gap-2 ${shouldDisableButton ? 'bg-slate-700 text-slate-400 cursor-not-allowed opacity-50' : 'bg-linear-to-r from-cyan-600 to-blue-600 hover:from-cyan-500 hover:to-blue-500 text-white shadow-cyan-500/20'}`}> {isStarting ? (<Loader2 className="animate-spin w-5 h-5" />) : (<>Başlat <TrendingUp className="w-5 h-5" /></>)} </button>
                                {isInsufficientBalance && !isImmediate && (<p className="text-center text-[10px] text-yellow-500 mt-2"> ⚠️ Bakiye yetersiz, işlem sırası gelince kontol edilecek. </p>)}
                                {isImmediate && isInsufficientBalance && (<p className="text-center text-xs text-red-500 mt-2 font-medium"> YETERSİZ BAKİYE ⚠️ </p>)}
                            </div>
                        </div>
                    </div>
                </div>

                {/* RIGHT COLUMN - TABS & CONTENT */}
                <div className="lg:col-span-8">

                    {/* STATS GRID (MOVED HERE) */}
                    {stats && wallet && (
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
                            {/* Aktif */}
                            <div className="bg-slate-800/40 border border-slate-700/50 p-4 rounded-2xl flex flex-col justify-center relative overflow-hidden group hover:border-green-500/30 transition-all">
                                <div className="absolute top-0 right-0 p-3 opacity-10 group-hover:opacity-20 transition-opacity"> <Activity size={32} className="text-green-500" /> </div>
                                <span className="text-green-500/70 text-xs font-bold uppercase tracking-wider mb-1">Aktif Botlar</span>
                                <span className="text-2xl font-bold text-white font-mono">{stats.active_bots}</span>
                            </div>

                            {/* Bakiye */}
                            <div onClick={() => setIsWalletModalOpen(true)} className="bg-slate-800/40 border border-slate-700/50 p-4 rounded-2xl flex flex-col justify-center cursor-pointer hover:bg-slate-800/60 transition-colors group relative overflow-hidden">
                                <div className="absolute top-0 right-0 p-3 opacity-10 group-hover:opacity-20 transition-opacity"> <WalletIcon size={32} className="text-white" /> </div>
                                <span className="text-slate-500 text-xs font-bold uppercase tracking-wider mb-1 flex items-center gap-2"> Toplam Bakiye <ChevronDown size={12} /> </span>
                                <span className="text-2xl font-bold text-white font-mono flex items-center gap-2"> ${wallet.current_balance?.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} </span>
                            </div>

                            {/* Hacim */}
                            <div className="bg-slate-800/40 border border-slate-700/50 p-4 rounded-2xl flex flex-col justify-center relative overflow-hidden group hover:border-cyan-500/30 transition-all">
                                <div className="absolute top-0 right-0 p-3 opacity-10 group-hover:opacity-20 transition-opacity"> <BarChart2 size={32} className="text-cyan-500" /> </div>
                                <span className="text-cyan-500/70 text-xs font-bold uppercase tracking-wider mb-1">Toplam Hacim</span>
                                <span className="text-2xl font-bold text-white font-mono">${stats.total_volume}</span>
                            </div>
                        </div>
                    )}

                    {/* TAB NAVIGATION */}
                    <div className="bg-slate-900/50 p-1.5 rounded-2xl flex gap-1 mb-6 border border-slate-800 w-fit">
                        <button
                            onClick={() => setActiveTab('active')}
                            className={`px-5 py-2.5 rounded-xl text-sm font-semibold transition-all flex items-center gap-2 ${activeTab === 'active' ? 'bg-slate-700 text-white shadow-lg shadow-black/20' : 'text-slate-400 hover:text-white hover:bg-slate-800'}`}
                        >
                            Aktif Botlar
                            <span className="bg-cyan-500 text-black text-[10px] font-bold px-1.5 py-0.5 rounded ml-1">{activeBots.length}</span>
                        </button>
                        <button
                            onClick={() => setActiveTab('history')}
                            className={`px-5 py-2.5 rounded-xl text-sm font-semibold transition-all flex items-center gap-2 ${activeTab === 'history' ? 'bg-slate-700 text-white shadow-lg shadow-black/20' : 'text-slate-400 hover:text-white hover:bg-slate-800'}`}
                        >
                            Geçmiş İşlemler
                        </button>
                        <button
                            onClick={() => setActiveTab('backtest')}
                            className={`px-5 py-2.5 rounded-xl text-sm font-semibold transition-all flex items-center gap-2 ${activeTab === 'backtest' ? 'bg-slate-700 text-white shadow-lg shadow-black/20' : 'text-slate-400 hover:text-white hover:bg-slate-800'}`}
                        >
                            <FlaskConical size={16} />
                            Backtest (Simülasyon)
                        </button>
                        <button
                            onClick={() => setActiveTab('analytics')}
                            className={`px-5 py-2.5 rounded-xl text-sm font-semibold transition-all flex items-center gap-2 ${activeTab === 'analytics' ? 'bg-slate-700 text-white shadow-lg shadow-black/20' : 'text-slate-400 hover:text-white hover:bg-slate-800'}`}
                        >
                            <BarChart2 size={16} />
                            Raporlar
                        </button>
                    </div>

                    {/* CONTENT AREA */}
                    <div className="space-y-4 min-h-[500px]">
                        <AnimatePresence mode="wait">

                            {/* ACTIVE BOTS TAB */}
                            {activeTab === 'active' && (
                                <motion.div key="active" initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -10 }}>
                                    {activeBots.length === 0 ? (
                                        <div className="flex flex-col items-center justify-center py-20 bg-slate-800/20 border border-slate-700/50 rounded-3xl border-dashed h-96">
                                            <div className="w-16 h-16 bg-slate-800 rounded-full flex items-center justify-center mb-4">
                                                <Activity className="text-slate-600" size={32} />
                                            </div>
                                            <h3 className="text-white font-bold text-lg mb-2">Henüz aktif bot yok</h3>
                                            <p className="text-slate-500 text-sm max-w-md text-center">
                                                Sol taraftaki panelden yeni bir bot başlatarak otomatik al-sat işlemlerine başlayabilirsiniz.
                                            </p>
                                        </div>
                                    ) : (
                                        activeBots.map((bot) => (
                                            <BotCard key={bot.id} bot={bot} isActive={true} activeChartBotId={activeChartBotId} setActiveChartBotId={setActiveChartBotId} handleStopBot={handleStopBot} />
                                        ))
                                    )}
                                </motion.div>
                            )}

                            {/* HISTORY BOTS TAB */}
                            {activeTab === 'history' && (
                                <motion.div key="history" initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -10 }}>
                                    {historyBots.length === 0 ? (
                                        <div className="flex flex-col items-center justify-center py-20 bg-slate-800/20 border border-slate-700/50 rounded-3xl border-dashed h-96">
                                            <History className="text-slate-600 mb-4" size={48} />
                                            <h3 className="text-white font-bold text-lg mb-2">Geçmiş işlem bulunamadı</h3>
                                            <p className="text-slate-500 text-sm">Tamamlanan bot işlemleri burada listelenir.</p>
                                        </div>
                                    ) : (
                                        historyBots.map((bot) => (
                                            <BotCard key={bot.id} bot={bot} isActive={false} activeChartBotId={activeChartBotId} setActiveChartBotId={setActiveChartBotId} handleStopBot={handleStopBot} />
                                        ))
                                    )}
                                </motion.div>
                            )}

                            {/* BACKTEST TAB */}
                            {activeTab === 'backtest' && (
                                <motion.div key="backtest" initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -10 }}>
                                    <BacktestPanel coins={coins} strategies={strategies} />
                                </motion.div>
                            )}

                            {/* ANALYTICS TAB */}
                            {activeTab === 'analytics' && (
                                <motion.div key="analytics" initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -10 }}>
                                    <AnalyticsDashboard />
                                </motion.div>
                            )}

                        </AnimatePresence>
                    </div>
                </div>

            </div>

            <WalletModal isOpen={isWalletModalOpen} onClose={() => setIsWalletModalOpen(false)}
            />

            <SettingsModal
                isOpen={isSettingsOpen}
                onClose={() => setIsSettingsOpen(false)}
                activeTab={settingsTab}
            />

            <LogsDrawer
                isOpen={isLogsOpen}
                onClose={() => setIsLogsOpen(false)}
            />
        </main>
    );
}

// Bot Card Component
function BotCard({ bot, isActive, activeChartBotId, setActiveChartBotId, handleStopBot }: any) {
    return (
        <motion.div
            layout
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95 }}
            className={`border rounded-2xl overflow-hidden transition-all group ${isActive ? 'bg-slate-800/60 backdrop-blur-md border-slate-700/50 hover:border-slate-600' : 'bg-slate-900/40 border-slate-800 opacity-80 hover:opacity-100'}`}
        >
            <div className="p-5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-5">

                <div className="flex items-center gap-4">
                    <div className={`w-12 h-12 rounded-2xl flex items-center justify-center text-lg font-bold shadow-inner ${bot.status === 'Running'
                        ? 'bg-linear-to-br from-cyan-500/20 to-blue-500/10 text-cyan-400 border border-cyan-500/20'
                        : 'bg-slate-700/30 text-slate-500 border border-slate-700'
                        }`}>
                        {bot.symbol.substring(0, 1)}
                    </div>

                    <div>
                        <div className="flex items-center gap-2">
                            <h3 className="text-white font-bold text-lg">{bot.symbol}</h3>
                            <div className="flex items-center gap-1.5">
                                <span className="text-[10px] bg-slate-800 border border-slate-700 px-2 py-0.5 rounded-md text-slate-400 font-medium">{bot.strategyName}</span>
                                <span className="text-[10px] bg-cyan-500/10 border border-cyan-500/20 px-2 py-0.5 rounded-md text-cyan-400 font-bold font-mono uppercase">{bot.interval}</span>
                            </div>
                        </div>
                        <div className="flex items-center gap-3 text-xs text-slate-400 mt-1">
                            <span className="font-mono flex items-center gap-1"><DollarSign size={10} /> {bot.amount}</span>
                            <span>•</span>
                            <span>{new Date(bot.createdAt).toLocaleString()}</span>
                        </div>
                    </div>
                </div>

                {/* TP/SL Progress Bar */}
                {isActive && <div className="flex-1 px-4 hidden sm:block">
                    {(bot.takeProfit || bot.stopLoss) && (
                        <div className="flex flex-col gap-1.5 max-w-[200px] ml-auto mr-4">
                            {/* TP Bar */}
                            {bot.takeProfit && (
                                <div className="relative h-1.5 bg-slate-700 rounded-full overflow-hidden">
                                    <div className="absolute top-0 left-0 h-full bg-green-500/80 shadow-[0_0_8px_rgba(34,197,94,0.5)] transition-all duration-700 ease-out" style={{ width: `${Math.min(Math.max(0, bot.pnlPercent) / bot.takeProfit * 100, 100)}%` }} />
                                </div>
                            )}
                            {bot.stopLoss && bot.pnlPercent < 0 && (
                                <div className="relative h-1.5 bg-slate-700 rounded-full overflow-hidden">
                                    <div className="absolute top-0 left-0 h-full bg-red-500/80 shadow-[0_0_8px_rgba(239,68,68,0.5)] transition-all duration-700 ease-out" style={{ width: `${Math.min(Math.abs(bot.pnlPercent) / bot.stopLoss * 100, 100)}%` }} />
                                </div>
                            )}
                            <div className="flex justify-between text-[9px] text-slate-500 font-mono uppercase tracking-wider">
                                <span>Hedef: %{bot.takeProfit || '-'}</span>
                                {bot.stopLoss && <span>Stop: %{bot.stopLoss}</span>}
                            </div>
                        </div>
                    )}
                </div>}


                <div className="flex items-center gap-4 w-full sm:w-auto justify-between sm:justify-end">

                    {/* PNL Badge */}
                    <div className={`flex flex-col items-end px-3 py-1 rounded-lg border ${bot.pnl >= 0 ? 'bg-green-500/10 border-green-500/20' : 'bg-red-500/10 border-red-500/20'
                        }`}>
                        <span className={`text-sm font-bold font-mono ${bot.pnl >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                            {bot.pnl >= 0 ? '+' : ''}{bot.pnl?.toFixed(2)}$
                        </span>
                        <span className={`text-[10px] font-bold ${bot.pnl >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                            %{bot.pnlPercent?.toFixed(2)}
                        </span>
                    </div>

                    {/* Status Badge */}
                    <div className={`flex items-center gap-2 px-3 py-1.5 rounded-lg border text-xs font-semibold ${bot.status === 'Running' ? 'bg-blue-500/10 border-blue-500/20 text-blue-400'
                        : bot.status === 'WaitingForEntry' ? 'bg-yellow-500/10 border-yellow-500/20 text-yellow-500'
                            : bot.status === 'Completed' ? 'bg-green-500/10 border-green-500/20 text-green-400'
                                : 'bg-slate-700/50 border-slate-600 text-slate-400'
                        }`}>
                        <div className={`w-1.5 h-1.5 rounded-full ${bot.status === 'Running' ? 'bg-blue-500 animate-pulse'
                            : bot.status === 'WaitingForEntry' ? 'bg-yellow-500 animate-pulse'
                                : bot.status === 'Completed' ? 'bg-green-500'
                                    : 'bg-slate-500'}`}></div>

                        {bot.status === 'Running' ? 'Çalışıyor'
                            : bot.status === 'WaitingForEntry' ? 'Sinyal Bekliyor'
                                : bot.status === 'Completed' ? 'Tamamlandı'
                                    : 'Durduruldu'}
                    </div>

                    <div className="flex gap-2">
                        <button onClick={() => setActiveChartBotId(activeChartBotId === bot.id ? null : bot.id)} className={`p-2.5 rounded-xl border transition-all ${activeChartBotId === bot.id ? 'bg-indigo-500 text-white border-indigo-500' : 'bg-indigo-500/10 text-indigo-400 border-indigo-500/20 hover:bg-indigo-500 hover:text-white'}`}> <Activity className="w-4 h-4" /> </button>
                        {isActive && (
                            <button onClick={() => handleStopBot(bot.id)} className="p-2.5 rounded-xl bg-red-500/10 text-red-400 border border-red-500/20 hover:bg-red-500 hover:text-white transition-all active:scale-95" title="Botu Durdur"> <Square className="w-4 h-4 fill-current" /> </button>
                        )}
                    </div>
                </div>
            </div>

            {/* LOGS & CHART */}
            {(isActive || activeChartBotId === bot.id) && (
                <>
                    <BotLogs logs={bot.logs || []} compact={!isActive} /> {/* Historyde compact log */}
                    <AnimatePresence>
                        {activeChartBotId === bot.id && (
                            <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} exit={{ height: 0, opacity: 0 }} className="px-5 pb-5 border-t border-slate-700/50 bg-slate-900/30">
                                <TradingViewWidget symbol={bot.symbol} strategy={bot.strategyName} />
                            </motion.div>
                        )}
                    </AnimatePresence>
                </>
            )}
        </motion.div>
    );
}
