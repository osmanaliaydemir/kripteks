"use client";
import { useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Terminal, Clock } from "lucide-react";

interface Log {
    id: number;
    message: string;
    level: number;
    timestamp: string;
}

interface Props {
    logs: Log[];
    compact?: boolean;
}

export default function BotLogs({ logs, compact = false }: Props) {
    const scrollRef = useRef<HTMLDivElement>(null);

    // Yeni log geldiğinde en alta kaydır
    useEffect(() => {
        if (scrollRef.current) {
            scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
        }
    }, [logs]);

    // Son 10 logu al
    const recentLogs = logs.slice(-10);

    return (
        <div className={`mt-4 bg-slate-950/30 rounded-xl border border-white/5 overflow-hidden font-mono text-xs ${compact ? 'opacity-70 hover:opacity-100 transition-opacity' : ''}`}>
            {/* Header */}
            <div className="flex items-center gap-2 px-3 py-2 bg-white/5 border-b border-white/5 text-slate-400">
                <Terminal size={12} />
                <span className="uppercase tracking-wider font-bold text-[10px]">{compact ? 'Canlı Kayıtlar' : 'Sistem Kayıtları'}</span>
            </div>

            {/* Log Area */}
            <div
                ref={scrollRef}
                className={`${compact ? 'h-24' : 'h-32'} overflow-y-auto p-3 space-y-1.5 scrollbar-thin scrollbar-thumb-slate-700 scrollbar-track-transparent`}
            >
                {recentLogs.length === 0 ? (
                    <div className="text-slate-600 italic">Log kaydı bekleniyor...</div>
                ) : (
                    recentLogs.map((log) => (
                        <motion.div
                            key={log.id}
                            initial={{ opacity: 0, x: -10 }}
                            animate={{ opacity: 1, x: 0 }}
                            className="flex gap-2 text-slate-300"
                        >
                            <span className="text-slate-600 shrink-0">
                                {new Date(log.timestamp).toLocaleTimeString()}
                            </span>
                            <span className={
                                log.message.includes("KAR AL") ? "text-green-400 font-bold" :
                                    log.message.includes("ZARAR DURDUR") ? "text-red-400 font-bold" :
                                        log.message.includes("kontrol") ? "text-cyan-400/70" :
                                            "text-slate-300"
                            }>
                                {log.message}
                            </span>
                        </motion.div>
                    ))
                )}
            </div>
        </div>
    );
}
