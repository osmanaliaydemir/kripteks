"use client";
import { useEffect, useState } from "react";
import { X, ArrowUpRight, ArrowDownLeft, Wallet, RefreshCw } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { WalletService } from "@/lib/api";

interface Transaction {
    id: string;
    amount: number;
    type: string;
    description: string;
    createdAt: string;
}

interface Props {
    isOpen: boolean;
    onClose: () => void;
}

export default function WalletModal({ isOpen, onClose }: Props) {
    const [transactions, setTransactions] = useState<Transaction[]>([]);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        if (isOpen) {
            fetchTransactions();
        }
    }, [isOpen]);

    const fetchTransactions = async () => {
        setLoading(true);
        try {
            const data = await WalletService.getTransactions();
            setTransactions(data);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    return (
        <AnimatePresence>
            {isOpen && (
                <>
                    {/* Backdrop */}
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        onClick={onClose}
                        className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50"
                    />

                    {/* Modal Content */}
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95, y: 20 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.95, y: 20 }}
                        className="fixed inset-0 m-auto w-full max-w-2xl h-[600px] glass border border-white/10 rounded-3xl shadow-2xl z-50 flex flex-col overflow-hidden"
                    >
                        {/* Header */}
                        <div className="flex items-center justify-between p-6 border-b border-white/10 bg-white/5">
                            <h2 className="text-xl font-display font-bold text-white flex items-center gap-3">
                                <span className="bg-primary/20 p-2 rounded-xl text-primary border border-primary/20">
                                    <Wallet size={24} />
                                </span>
                                Cüzdan Hareketleri
                            </h2>
                            <button onClick={onClose} className="p-2 hover:bg-white/10 rounded-full text-slate-400 hover:text-white transition-colors">
                                <X size={20} />
                            </button>
                        </div>

                        {/* List Area */}
                        <div className="flex-1 overflow-y-auto p-4 space-y-2">
                            {loading ? (
                                <div className="flex justify-center items-center h-40 text-slate-500 gap-2 font-mono text-xs">
                                    <RefreshCw className="animate-spin text-primary" size={16} /> İşlemler yükleniyor...
                                </div>
                            ) : transactions.length === 0 ? (
                                <div className="text-center py-20 text-slate-500 flex flex-col items-center gap-2">
                                    <div className="w-12 h-12 rounded-full bg-slate-800 flex items-center justify-center text-slate-600">
                                        <Wallet size={24} />
                                    </div>
                                    <span className="text-sm font-medium">Herhangi bir işlem bulunamadı.</span>
                                </div>
                            ) : (
                                transactions.map((tx) => (
                                    <div key={tx.id} className="glass-card p-4 rounded-xl flex items-center justify-between hover:bg-white/5 transition-colors group">
                                        <div className="flex items-center gap-4">
                                            <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 border ${tx.amount > 0
                                                ? "bg-emerald-500/10 text-emerald-500 border-emerald-500/20"
                                                : "bg-rose-500/10 text-rose-500 border-rose-500/20"
                                                }`}>
                                                {tx.amount > 0 ? <ArrowDownLeft size={18} /> : <ArrowUpRight size={18} />}
                                            </div>
                                            <div>
                                                <p className="text-white font-bold text-sm">{tx.description}</p>
                                                <p className="text-[10px] text-slate-500 font-mono uppercase tracking-wider mt-0.5">
                                                    {new Date(tx.createdAt).toLocaleString()}
                                                </p>
                                            </div>
                                        </div>
                                        <div className={`font-mono font-bold text-sm ${tx.amount > 0 ? "text-emerald-400" : "text-slate-200"
                                            }`}>
                                            {tx.amount > 0 ? '+' : ''}{tx.amount.toFixed(2)} USDT
                                        </div>
                                    </div>
                                ))
                            )}
                        </div>
                    </motion.div>
                </>
            )}
        </AnimatePresence>
    );
}
