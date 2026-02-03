"use client";

import { motion } from "framer-motion";
import { TrendingUp } from "lucide-react";
import React from "react";

interface StatCardProps {
    title: string;
    value: string | number;
    icon: React.ReactNode;
    trend?: string;
    trendUp?: boolean;
    delay: number;
    highlight?: boolean;
    onClick?: () => void;
}

export function StatCard({ title, value, icon, trend, trendUp, delay, highlight, onClick }: StatCardProps) {
    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay, duration: 0.5 }}
            onClick={onClick}
            className={`glass-card p-5 relative overflow-hidden group ${onClick ? 'cursor-pointer' : ''} ${highlight ? 'border-primary/20 bg-primary/5' : ''}`}
        >
            <div className="flex justify-between items-start mb-4 relative z-10">
                <div>
                    <p className="text-slate-400 text-xs font-bold uppercase tracking-widest mb-1">{title}</p>
                    <h3 className="text-2xl font-mono font-bold text-white tracking-tighter">{value}</h3>
                </div>
                <div className={`p-3 rounded-xl ${highlight ? 'bg-primary/20' : 'bg-slate-800/50'} border border-white/5`}>
                    {icon}
                </div>
            </div>
            {trend && (
                <div className={`flex items-center gap-2 text-xs font-medium ${trendUp ? 'text-emerald-400' : 'text-slate-500'}`}>
                    {trendUp && <TrendingUp size={14} />}
                    {trend}
                </div>
            )}
            <div className={`absolute -bottom-4 -right-4 w-24 h-24 rounded-full blur-2xl opacity-20 pointer-events-none group-hover:opacity-30 transition-opacity ${highlight ? 'bg-primary' : 'bg-white'}`}></div>
        </motion.div>
    );
}
