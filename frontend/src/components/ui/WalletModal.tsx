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
                        className="fixed inset-0 m-auto w-full max-w-2xl h-[600px] bg-slate-900 border border-slate-700/50 rounded-3xl shadow-2xl z-50 flex flex-col overflow-hidden"
                    >
                        {/* Header */}
                        <div className="flex items-center justify-between p-6 border-b border-slate-700/50">
                            <h2 className="text-xl font-bold text-white flex items-center gap-3">
                                <span className="bg-cyan-500/10 p-2 rounded-xl text-cyan-400">
                                    <Wallet size={24} />
                                </span>
                                Cüzdan Geçmişi
                            </h2>
                            <button onClick={onClose} className="p-2 hover:bg-slate-800 rounded-full text-slate-400 hover:text-white transition-colors">
                                <X size={20} />
                            </button>
                        </div>

                        {/* List Area */}
                        <div className="flex-1 overflow-y-auto p-4 space-y-2">
                            {loading ? (
                                <div className="flex justify-center items-center h-40 text-slate-500 gap-2">
                                    <RefreshCw className="animate-spin" size={16} /> Yükleniyor...
                                </div>
                            ) : transactions.length === 0 ? (
                                <div className="text-center py-20 text-slate-500">
                                    Henüz işlem kaydı bulunmuyor.
                                </div>
                            ) : (
                                transactions.map((tx) => (
                                    <div key={tx.id} className="bg-slate-800/40 p-4 rounded-xl flex items-center justify-between hover:bg-slate-800/60 transition-colors border border-transparent hover:border-slate-700">
                                        <div className="flex items-center gap-4">
                                            <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${tx.amount > 0
                                                    ? "bg-green-500/10 text-green-500"
                                                    : "bg-red-500/10 text-red-500"
                                                }`}>
                                                {tx.amount > 0 ? <ArrowDownLeft size={18} /> : <ArrowUpRight size={18} />}
                                            </div>
                                            <div>
                                                <p className="text-white font-medium text-sm">{tx.description}</p>
                                                <p className="text-xs text-slate-500 font-mono mt-0.5">
                                                    {new Date(tx.createdAt).toLocaleString()}
                                                </p>
                                            </div>
                                        </div>
                                        <div className={`font-mono font-bold text-sm ${tx.amount > 0 ? "text-green-400" : "text-slate-200"
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
