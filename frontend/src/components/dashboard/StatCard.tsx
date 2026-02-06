"use client";

import { motion } from "framer-motion";
import { TrendingUp, HelpCircle } from "lucide-react";
import { InfoTooltip } from "./InfoTooltip";
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
    description?: string;
}

export function StatCard({ title, value, icon, trend, trendUp, delay, highlight, onClick, description }: StatCardProps) {
    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            whileHover={{ scale: 1.02, translateY: -4 }}
            transition={{ delay, duration: 0.5 }}
            onClick={onClick}
            className={`glass-card p-6 relative group transition-shadow hover:shadow-2xl hover:shadow-primary/5 ${onClick ? 'cursor-pointer' : ''} ${highlight ? 'border-primary/20 bg-primary/5' : ''}`}
        >
            <div className="flex justify-between items-start mb-4 relative z-10">
                <div>
                    <div className="flex items-center gap-1.5 mb-1 group/title">
                        <p className="text-slate-400 text-xs font-bold uppercase tracking-widest">{title}</p>
                        {description && (
                            <InfoTooltip text={description} />
                        )}
                    </div>
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
            <div className="absolute inset-0 rounded-2xl overflow-hidden pointer-events-none">
                <div className={`absolute -bottom-4 -right-4 w-24 h-24 rounded-full blur-2xl opacity-20 group-hover:opacity-30 transition-opacity ${highlight ? 'bg-primary' : 'bg-white'}`}></div>
            </div>
        </motion.div>
    );
}
