"use client";

import React, { useState } from "react";
import { Bot } from "@/types";
import { motion, AnimatePresence } from "framer-motion";
import Link from "next/link";
import {
    Activity,
    Square,
    ExternalLink,
    ChevronDown,
    DollarSign
} from "lucide-react";
import TradingViewWidget from "@/components/ui/TradingViewWidget";
import BotLogs from "@/components/ui/BotLogs";

interface BotCardProps {
    bot: Bot;
    isActive: boolean;
    activeChartBotId: string | null;
    setActiveChartBotId: (id: string | null) => void;
    handleStopBot: (id: string) => void;
    onStrategyClick: (id: string) => void;
}

export function BotCard({ bot, isActive, activeChartBotId, setActiveChartBotId, handleStopBot, onStrategyClick }: BotCardProps) {
    const [isLogsOpen, setIsLogsOpen] = useState(false);

    return (
        <motion.div
            layout
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95 }}
            whileHover={{ translateY: -4 }}
            className={`glass-card overflow-hidden group transition-all hover:shadow-2xl hover:shadow-emerald-500/5 ${isActive
                ? 'bg-slate-800/40 border-l-4 border-l-emerald-500'
                : 'bg-slate-900/30 opacity-70 hover:opacity-100 border-l-4 border-l-slate-700'
                }`}
        >
            <div className="p-4 sm:p-6 flex flex-col sm:flex-row items-center gap-4 sm:gap-6">

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
                        <Link href={`/bots/${bot.id}`} className="hover:underline hover:text-primary transition-colors">
                            <h3 className="text-white font-display font-bold text-xl tracking-wide">{bot.symbol}</h3>
                        </Link>
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
                    <div className="flex flex-col sm:flex-row items-center justify-center sm:justify-start gap-3 mt-1 w-full">
                        <div className="flex items-center gap-2 px-2 py-0.5 rounded-lg bg-white/5 border border-white/5">
                            <DollarSign size={10} className="text-slate-500" />
                            <span className="text-[11px] font-mono font-bold text-slate-400 tracking-tight">{bot.amount} Bakiye</span>
                        </div>
                    </div>
                </div>

                {/* PNL Display */}
                <div className="flex flex-col items-center sm:items-end min-w-[100px]">
                    <span className={`text-2xl font-bold font-mono tracking-tight ${bot.pnl >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
                        {bot.pnl >= 0 ? '+' : ''}{bot.pnl?.toFixed(2)}$
                    </span>
                    <span className={`text-xs font-bold font-mono px-2 py-0.5 rounded-full ${bot.pnl >= 0 ? 'bg-emerald-500/10 text-emerald-500' : 'bg-rose-500/10 text-rose-500'}`}>
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
                            className="flex-1 sm:flex-none p-3 rounded-xl bg-rose-500/10 text-rose-400 border border-rose-500/20 hover:bg-rose-600 hover:text-white transition-all active:scale-95 group/stop"
                            title="Acil Durdur"
                        >
                            <Square size={18} className="fill-current group-hover/stop:fill-white" />
                        </button>
                    )}
                    <Link
                        href={`/bots/${bot.id}`}
                        className="flex-1 sm:flex-none p-3 rounded-xl bg-slate-800 text-slate-400 border border-white/5 hover:bg-primary/10 hover:text-primary hover:border-primary/50 transition-all flex items-center justify-center"
                        title="Detaylar"
                    >
                        <ExternalLink size={18} />
                    </Link>
                </div>
            </div>

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
