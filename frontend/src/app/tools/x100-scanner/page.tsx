"use client";

import React from "react";
import X100ScannerDashboard from "@/components/scanner/X100ScannerDashboard";
import { motion } from "framer-motion";
import { Target, Info, ArrowLeft } from "lucide-react";
import Link from "next/link";

export default function X100ScannerPage() {
    return (
        <div className="p-4 md:p-8 pt-20 md:pt-8 min-h-screen bg-transparent">
            <div className="max-w-7xl mx-auto space-y-8">
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

                        <motion.div
                            initial={{ opacity: 0, scale: 0.9 }}
                            animate={{ opacity: 1, scale: 1 }}
                            className="flex items-center gap-4 bg-white/5 border border-white/10 p-4 rounded-2xl backdrop-blur-md"
                        >
                            <div className="p-2 bg-indigo-500/10 rounded-xl text-indigo-400">
                                <Info size={16} />
                            </div>
                            <div className="text-xs">
                                <div className="text-white font-bold tracking-tight">X100 Tarama</div>
                                <div className="text-slate-500 font-medium">BIST Real-time</div>
                            </div>
                        </motion.div>
                    </div>
                </div>

                {/* Dashboard */}
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.2 }}
                >
                    <X100ScannerDashboard />
                </motion.div>
            </div>
        </div>
    );
}
