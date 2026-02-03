"use client";

import { useEffect, useState } from "react";
import { WalletService } from "@/lib/api";
import { Wallet, WalletTransaction, User } from "@/types";
import { Wallet as WalletIcon, ArrowUpRight, ArrowDownLeft, Lock, DollarSign, Activity, CreditCard, History } from "lucide-react";
import Navbar from "@/components/ui/Navbar";
import { toast } from "sonner";
import { WalletCardSkeleton, TableSkeleton } from "@/components/ui/Skeletons";
import { motion, AnimatePresence } from "framer-motion";

export default function WalletPage() {
    const [user, setUser] = useState<User | null>(null);
    const [wallet, setWallet] = useState<Wallet | null>(null);
    const [transactions, setTransactions] = useState<WalletTransaction[]>([]);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        // Load User
        try {
            const userData = localStorage.getItem("user");
            if (userData) setUser(JSON.parse(userData));
        } catch (e) {
            console.error(e);
        }

        fetchData();
    }, []);

    const fetchData = async () => {
        try {
            const [walletData, txData] = await Promise.all([
                WalletService.getWallet(),
                WalletService.getTransactions()
            ]);
            setWallet(walletData);
            setTransactions(txData);
        } catch (error) {
            console.error(error);
            toast.error("Cüzdan bilgileri alınamadı.");
        } finally {
            setIsLoading(false);
        }
    };


    return (
        <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-20">
            <Navbar user={user} />

            <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="flex items-center gap-3 mb-8"
            >
                <div className="p-3 bg-primary/10 rounded-xl text-primary border border-primary/20">
                    <WalletIcon size={24} />
                </div>
                <div>
                    <h1 className="text-3xl font-display font-bold text-white">Cüzdanım</h1>
                    <p className="text-slate-400 text-sm">Varlık yönetimi ve işlem geçmişi</p>
                </div>
            </motion.div>

            {/* WALLET CARDS */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5 mb-8">
                <AnimatePresence mode="popLayout">
                    {isLoading ? (
                        <>
                            <WalletCardSkeleton key="s1" />
                            <WalletCardSkeleton key="s2" />
                            <WalletCardSkeleton key="s3" />
                            <WalletCardSkeleton key="s4" />
                        </>
                    ) : (
                        <>
                            {/* Total Asset */}
                            <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="glass-card p-6 border border-white/5 relative overflow-hidden group">
                                <div className="absolute top-0 right-0 w-32 h-32 bg-primary/10 rounded-full blur-3xl -mr-16 -mt-16 pointer-events-none group-hover:bg-primary/20 transition-colors"></div>
                                <div className="flex justify-between items-start mb-4 relative z-10">
                                    <div className="p-3 bg-slate-800/50 rounded-xl text-primary border border-white/5">
                                        <DollarSign size={20} />
                                    </div>
                                    <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest bg-slate-900/50 px-2 py-1 rounded">Toplam Varlık</span>
                                </div>
                                <div className="relative z-10">
                                    <h2 className="text-3xl font-bold font-mono text-white mb-1 tracking-tighter">
                                        ${wallet?.current_balance.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                                    </h2>
                                    <p className="text-xs text-slate-400">Tahmini USD Değeri</p>
                                </div>
                            </motion.div>

                            {/* Available Balance */}
                            <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} transition={{ delay: 0.1 }} className="glass-card p-6 border border-white/5 relative overflow-hidden group">
                                <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-500/10 rounded-full blur-3xl -mr-16 -mt-16 pointer-events-none group-hover:bg-emerald-500/20 transition-colors"></div>
                                <div className="flex justify-between items-start mb-4 relative z-10">
                                    <div className="p-3 bg-slate-800/50 rounded-xl text-emerald-400 border border-white/5">
                                        <CreditCard size={20} />
                                    </div>
                                    <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest bg-slate-900/50 px-2 py-1 rounded">Kullanılabilir</span>
                                </div>
                                <div className="relative z-10">
                                    <h2 className="text-3xl font-bold font-mono text-white mb-1 tracking-tighter">
                                        ${wallet?.available_balance.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                                    </h2>
                                    <p className="text-xs text-slate-400">İşlem açılabilir bakiye</p>
                                </div>
                            </motion.div>

                            {/* Locked / In Trade */}
                            <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} transition={{ delay: 0.2 }} className="glass-card p-6 border border-white/5 relative overflow-hidden group">
                                <div className="absolute top-0 right-0 w-32 h-32 bg-amber-500/10 rounded-full blur-3xl -mr-16 -mt-16 pointer-events-none group-hover:bg-amber-500/20 transition-colors"></div>
                                <div className="flex justify-between items-start mb-4 relative z-10">
                                    <div className="p-3 bg-slate-800/50 rounded-xl text-amber-400 border border-white/5">
                                        <Lock size={20} />
                                    </div>
                                    <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest bg-slate-900/50 px-2 py-1 rounded">Bloke / İşlemde</span>
                                </div>
                                <div className="relative z-10">
                                    <h2 className="text-3xl font-bold font-mono text-white mb-1 tracking-tighter">
                                        ${wallet?.locked_balance.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                                    </h2>
                                    <p className="text-xs text-slate-400">Aktif botlarda kullanılan</p>
                                </div>
                            </motion.div>

                            {/* Total PnL */}
                            <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} transition={{ delay: 0.3 }} className="glass-card p-6 border border-white/5 relative overflow-hidden group">
                                <div className={`absolute top-0 right-0 w-32 h-32 rounded-full blur-3xl -mr-16 -mt-16 pointer-events-none transition-colors ${wallet && wallet.total_pnl >= 0 ? 'bg-emerald-500/10 group-hover:bg-emerald-500/20' : 'bg-rose-500/10 group-hover:bg-rose-500/20'}`}></div>
                                <div className="flex justify-between items-start mb-4 relative z-10">
                                    <div className={`p-3 bg-slate-800/50 rounded-xl border border-white/5 ${wallet && wallet.total_pnl >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
                                        <Activity size={20} />
                                    </div>
                                    <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest bg-slate-900/50 px-2 py-1 rounded">Canlı PnL</span>
                                </div>
                                <div className="relative z-10">
                                    <h2 className={`text-3xl font-bold font-mono mb-1 tracking-tighter ${wallet && wallet.total_pnl >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
                                        {wallet && wallet.total_pnl >= 0 ? '+' : ''}{wallet?.total_pnl.toFixed(2)}$
                                    </h2>
                                    <p className="text-xs text-slate-400">Tüm açık işlemlerden</p>
                                </div>
                            </motion.div>
                        </>
                    )}
                </AnimatePresence>
            </div>

            {/* ACTIONS */}
            <div className="flex gap-4 mb-8">
                <button onClick={() => toast.info("Para Yatırma modülü yakında eklenecek.")} className="px-6 py-3 bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/20 text-emerald-400 rounded-xl font-bold flex items-center gap-2 transition-all active:scale-95">
                    <ArrowDownLeft size={18} />
                    Para Yatır
                </button>
                <button onClick={() => toast.info("Para Çekme modülü yakında eklenecek.")} className="px-6 py-3 bg-slate-800 hover:bg-slate-700 border border-white/5 text-slate-300 rounded-xl font-bold flex items-center gap-2 transition-all active:scale-95">
                    <ArrowUpRight size={18} />
                    Para Çek
                </button>
            </div>

            {/* TRANSACTIONS TABLE */}
            <div className="glass-card overflow-hidden">
                <div className="px-6 py-5 border-b border-white/5 flex items-center gap-3">
                    <History size={20} className="text-slate-400" />
                    <h3 className="font-bold text-white">İşlem Geçmişi</h3>
                </div>
                <div className="overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="bg-white/2 border-b border-white/5">
                                <th className="p-4 text-[10px] font-bold text-slate-500 uppercase tracking-widest">Tarih</th>
                                <th className="p-4 text-[10px] font-bold text-slate-500 uppercase tracking-widest">İşlem Tipi</th>
                                <th className="p-4 text-[10px] font-bold text-slate-500 uppercase tracking-widest">Açıklama</th>
                                <th className="p-4 text-[10px] font-bold text-slate-500 uppercase tracking-widest text-right">Tutar</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5">
                            {isLoading ? (
                                <tr>
                                    <td colSpan={4} className="p-6">
                                        <TableSkeleton rows={5} />
                                    </td>
                                </tr>
                            ) : (
                                <>
                                    {transactions.length === 0 ? (
                                        <tr>
                                            <td colSpan={4} className="p-12 text-center text-slate-500 text-sm font-medium">Henüz işlem geçmişi yok.</td>
                                        </tr>
                                    ) : (
                                        transactions.map((tx) => (
                                            <tr key={tx.id} className="hover:bg-white/2 transition-colors group">
                                                <td className="p-4 text-xs text-slate-400 font-mono w-48">{new Date(tx.createdAt).toLocaleString()}</td>
                                                <td className="p-4 w-40">
                                                    <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-tight ${tx.amount >= 0 ? 'bg-emerald-500/10 text-emerald-400' : 'bg-rose-500/10 text-rose-400'}`}>
                                                        {tx.type}
                                                    </span>
                                                </td>
                                                <td className="p-4 text-xs text-slate-300 font-medium">{tx.description}</td>
                                                <td className={`p-4 text-sm font-bold font-mono text-right w-32 tracking-tighter ${tx.amount >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
                                                    {tx.amount >= 0 ? '+' : ''}{tx.amount.toLocaleString()} $
                                                </td>
                                            </tr>
                                        ))
                                    )}
                                </>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </main>
    );
}
