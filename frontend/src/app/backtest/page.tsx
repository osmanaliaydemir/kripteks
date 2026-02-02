"use client";

import { useEffect, useState } from "react";
import { Strategy, Coin, User } from "@/types";
import { MarketService } from "@/lib/api";
import { motion, AnimatePresence } from "framer-motion";
import { Activity, FlaskConical, LayoutDashboard, LogOut, Settings, User as UserIcon, Key, Database, Info, BarChart2 } from "lucide-react";
import { toast } from "sonner";
import Link from "next/link";
import BacktestPanel from "@/components/ui/BacktestPanel";
import Navbar from "@/components/ui/Navbar";

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


export default function BacktestPage() {
    const [coins, setCoins] = useState<Coin[]>([]);
    const [strategies, setStrategies] = useState<Strategy[]>([]);
    const [user, setUser] = useState<User | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [isCoinsLoading, setIsCoinsLoading] = useState(false);

    useEffect(() => {
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

        fetchInitialData();
    }, []);

    const fetchInitialData = async () => {
        try {
            const [strategiesData] = await Promise.all([
                MarketService.getStrategies()
            ]);
            setStrategies(strategiesData);
        } catch (error) {
            console.error("Veri hatası", error);
        } finally {
            setIsLoading(false);
        }
    };

    const refreshCoins = async () => {
        setIsCoinsLoading(true);
        try {
            const coinsData = await MarketService.getCoins();
            setCoins(coinsData);
        } catch (e) {
            console.error(e);
        }
        setIsCoinsLoading(false);
    };

    const handleLogout = () => {
        localStorage.removeItem("token");
        localStorage.removeItem("user");
        window.location.href = '/login';
    };

    return (
        <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-20">
            {/* HEADER BAR */}
            <Navbar user={user} />

            <div className="space-y-6">
                <div className="flex items-center gap-3 mb-2">
                    <div className="w-10 h-10 rounded-xl bg-secondary/10 flex items-center justify-center border border-secondary/20">
                        <FlaskConical className="text-secondary" size={20} />
                    </div>
                    <div>
                        <h2 className="text-xl font-display font-bold text-white tracking-tight">Gelişmiş Strateji Simülatörü</h2>
                        <p className="text-xs text-slate-400">Botlarınızı gerçek verilerle geçmişe dönük test edin</p>
                    </div>
                </div>

                <div className="glass-card p-1">
                    <div className="bg-slate-900/40 rounded-2xl p-6">
                        <BacktestPanel
                            coins={coins}
                            strategies={strategies}
                            onRefreshCoins={refreshCoins}
                            isCoinsLoading={isCoinsLoading}
                        />
                    </div>
                </div>
            </div>
        </main>
    );
}
