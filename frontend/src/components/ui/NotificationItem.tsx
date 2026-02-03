"use client";

import React from "react";
import { Bell, Check, Info, AlertTriangle, AlertCircle, ShoppingCart, Clock } from "lucide-react";
import { motion } from "framer-motion";

interface NotificationItemProps {
    notification: {
        id: string;
        title: string;
        message: string;
        type: number; // 0: Info, 1: Success, 2: Warning, 3: Error, 4: Trade
        isRead: boolean;
        createdAt: string;
    };
    onMarkAsRead: (id: string) => void;
}

export function NotificationItem({ notification, onMarkAsRead }: NotificationItemProps) {
    const getIcon = () => {
        switch (notification.type) {
            case 1: return <Check size={14} className="text-emerald-500" />;
            case 2: return <AlertTriangle size={14} className="text-amber-500" />;
            case 3: return <AlertCircle size={14} className="text-rose-500" />;
            case 4: return <ShoppingCart size={14} className="text-primary" />;
            default: return <Info size={14} className="text-sky-500" />;
        }
    };

    const formatTime = (dateStr: string) => {
        const date = new Date(dateStr);
        const now = new Date();
        const diffInMs = now.getTime() - date.getTime();
        const diffInMins = Math.floor(diffInMs / (1000 * 60));

        if (diffInMins < 1) return "Az önce";
        if (diffInMins < 60) return `${diffInMins}dk önce`;

        const diffInHours = Math.floor(diffInMins / 60);
        if (diffInHours < 24) return `${diffInHours}sa önce`;

        return date.toLocaleDateString();
    };

    return (
        <div className={`p-3 border-b border-white/5 hover:bg-white/5 transition-all group relative ${!notification.isRead ? 'bg-slate-800/30' : ''}`}>
            <div className="flex items-start gap-3 pr-8">
                <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 bg-slate-900 border border-white/5`}>
                    {getIcon()}
                </div>
                <div className="flex-1 min-w-0">
                    <h4 className="text-[11px] font-bold text-white mb-0.5 truncate">{notification.title}</h4>
                    <p className="text-[10px] text-slate-400 leading-relaxed mb-1 line-clamp-2">{notification.message}</p>
                    <div className="flex items-center gap-1.5 text-slate-600">
                        <Clock size={10} />
                        <span className="text-[8px] font-mono tracking-tighter">{formatTime(notification.createdAt)}</span>
                    </div>
                </div>
            </div>

            {!notification.isRead && (
                <button
                    onClick={(e) => {
                        e.stopPropagation();
                        onMarkAsRead(notification.id);
                    }}
                    className="absolute right-3 top-1/2 -translate-y-1/2 p-2 rounded-lg bg-emerald-500/10 text-emerald-500 opacity-0 group-hover:opacity-100 transition-all hover:bg-emerald-500/20"
                    title="Okundu olarak işaretle"
                >
                    <Check size={14} />
                </button>
            )}
        </div>
    );
}
