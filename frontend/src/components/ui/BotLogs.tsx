"use client";
import { useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Terminal, Clock } from "lucide-react";

interface Log {
    id: number | string;
    message: string;
    level: number | string;
    timestamp: string;
}

interface Props {
    logs: Log[];
    compact?: boolean;
}

export default function BotLogs({ logs, compact = false }: Props) {
    const scrollRef = useRef<HTMLDivElement>(null);

    // En yeni logları en üstte göster (Tarihe göre tersten diz)
    const displayLogs = [...logs]
        .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
        .slice(0, compact ? 10 : 50);

    // Yeni log geldiğinde en üste kaydır
    useEffect(() => {
        if (scrollRef.current) {
            scrollRef.current.scrollTop = 0;
        }
    }, [logs]);

    return (
        <div className={`mt-4 bg-slate-950/30 rounded-xl border border-white/5 overflow-hidden font-mono text-xs ${compact ? 'opacity-70 hover:opacity-100 transition-opacity' : ''}`}>
            {/* Header Removed - Controlled by Parent Accordion */}


            {/* Log Area */}
            <div
                ref={scrollRef}
                className={`${compact ? 'h-24' : 'h-32'} overflow-y-auto p-3 space-y-1.5 scrollbar-thin scrollbar-thumb-slate-700 scrollbar-track-transparent`}
            >
                {displayLogs.length === 0 ? (
                    <div className="text-slate-600 italic">Log kaydı bekleniyor...</div>
                ) : (
                    displayLogs.map((log: Log) => (
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
