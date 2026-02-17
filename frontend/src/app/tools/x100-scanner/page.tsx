"use client";

import React from "react";
import { motion } from "framer-motion";
import { Target, ArrowLeft } from "lucide-react";
import Link from "next/link";
import TradingViewScreenerWidget from "@/components/ui/TradingViewScreenerWidget";

export default function X100ScannerPage() {
    return (
        <div className="p-4 md:p-8 pt-20 md:pt-8 min-h-screen bg-transparent mb-10">
            <div className="max-w-[1920px] mx-auto space-y-8">
                {/* Header */}
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div className="space-y-1">
                        <motion.div
                            initial={{ opacity: 0, x: -20 }}
                            animate={{ opacity: 1, x: 0 }}
                            className="flex items-center gap-3"
                        >
                            <div className="p-2.5 bg-primary/10 rounded-2xl text-primary border border-primary/20 shadow-lg shadow-primary/10">
                                <Target size={24} />
                            </div>
                            <h1 className="text-3xl font-black text-white tracking-tight">
                                X100 <span className="text-primary italic">Scanner</span>
                            </h1>
                        </motion.div>
                        <p className="text-slate-400 text-sm font-medium pl-14">
                            Borsa İstanbul (BIST 100) teknik analizi ve canlı tarama ekranı.
                        </p>
                    </div>

                    <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-4">
                        <Link
                            href="/"
                            className="flex items-center gap-4 bg-white/5 border border-white/10 p-4 rounded-2xl backdrop-blur-md hover:bg-white/10 transition-all group"
                        >
                            <div className="p-2 bg-primary/10 rounded-xl text-primary group-hover:-translate-x-1 transition-transform">
                                <ArrowLeft size={16} />
                            </div>
                            <div className="text-xs">
                                <div className="text-white font-bold tracking-tight">Dashboard'a Dön</div>
                                <div className="text-slate-500 font-medium">Kripto Paneli</div>
                            </div>
                        </Link>
                    </div>
                </div>

                {/* Scanner Widget Area */}
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.2 }}
                    className="h-[800px] w-full"
                >
                    <TradingViewScreenerWidget height="100%" />
                </motion.div>
            </div>
        </div>
    );
}
