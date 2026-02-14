"use client";

import React, { useState, useMemo, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ScannerService, MarketService } from "@/lib/api";
import { toast } from "sonner";
import {
    Search, PlayCircle, TrendingUp, Activity, Info,
    Zap, Loader2, CheckCircle2, XCircle, BarChart3, Clock,
    Gauge, Target, History, RefreshCw, Filter, Trash2, Edit2, ListPlus, Volume2, VolumeX
} from "lucide-react";
import { Coin, Strategy, ScannerResultItem, ScannerFavoriteList } from "@/types";
import { InfoTooltip } from "@/components/dashboard/InfoTooltip";
import FavoriteListModal from "./FavoriteListModal";
import { ScannerResultDetailModal } from "./ScannerResultDetailModal";
import { StrategyDetailModal } from "./StrategyDetailModal";
import { QuickBuyModal } from "./QuickBuyModal";

export default function ScannerDashboard() {
    const [coins, setCoins] = useState<Coin[]>([]);
    const [strategies, setStrategies] = useState<Strategy[]>([]);
    const [selectedSymbols, setSelectedSymbols] = useState<string[]>([]);
    const [interval, setInterval] = useState("1h");
    const [strategy, setStrategy] = useState("");
    const [loading, setLoading] = useState(false);
    const [selectedDetailResult, setSelectedDetailResult] = useState<ScannerResultItem | null>(null);
    const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);
    const [isInitialLoading, setIsInitialLoading] = useState(true);
    const [results, setResults] = useState<ScannerResultItem[]>([]);
    const [searchTerm, setSearchTerm] = useState("");
    const [minScore, setMinScore] = useState(50);
    const [hasScanned, setHasScanned] = useState(false);

    // Favorite List States
    const [favoriteLists, setFavoriteLists] = useState<ScannerFavoriteList[]>([]);
    const [selectedListId, setSelectedListId] = useState<string | null>(null);
    const [isFavoriteModalOpen, setIsFavoriteModalOpen] = useState(false);
    const [editingList, setEditingList] = useState<ScannerFavoriteList | null>(null);
    const [isSettingsOpen, setIsSettingsOpen] = useState(false);
    const [isStrategyDetailOpen, setIsStrategyDetailOpen] = useState(false);
    const [isQuickBuyOpen, setIsQuickBuyOpen] = useState(false);
    const [quickBuyItem, setQuickBuyItem] = useState<ScannerResultItem | null>(null);

    // Auto Scan States
    const [autoScanInterval, setAutoScanInterval] = useState<number>(0);
    const [nextScanTime, setNextScanTime] = useState<Date | null>(null);
    const [timeLeft, setTimeLeft] = useState<number>(0);


    const [isSoundEnabled, setIsSoundEnabled] = useState(false);

    // Ref ile güncel state'i takip et (Stale closure fix)
    const isSoundEnabledRef = React.useRef(isSoundEnabled);
    const autoScanIntervalRef = React.useRef(autoScanInterval);

    useEffect(() => {
        isSoundEnabledRef.current = isSoundEnabled;
    }, [isSoundEnabled]);

    useEffect(() => {
        autoScanIntervalRef.current = autoScanInterval;
    }, [autoScanInterval]);

    const playNotificationSound = () => {
        const audio = new Audio("https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3");
        audio.play().catch(e => console.error("Audio play failed", e));
    };


    const loadData = async () => {
        try {
            const [coinsData, strData, favData] = await Promise.all([
                MarketService.getCoins(),
                MarketService.getStrategies(),
                ScannerService.getFavorites()
            ]);
            setCoins(coinsData || []);
            // Filter only scanner and both categories for scanner dashboard
            const scannerStrategies = (strData || []).filter(
                (s: Strategy) => s.category === 'scanner' || s.category === 'both'
            );
            setStrategies(scannerStrategies);
            setFavoriteLists(favData || []);
        } catch (error) {
            toast.error("Veriler yüklenemedi");
        } finally {
            setIsInitialLoading(false);
        }
    };

    useEffect(() => {
        loadData();
    }, []);

    useEffect(() => {
        if (strategies.length > 0 && !strategy) {
            setStrategy(strategies[0].id);
        }
    }, [strategies, strategy]);


    const filteredCoins = useMemo(() => {
        const filtered = coins.filter(c => c.symbol.toLowerCase().includes(searchTerm.toLowerCase()));
        return [...filtered].sort((a, b) => {
            const aSelected = selectedSymbols.includes(a.symbol);
            const bSelected = selectedSymbols.includes(b.symbol);
            if (aSelected && !bSelected) return -1;
            if (!aSelected && bSelected) return 1;
            return 0;
        });
    }, [coins, searchTerm, selectedSymbols]);

    const handleToggleSymbol = (symbol: string) => {
        setSelectedSymbols(prev =>
            prev.includes(symbol) ? prev.filter(s => s !== symbol) : [...prev, symbol]
        );
    };

    const handleRunScanner = async (isAuto = false) => {
        if (!strategy) {
            if (!isAuto) toast.error("Lütfen bir strateji seçiniz");
            return;
        }

        console.log("[DEBUG] Scanner Started. Strategy:", strategy, "IsAuto:", isAuto, "Symbols:", selectedSymbols.length);

        if (!isAuto) setLoading(true);
        // Silent loading için sonuçları temizlemiyoruz
        if (!isAuto) setResults([]);

        try {
            const data = await ScannerService.scan({
                symbols: selectedSymbols,
                interval,
                strategyId: strategy,
                minScore: minScore > 0 ? minScore : undefined
            });

            console.log("[DEBUG] Scanner Results:", data);

            if (data && data.results) {
                setResults(data.results);
                setHasScanned(true);
                if (!isAuto) toast.success("Tarama Tamamlandı", { description: `${data.results.length} parite analiz edildi.` });

                // Otomatik taramada sesli bildirim kontrolü
                // Ref değerini kullanıyoruz çünkü handleRunScanner stale closure içinde kalabilir
                if (isAuto && isSoundEnabledRef.current) {
                    const hasHighScores = data.results.some((r: any) => {
                        const score = r.signalScore ?? r.SignalScore ?? 0;
                        return score >= 80;
                    });

                    if (hasHighScores) {
                        playNotificationSound();
                        toast.success("Yüksek Skorlu Fırsat Yakalandı!", {
                            description: "Otomatik tarama sonucunda >80 puanlı coinler bulundu.",
                            duration: 5000
                        });
                    }
                }
            } else {
                console.warn("[DEBUG] No results in response:", data);
            }
        } catch (error: any) {
            console.error("[DEBUG] Scanner Error:", error);
            if (!isAuto) toast.error("Hata", { description: error.message || "Bağlantı hatası oluştu." });
        } finally {
            if (!isAuto) setLoading(false);

            // Otomatik tarama aktifse, işlem bittikten sonra sayacı yeniden başlat
            // Böylece tarama süresi, bekleme süresine dahil edilmez
            // Otomatik tarama aktifse, işlem bittikten sonra sayacı yeniden başlat
            // Ref'ten güncel interval değerini al
            if (autoScanIntervalRef.current > 0) {
                const newNextTime = new Date(Date.now() + autoScanIntervalRef.current);
                setNextScanTime(newNextTime);
                setTimeLeft(Math.ceil(autoScanIntervalRef.current / 1000));
            }
        }
    };

    useEffect(() => {
        // Interval kapalıysa hiçbir şey yapma
        if (autoScanInterval === 0) {
            setNextScanTime(null);
            setTimeLeft(0);
            return;
        }

        const timer = window.setInterval(() => {
            // Eğer bir sonraki tarama zamanı belirlenmemişse, hiçbir şey yapma (bekle)
            // handleRunScanner bitince nextScanTime set edilecek
            if (!nextScanTime) return;

            const now = new Date();
            const diff = nextScanTime.getTime() - now.getTime();

            // Süre bitti, tarama zamanı geldi
            if (diff <= 0) {
                // Sayacı durdur (nextScanTime null yaparak)
                setNextScanTime(null);
                // Taramayı başlat
                handleRunScanner(true);
            } else {
                // Sadece sayacı güncelle
                setTimeLeft(Math.ceil(diff / 1000));
            }
        }, 1000);

        return () => window.clearInterval(timer);
    }, [autoScanInterval, nextScanTime, strategy, selectedSymbols]);

    const displayResults = useMemo(() => {
        return results.filter(r => {
            const score = r.signalScore ?? (r as any).SignalScore ?? 0;
            return score >= minScore;
        });
    }, [results, minScore]);

    if (isInitialLoading) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[400px] gap-4">
                <Loader2 className="w-10 h-10 animate-spin text-primary" />
                <p className="text-slate-500 animate-pulse">Piyasa verileri hazırlanıyor...</p>
            </div>
        );
    }

    const currentStrategy = strategies.find(s => s.id === strategy);

    return (
        <div className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                {/* Sol Panel - Kontroller */}
                <div className="lg:col-span-4">
                    <div className="glass-card p-6 rounded-3xl border border-white/10 space-y-6 sticky top-24">
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="p-2 bg-primary/10 rounded-xl text-primary border border-primary/20">
                                    <Target size={18} />
                                </div>
                                <h3 className="font-bold text-white uppercase tracking-wider text-sm">Tarayıcı Ayarları</h3>
                            </div>
                        </div>

                        {/* Combined Accordion */}
                        <div className="space-y-2">
                            <button
                                onClick={() => setIsSettingsOpen(!isSettingsOpen)}
                                className={`w-full flex items-center justify-between p-4 rounded-2xl transition-all border ${isSettingsOpen ? "bg-primary/10 border-primary/20 shadow-[0_0_20px_rgba(var(--primary-rgb),0.1)]" : "bg-white/2 border-white/5 hover:bg-white/5"
                                    }`}
                            >
                                <div className="flex items-center gap-3">
                                    <div className={`p-2 rounded-xl ${isSettingsOpen ? "bg-primary text-white" : "bg-white/5 text-slate-500"}`}>
                                        <ListPlus size={16} />
                                    </div>
                                    <div className="flex flex-col items-start">
                                        <span className={`text-xs uppercase font-black tracking-widest ${isSettingsOpen ? "text-white" : "text-slate-400"}`}>
                                            Parite ve Liste Seçimi
                                        </span>
                                        <span className="text-[10px] text-slate-500 font-bold">
                                            {selectedSymbols.length} Parite / {favoriteLists.length} Liste
                                        </span>
                                    </div>
                                </div>
                                <motion.div
                                    animate={{ rotate: isSettingsOpen ? 180 : 0 }}
                                    className="text-slate-500"
                                >
                                    <RefreshCw size={14} className={isSettingsOpen ? "" : "opacity-40"} />
                                </motion.div>
                            </button>

                            <AnimatePresence>
                                {isSettingsOpen && (
                                    <motion.div
                                        initial={{ height: 0, opacity: 0 }}
                                        animate={{ height: "auto", opacity: 1 }}
                                        exit={{ height: 0, opacity: 0 }}
                                        className="overflow-hidden"
                                    >
                                        <div className="p-4 space-y-6 bg-white/2 border border-white/5 rounded-[24px] mt-2">
                                            {/* Favori Listelerim Alt Bölüm */}
                                            <div className="space-y-3">
                                                <div className="flex items-center justify-between px-1">
                                                    <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-2">
                                                        <History size={12} /> Favori Listelerim
                                                    </label>
                                                    <button
                                                        onClick={(e) => { e.stopPropagation(); setEditingList(null); setIsFavoriteModalOpen(true); }}
                                                        className="text-[9px] text-primary hover:text-primary-light font-black uppercase"
                                                    >
                                                        + YENİ
                                                    </button>
                                                </div>

                                                {favoriteLists.length > 0 ? (
                                                    <div className="space-y-2 max-h-32 overflow-y-auto pr-1 custom-scrollbar">
                                                        {favoriteLists.map(list => (
                                                            <div
                                                                key={list.id}
                                                                className={`group flex items-center justify-between p-2.5 rounded-xl border transition-all cursor-pointer ${selectedListId === list.id
                                                                    ? "bg-primary/20 border-primary/40"
                                                                    : "bg-white/5 border-white/5 hover:bg-white/10"
                                                                    }`}
                                                                onClick={() => {
                                                                    console.log("[DEBUG] Selected List:", list.name, "Symbols:", list.symbols);
                                                                    setSelectedListId(list.id);
                                                                    setSelectedSymbols(list.symbols);
                                                                }}
                                                            >
                                                                <div className="flex items-center gap-2 min-w-0">
                                                                    <div className={`w-1.5 h-1.5 rounded-full ${selectedListId === list.id ? "bg-primary" : "bg-slate-600"}`} />
                                                                    <span className={`text-[11px] font-bold truncate ${selectedListId === list.id ? "text-white" : "text-slate-400"}`}>
                                                                        {list.name}
                                                                    </span>
                                                                </div>
                                                                <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                                                    <button
                                                                        onClick={(e) => {
                                                                            e.stopPropagation();
                                                                            setEditingList(list);
                                                                            setIsFavoriteModalOpen(true);
                                                                        }}
                                                                        className="p-1 hover:bg-white/10 rounded text-slate-500 hover:text-white"
                                                                    >
                                                                        <Edit2 size={10} />
                                                                    </button>
                                                                </div>
                                                            </div>
                                                        ))}
                                                    </div>
                                                ) : (
                                                    <p className="text-[10px] text-slate-600 text-center py-2 italic">Liste bulunamadı</p>
                                                )}
                                            </div>

                                            <div className="h-px bg-white/5" />

                                            {/* Parite Seçimi Alt Bölüm */}
                                            <div className="space-y-3">
                                                <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-2">
                                                    <Filter size={12} /> Manuel Parite Seçimi
                                                </label>
                                                <div className="relative">
                                                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 w-3.5 h-3.5" />
                                                    <input
                                                        type="text"
                                                        placeholder="Coin ara..."
                                                        value={searchTerm}
                                                        onChange={(e) => setSearchTerm(e.target.value)}
                                                        className="w-full bg-slate-950/40 border border-white/5 rounded-xl pl-9 pr-4 py-2 text-[11px] text-white focus:outline-none focus:border-primary/40"
                                                    />
                                                </div>
                                                <div className="max-h-40 overflow-y-auto pr-2 custom-scrollbar grid grid-cols-3 gap-1.5">
                                                    {filteredCoins.map(coin => (
                                                        <button
                                                            key={coin.symbol}
                                                            onClick={() => handleToggleSymbol(coin.symbol)}
                                                            className={`px-2 py-1.5 rounded-lg text-[9px] font-bold text-center transition-all border ${selectedSymbols.includes(coin.symbol)
                                                                ? "bg-primary/20 text-primary border-primary/30"
                                                                : "bg-white/5 border-white/5 text-slate-500 hover:bg-white/10"
                                                                }`}
                                                        >
                                                            {coin.symbol.replace("USDT", "")}
                                                        </button>
                                                    ))}
                                                </div>
                                            </div>
                                        </div>
                                    </motion.div>
                                )}
                            </AnimatePresence>
                        </div>

                        <div className="h-px bg-white/5 mx-2" />

                        {/* Diğer Kontroller */}
                        <div className="space-y-4">
                            <div className="space-y-3">
                                <div className="space-y-2">
                                    <div className="flex items-center justify-between">
                                        <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-2">
                                            Strateji <span className="text-rose-400">*</span>
                                        </label>
                                        {strategy && (
                                            <button
                                                onClick={() => setIsStrategyDetailOpen(true)}
                                                className="flex items-center gap-1 px-2 py-1 rounded-lg bg-primary/10 hover:bg-primary/20 text-primary text-[9px] font-bold uppercase tracking-wider transition-all border border-primary/20"
                                            >
                                                <Info size={10} />
                                                Detay
                                            </button>
                                        )}
                                    </div>
                                    <select
                                        value={strategy}
                                        onChange={(e) => setStrategy(e.target.value)}
                                        className={`w-full bg-slate-950/40 border border-white/5 rounded-xl px-3 py-2.5 text-xs focus:outline-none cursor-pointer ${!strategy ? "text-slate-400" : "text-white focus:border-primary/40"}`}
                                    >
                                        <option value="" disabled>Strateji Seçiniz...</option>
                                        {strategies.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                                    </select>
                                </div>
                                <div className="space-y-2">
                                    <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-2">
                                        Zaman Dilimi
                                    </label>
                                    <select
                                        value={interval}
                                        onChange={(e) => setInterval(e.target.value)}
                                        className="w-full bg-slate-950/40 border border-white/5 rounded-xl px-3 py-2.5 text-xs text-white focus:outline-none focus:border-primary/40 cursor-pointer"
                                    >
                                        <option value="15m">15 Dakika</option>
                                        <option value="1h">1 Saat</option>
                                        <option value="4h">4 Saat</option>
                                        <option value="1d">1 Gün</option>
                                    </select>
                                </div>
                                <div className="space-y-2">
                                    <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-2">
                                        Min. Sinyal Skoru: {minScore}
                                    </label>
                                    <input
                                        type="range"
                                        min="0" max="100"
                                        value={minScore}
                                        onChange={(e) => setMinScore(parseInt(e.target.value))}
                                        className="w-full h-1.5 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-primary"
                                        style={{
                                            background: `linear-gradient(to right, #f59e0b 0%, #f59e0b ${minScore}%, #1e293b ${minScore}%, #1e293b 100%)`
                                        }}
                                    />
                                </div>

                                {/* Auto Scan UI */}
                                <div className="space-y-2">
                                    <div className="flex items-center justify-between">
                                        <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-2">
                                            <Clock size={12} /> Otomatik Tarama
                                        </label>
                                        {nextScanTime && (
                                            <span className="text-[10px] font-bold text-emerald-400 animate-pulse bg-emerald-500/10 px-1.5 py-0.5 rounded flex items-center gap-1">
                                                <span>{timeLeft}s</span>
                                            </span>
                                        )}
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <select
                                            value={autoScanInterval}
                                            onChange={(e) => {
                                                const val = parseInt(e.target.value);
                                                setAutoScanInterval(val);
                                                if (val === 0) {
                                                    setNextScanTime(null);
                                                    setTimeLeft(0);
                                                }
                                                else {
                                                    // Hemen başlatmak için süreyi şimdiye ayarla
                                                    // Timer döngüsü bunu yakalayıp taramayı başlatacak
                                                    setNextScanTime(new Date());
                                                }
                                            }}
                                            className={`w-full bg-slate-950/40 border border-white/5 rounded-xl px-3 py-2.5 text-xs focus:outline-none cursor-pointer ${autoScanInterval === 0 ? "text-slate-400" : "text-emerald-400 font-bold border-emerald-500/30 bg-emerald-500/10"}`}
                                        >
                                            <option value={0}>Kapalı (Manuel)</option>
                                            <option value={60000}>1 Dakika</option>
                                            <option value={180000}>3 Dakika</option>
                                            <option value={300000}>5 Dakika</option>
                                            <option value={900000}>15 Dakika</option>
                                            <option value={1800000}>30 Dakika</option>
                                            <option value={3600000}>1 Saat</option>
                                        </select>
                                        <button
                                            onClick={() => {
                                                const newState = !isSoundEnabled;
                                                setIsSoundEnabled(newState);
                                                if (newState) {
                                                    // Test sesi çal (Kullanıcı etkileşimi ile)
                                                    playNotificationSound();
                                                    toast.success("Sesli bildirimler açıldı");
                                                }
                                            }}
                                            className={`p-2.5 rounded-xl border transition-all ${isSoundEnabled
                                                ? "bg-primary/20 text-primary border-primary/30 shadow-[0_0_10px_rgba(var(--primary-rgb),0.2)]"
                                                : "bg-slate-950/40 border-white/5 text-slate-500 hover:text-white"
                                                }`}
                                            title="Sesli Bildirim"
                                        >
                                            {isSoundEnabled ? <Volume2 size={16} /> : <VolumeX size={16} />}
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <button
                                onClick={() => handleRunScanner(false)}
                                disabled={loading || !strategy}
                                className={`w-full py-4 rounded-2xl font-bold text-sm text-white shadow-lg transition-all active:scale-[0.98] flex items-center justify-center gap-3 disabled:opacity-50 disabled:cursor-not-allowed ${!strategy
                                    ? "bg-slate-700 shadow-none"
                                    : selectedSymbols.length === 0
                                        ? "bg-linear-to-r from-amber-600 to-orange-600 shadow-orange-900/20 hover:shadow-orange-900/40"
                                        : "bg-linear-to-r from-primary to-indigo-600 shadow-primary/20 hover:shadow-primary/40"
                                    }`}
                            >
                                {loading ? (
                                    <Loader2 className="w-5 h-5 animate-spin" />
                                ) : !strategy ? (
                                    <>
                                        <Target className="w-5 h-5" />
                                        <span>Strateji Seçiniz</span>
                                    </>
                                ) : (
                                    <>
                                        {selectedSymbols.length === 0 ? <Target className="w-5 h-5" /> : <RefreshCw className="w-5 h-5" />}
                                        <span>{selectedSymbols.length === 0 ? "Piyasa Taramasını Başlat" : "Seçili Pariteleri Tara"}</span>
                                    </>
                                )}
                            </button>
                        </div>
                    </div>
                </div>

                {/* Sağ Panel - Sonuçlar */}
                <div className="lg:col-span-8">
                    <div className="glass-card h-full min-h-[600px] rounded-3xl border border-white/10 overflow-hidden flex flex-col">
                        <div className="p-6 border-b border-white/5 flex items-center justify-between bg-white/2">
                            <div className="flex items-center gap-3">
                                <div className="p-2 bg-emerald-500/10 rounded-xl text-emerald-400 border border-emerald-500/20">
                                    <BarChart3 size={18} />
                                </div>
                                <h3 className="font-bold text-white uppercase tracking-wider text-sm">Alım Potansiyeli Olanlar</h3>
                            </div>
                            <div className="flex items-center gap-3">
                                <div className="px-3 py-1 bg-white/5 rounded-full text-[10px] font-mono text-slate-400 border border-white/5">
                                    {displayResults.length} Coin Bulundu
                                </div>
                                {results.length > 0 && (
                                    <button
                                        onClick={() => setResults([])}
                                        className="flex items-center gap-1.5 px-3 py-1 bg-rose-500/10 hover:bg-rose-500/20 rounded-full text-[10px] font-bold text-rose-400 border border-rose-500/20 transition-all uppercase tracking-wider"
                                    >
                                        <Trash2 size={12} /> Listeyi Temizle
                                    </button>
                                )}
                            </div>
                        </div>

                        <div className="flex-1 overflow-y-auto custom-scrollbar p-6">
                            {loading ? (
                                <div className="h-full flex flex-col items-center justify-center space-y-4">
                                    <div className="relative">
                                        <div className="absolute inset-0 bg-primary/20 blur-xl rounded-full animate-pulse" />
                                        <Loader2 size={48} className="text-primary animate-spin relative z-10" />
                                    </div>
                                    <div className="text-center space-y-2">
                                        <h4 className="text-white font-bold animate-pulse">Piyasa Taranıyor...</h4>
                                        <p className="text-xs text-slate-400">
                                            Seçilen kriterlere uygun fırsatlar analiz ediliyor.
                                            <br />
                                            Lütfen bekleyiniz.
                                        </p>
                                    </div>
                                </div>
                            ) : displayResults.length > 0 ? (
                                <div className="space-y-6">
                                    {/* Strateji Açıklama Kutusu */}
                                    <motion.div
                                        initial={{ opacity: 0, y: -10 }}
                                        animate={{ opacity: 1, y: 0 }}
                                        className="p-4 rounded-2xl bg-primary/5 border border-primary/10 flex items-start gap-3"
                                    >
                                        <div className="p-2 bg-primary/10 rounded-xl text-primary mt-1">
                                            <Info size={16} />
                                        </div>
                                        <div className="space-y-1">
                                            <h4 className="text-xs font-bold text-white uppercase tracking-tight">
                                                {currentStrategy?.name} Uygulanıyor
                                            </h4>
                                            <p className="text-[11px] text-slate-400 leading-relaxed">
                                                {currentStrategy?.description || "Bu liste, seçtiğiniz stratejinin teknik analiz kurallarına göre en yüksek alım puanına sahip pariteleri göstermektedir."}
                                            </p>
                                        </div>
                                    </motion.div>

                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                        <AnimatePresence mode="popLayout">
                                            {displayResults.map((item, idx) => {
                                                const res = {
                                                    symbol: item.symbol || (item as any).Symbol,
                                                    signalScore: item.signalScore ?? (item as any).SignalScore ?? 0,
                                                    suggestedAction: item.suggestedAction || (item as any).SuggestedAction || "None",
                                                    comment: item.comment || (item as any).Comment || "",
                                                    lastPrice: item.lastPrice ?? (item as any).LastPrice ?? 0
                                                };

                                                return (
                                                    <motion.div
                                                        key={res.symbol}
                                                        layout
                                                        initial={{ opacity: 0, scale: 0.9 }}
                                                        animate={{ opacity: 1, scale: 1 }}
                                                        exit={{ opacity: 0, scale: 0.9 }}
                                                        transition={{ duration: 0.2, delay: idx * 0.05 }}
                                                        onClick={() => {
                                                            setSelectedDetailResult(res as any);
                                                            setIsDetailModalOpen(true);
                                                        }}
                                                        className="p-5 rounded-2xl bg-white/3 border border-white/5 hover:border-primary/30 transition-all group relative cursor-pointer hover:z-20"
                                                    >
                                                        <div className="absolute inset-0 rounded-2xl overflow-hidden pointer-events-none">
                                                            <div className={`absolute -top-10 -right-10 w-32 h-32 blur-3xl opacity-10 transition-opacity group-hover:opacity-20 ${res.signalScore > 70 ? "bg-emerald-500" : res.signalScore > 40 ? "bg-amber-500" : "bg-rose-500"}`} />
                                                        </div>

                                                        <div className="flex justify-between items-start mb-4 relative z-10">
                                                            <div>
                                                                <h4 className="text-lg font-bold text-white group-hover:text-primary transition-colors">{res.symbol}</h4>
                                                                <div className="text-[10px] text-slate-500 font-mono mt-0.5">
                                                                    ${res.lastPrice.toLocaleString(undefined, {
                                                                        minimumFractionDigits: res.lastPrice < 0.1 ? 6 : 2,
                                                                        maximumFractionDigits: res.lastPrice < 0.1 ? 8 : 2
                                                                    })}
                                                                </div>
                                                            </div>
                                                            <div className={`px-3 py-2 rounded-xl border flex items-center gap-2 ${res.signalScore > 70 ? "bg-emerald-500/10 border-emerald-500/20 text-emerald-400 shadow-[0_0_15px_rgba(16,185,129,0.1)]" :
                                                                res.signalScore > 40 ? "bg-amber-500/10 border-amber-500/20 text-amber-400" :
                                                                    "bg-rose-500/10 border-rose-500/20 text-rose-400"
                                                                }`}>
                                                                <span className="text-sm font-black leading-none">{Math.round(res.signalScore)}</span>
                                                                <div className="flex items-center gap-1 opacity-80 border-l border-white/10 pl-2">
                                                                    <span className="text-[9px] uppercase tracking-wider font-bold">Skor</span>
                                                                    <InfoTooltip
                                                                        position="bottom"
                                                                        text={`SMA 111 Puanlama Mantığı:
• 100: Son 3 mumda yukarı yönlü kırılım gerçekleşti.
• 90: Trend üstünde ve SMA'ya çok yakın (%1).
• 80: Trend üstünde ve SMA'ya yakın (%3).
• 70: Trend üstünde (Güvenli Bölge).`}
                                                                    />
                                                                </div>
                                                            </div>
                                                        </div>

                                                        <div className="space-y-4 relative z-10">
                                                            <div className="w-full h-1.5 bg-white/5 rounded-full overflow-hidden">
                                                                <motion.div
                                                                    initial={{ width: 0 }}
                                                                    animate={{ width: `${res.signalScore}%` }}
                                                                    className={`h-full rounded-full ${res.signalScore > 70 ? "bg-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.5)]" :
                                                                        res.signalScore > 40 ? "bg-amber-500" : "bg-rose-500"
                                                                        }`}
                                                                />
                                                            </div>

                                                            <div className="flex items-center justify-between text-[10px] font-bold">
                                                                <div className="flex items-center gap-1.5 text-slate-400">
                                                                    <button
                                                                        onClick={(e) => {
                                                                            const cleanSymbol = res.symbol.replace("/", "");
                                                                            window.open(`https://tr.tradingview.com/chart/RbphTzbt/?symbol=BINANCE:${cleanSymbol.toUpperCase()}`, '_blank');
                                                                            e.stopPropagation();
                                                                        }}
                                                                        className="p-1 hover:bg-white/10 rounded-lg text-slate-500 hover:text-primary transition-all cursor-pointer"
                                                                        title="Grafiğe Bak"
                                                                    >
                                                                        <Activity size={12} />
                                                                    </button>
                                                                    <span className="truncate max-w-[120px]">{res.comment}</span>
                                                                </div>
                                                                <div className="flex items-center gap-2">
                                                                    <div className="flex items-center gap-1">
                                                                        {res.suggestedAction.toString() === "Buy" || res.suggestedAction.toString() === "1" ? (
                                                                            <>
                                                                                <span className="text-emerald-400 flex items-center gap-1 text-[10px] font-bold"><CheckCircle2 size={10} /> ALIM UYGUN</span>
                                                                                <button
                                                                                    onClick={(e) => {
                                                                                        e.stopPropagation();
                                                                                        setQuickBuyItem(res);
                                                                                        setIsQuickBuyOpen(true);
                                                                                    }}
                                                                                    className="ml-2 px-2 py-1 rounded-lg bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-400 text-[9px] font-bold flex items-center gap-1 transition-all border border-emerald-500/30 hover:scale-105"
                                                                                >
                                                                                    <Zap size={10} />
                                                                                    HIZLI AL
                                                                                </button>
                                                                            </>
                                                                        ) : res.suggestedAction.toString() === "Sell" || res.suggestedAction.toString() === "2" ? (
                                                                            <span className="text-rose-400 flex items-center gap-1 text-[10px] font-bold"><XCircle size={10} /> SATIŞ UYGUN</span>
                                                                        ) : (
                                                                            <span className="text-slate-500 text-[10px] font-bold">BEKLE</span>
                                                                        )}
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </motion.div>
                                                );
                                            })}
                                        </AnimatePresence>
                                    </div>
                                </div>
                            ) : (
                                <div className="h-full flex flex-col items-center justify-center text-center space-y-4 py-20 opacity-40">
                                    {hasScanned ? (
                                        <>
                                            <div className="w-20 h-20 bg-rose-500/10 rounded-3xl flex items-center justify-center border border-rose-500/20">
                                                <Filter size={40} className="text-rose-400" />
                                            </div>
                                            <div className="max-w-md space-y-2 px-6">
                                                <h4 className="text-white font-bold text-lg">Eşleşen Parite Bulunamadı</h4>
                                                <div className="bg-white/5 rounded-xl p-4 mt-2 text-left space-y-2 border border-white/5">
                                                    <div className="flex items-center gap-2 text-xs text-slate-300">
                                                        <Target size={14} className="text-primary" />
                                                        <span className="font-bold">Strateji:</span>
                                                        <span>{currentStrategy?.name}</span>
                                                    </div>
                                                    <div className="flex items-center gap-2 text-xs text-slate-300">
                                                        <Gauge size={14} className="text-amber-500" />
                                                        <span className="font-bold">Min. Skor:</span>
                                                        <span>{minScore}</span>
                                                    </div>
                                                    <div className="flex items-center gap-2 text-xs text-slate-300">
                                                        <TrendingUp size={14} className="text-emerald-500" />
                                                        <span className="font-bold">Açıklama:</span>
                                                        <span className="line-clamp-2">{currentStrategy?.description}</span>
                                                    </div>
                                                </div>
                                                <p className="text-xs text-slate-400 leading-relaxed mt-2">
                                                    Seçtiğiniz strateji kriterlerine ve min. skor filtresine uyan herhangi bir parite şu an için tespit edilemedi. Filtreleri gevşetebilir veya farklı bir strateji deneyebilirsiniz.
                                                </p>
                                            </div>
                                        </>
                                    ) : (
                                        <>
                                            <div className="w-20 h-20 bg-white/5 rounded-3xl flex items-center justify-center">
                                                <Gauge size={40} className="text-slate-500" />
                                            </div>
                                            <div className="max-w-xs space-y-2">
                                                <h4 className="text-white font-bold">Market Taraması Hazır</h4>
                                                <p className="text-xs text-slate-400 leading-relaxed">
                                                    Soldaki panelden stratejinizi ve paritelerinizi seçip taramayı başlatarak piyasadaki fırsatları anında yakalayabilirsiniz.
                                                </p>
                                            </div>
                                        </>
                                    )}
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            </div>

            {/* Detail Modal */}
            <ScannerResultDetailModal
                isOpen={isDetailModalOpen}
                onClose={() => setIsDetailModalOpen(false)}
                result={selectedDetailResult}
                onQuickBuy={(result) => {
                    setQuickBuyItem(result);
                    setIsQuickBuyOpen(true);
                }}
            />

            {/* Favorite List Modal */}
            <FavoriteListModal
                isOpen={isFavoriteModalOpen}
                onClose={() => setIsFavoriteModalOpen(false)}
                coins={coins}
                onSaved={loadData}
                editList={editingList}
            />

            {/* Strategy Detail Modal */}
            <StrategyDetailModal
                isOpen={isStrategyDetailOpen}
                onClose={() => setIsStrategyDetailOpen(false)}
                strategy={currentStrategy || null}
            />

            {/* Quick Buy Modal */}
            {quickBuyItem && (
                <QuickBuyModal
                    isOpen={isQuickBuyOpen}
                    onClose={() => {
                        setIsQuickBuyOpen(false);
                        setQuickBuyItem(null);
                    }}
                    symbol={quickBuyItem.symbol}
                    currentPrice={quickBuyItem.lastPrice}
                    signalScore={quickBuyItem.signalScore}
                />
            )}
        </div >
    );
}
