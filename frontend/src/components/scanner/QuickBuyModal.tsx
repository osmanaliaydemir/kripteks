"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X, Zap, TrendingUp, AlertTriangle, Loader2 } from "lucide-react";
import { BotService } from "@/lib/api";
import { toast } from "sonner";

interface QuickBuyModalProps {
    isOpen: boolean;
    onClose: () => void;
    symbol: string;
    currentPrice: number;
    signalScore: number;
}

export function QuickBuyModal({ isOpen, onClose, symbol, currentPrice, signalScore }: QuickBuyModalProps) {
    const [amount, setAmount] = useState<number>(100);
    const [loading, setLoading] = useState(false);
    const [strategy, setStrategy] = useState("strategy-market-buy");

    const handleQuickBuy = async () => {
        if (amount <= 0) {
            toast.error("Geçerli bir miktar giriniz");
            return;
        }

        setLoading(true);
        try {
            await BotService.create({
                symbol: symbol.replace("/", ""),
                strategy: strategy,
                amount: amount,
                interval: "1h",
                takeProfit: 5,
                stopLoss: 3,
                isActive: true
            });

            toast.success(
                <div className="flex flex-col gap-1">
                    <span className="font-bold">Alım Emri Gönderildi! 🚀</span>
                    <span className="text-xs opacity-80">{symbol} için ${amount} tutarında alım emri oluşturuldu</span>
                </div>
            );
            onClose();
        } catch (error: any) {
            toast.error(error.message || "Alım emri oluşturulurken hata oluştu");
        } finally {
            setLoading(false);
        }
    };

    const presetAmounts = [50, 100, 250, 500, 1000];

    return (
        <AnimatePresence>
            {isOpen && (
                <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4"
                    onClick={onClose}
                >
                    <motion.div
                        initial={{ scale: 0.9, opacity: 0, y: 20 }}
                        animate={{ scale: 1, opacity: 1, y: 0 }}
                        exit={{ scale: 0.9, opacity: 0, y: 20 }}
                        onClick={(e) => e.stopPropagation()}
                        className="bg-slate-900/95 border border-white/10 rounded-3xl max-w-md w-full overflow-hidden shadow-2xl"
                    >
                        {/* Header */}
                        <div className="p-6 border-b border-white/5 bg-emerald-500/5">
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    <div className="p-2.5 bg-emerald-500/10 rounded-xl text-emerald-400 border border-emerald-500/20">
                                        <Zap size={20} />
                                    </div>
                                    <div>
                                        <h3 className="font-bold text-white text-lg">Hızlı Alım</h3>
                                        <p className="text-[10px] text-emerald-400 uppercase tracking-widest font-bold">Bot ile anlık alım</p>
                                    </div>
                                </div>
                                <button
                                    onClick={onClose}
                                    className="p-2 hover:bg-white/10 rounded-xl transition-colors text-slate-400 hover:text-white"
                                >
                                    <X size={18} />
                                </button>
                            </div>
                        </div>

                        {/* Content */}
                        <div className="p-6 space-y-5">
                            {/* Coin Info */}
                            <div className="flex items-center justify-between p-4 rounded-2xl bg-white/3 border border-white/5">
                                <div className="flex items-center gap-3">
                                    <div className="w-10 h-10 rounded-xl bg-linear-to-br from-amber-500 to-orange-600 flex items-center justify-center font-black text-white text-sm">
                                        {symbol.split("/")[0].slice(0, 2)}
                                    </div>
                                    <div>
                                        <div className="font-bold text-white">{symbol}</div>
                                        <div className="text-xs text-slate-400 flex items-center gap-1">
                                            <TrendingUp size={10} className="text-emerald-400" />
                                            Sinyal Skoru: <span className="text-emerald-400 font-bold">{Math.round(signalScore)}</span>
                                        </div>
                                    </div>
                                </div>
                                <div className="text-right">
                                    <div className="text-xs text-slate-500">Güncel Fiyat</div>
                                    <div className="font-bold text-white">${currentPrice.toFixed(currentPrice < 1 ? 6 : 2)}</div>
                                </div>
                            </div>

                            {/* Strategy Selection */}
                            <div className="space-y-2">
                                <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest">Alım Stratejisi</label>
                                <select
                                    value={strategy}
                                    onChange={(e) => setStrategy(e.target.value)}
                                    className="w-full bg-slate-950/40 border border-white/5 rounded-xl px-3 py-2.5 text-xs text-white focus:outline-none focus:border-primary/40 cursor-pointer"
                                >
                                    <option value="strategy-market-buy">Anlık Alım (Piyasa Fiyatı)</option>
                                    <option value="strategy-golden-rose">Altın Gül Trendi</option>
                                    <option value="strategy-alpha-trend">Alfa Trend Takibi</option>
                                </select>
                            </div>

                            {/* Amount Input */}
                            <div className="space-y-3">
                                <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest">Alım Miktarı (USDT)</label>
                                <div className="relative">
                                    <input
                                        type="number"
                                        value={amount}
                                        onChange={(e) => setAmount(Number(e.target.value))}
                                        className="w-full bg-slate-950/40 border border-white/5 rounded-xl px-4 py-3 text-lg font-bold text-white focus:outline-none focus:border-primary/40"
                                        placeholder="0"
                                        min={10}
                                    />
                                    <span className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-500 font-bold text-sm">USDT</span>
                                </div>

                                {/* Preset Amounts */}
                                <div className="flex gap-2">
                                    {presetAmounts.map((preset) => (
                                        <button
                                            key={preset}
                                            onClick={() => setAmount(preset)}
                                            className={`flex-1 py-2 rounded-lg text-xs font-bold transition-all ${amount === preset
                                                ? "bg-primary text-white"
                                                : "bg-white/5 text-slate-400 hover:bg-white/10 hover:text-white"
                                                }`}
                                        >
                                            ${preset}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            {/* Summary */}
                            <div className="p-4 rounded-2xl bg-emerald-500/5 border border-emerald-500/10 space-y-2">
                                <div className="flex items-center justify-between text-xs">
                                    <span className="text-slate-400">Alım Miktarı</span>
                                    <span className="text-white font-bold">${amount.toFixed(2)} USDT</span>
                                </div>
                                <div className="flex items-center justify-between text-xs">
                                    <span className="text-slate-400">Tahmini Adet</span>
                                    <span className="text-white font-bold">~{(amount / currentPrice).toFixed(4)} {symbol.split("/")[0]}</span>
                                </div>
                                <div className="flex items-center justify-between text-xs">
                                    <span className="text-slate-400">Take Profit</span>
                                    <span className="text-emerald-400 font-bold">+5%</span>
                                </div>
                                <div className="flex items-center justify-between text-xs">
                                    <span className="text-slate-400">Stop Loss</span>
                                    <span className="text-rose-400 font-bold">-3%</span>
                                </div>
                            </div>

                            {/* Warning */}
                            <div className="flex items-start gap-2 p-3 rounded-xl bg-amber-500/5 border border-amber-500/10">
                                <AlertTriangle size={14} className="text-amber-400 shrink-0 mt-0.5" />
                                <p className="text-[10px] text-amber-400/80 leading-relaxed">
                                    Bu işlem gerçek bir alım emri oluşturacaktır. Yatırım riski içerir.
                                </p>
                            </div>
                        </div>

                        {/* Footer */}
                        <div className="p-6 pt-0">
                            <button
                                onClick={handleQuickBuy}
                                disabled={loading || amount <= 0}
                                className="w-full py-4 rounded-2xl font-bold text-white bg-linear-to-r from-emerald-600 to-green-600 shadow-lg shadow-emerald-900/20 hover:shadow-emerald-900/40 transition-all active:scale-[0.98] flex items-center justify-center gap-3 disabled:opacity-50 disabled:cursor-not-allowed"
                            >
                                {loading ? (
                                    <Loader2 className="w-5 h-5 animate-spin" />
                                ) : (
                                    <>
                                        <Zap size={18} />
                                        <span>Alım Emri Oluştur</span>
                                    </>
                                )}
                            </button>
                        </div>
                    </motion.div>
                </motion.div>
            )}
        </AnimatePresence>
    );
}
