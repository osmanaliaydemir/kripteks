"use client";

import React, { useState, useEffect } from "react";
import { SettingsService } from "@/lib/api";
import { toast } from "sonner";
import {
    Activity,
    User as UserIcon,
    Clock,
    Globe,
    Info,
    RefreshCw,
    Search
} from "lucide-react";
import { motion } from "framer-motion";

interface AuditLog {
    id: string;
    userId: string | null;
    userEmail: string;
    action: string;
    metadata: string | null;
    ipAddress: string | null;
    timestamp: string;
}

export function AuditLogs() {
    const [logs, setLogs] = useState<AuditLog[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState("");

    useEffect(() => {
        loadLogs();
    }, []);

    const loadLogs = async () => {
        setIsLoading(true);
        try {
            const data = await SettingsService.getAuditLogs();
            if (Array.isArray(data)) {
                setLogs(data);
            }
        } catch (error) {
            console.error("Loglar yüklenirken hata:", error);
            toast.error("Hata", { description: "Sistem günlükleri yüklenemedi." });
        } finally {
            setIsLoading(false);
        }
    };

    const filteredLogs = logs.filter(log =>
        log.action.toLowerCase().includes(searchTerm.toLowerCase()) ||
        log.userEmail.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (log.metadata && log.metadata.toLowerCase().includes(searchTerm.toLowerCase()))
    );

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div className="relative flex-1 max-w-md">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
                    <input
                        type="text"
                        placeholder="İşlem, kullanıcı veya detay ara..."
                        className="w-full bg-slate-900/50 border border-white/10 rounded-xl py-2.5 pl-10 pr-4 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary/50 transition-all"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
                <button
                    onClick={loadLogs}
                    disabled={isLoading}
                    className="flex items-center justify-center gap-2 px-4 py-2.5 bg-white/5 hover:bg-white/10 text-white rounded-xl transition-all border border-white/10 disabled:opacity-50"
                >
                    <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
                    <span className="text-sm font-medium">Yenile</span>
                </button>
            </div>

            <div className="overflow-x-auto rounded-xl border border-white/5">
                <table className="w-full text-left border-collapse">
                    <thead>
                        <tr className="bg-white/5 border-b border-white/5">
                            <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">İşlem</th>
                            <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Kullanıcı</th>
                            <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">IP Adresi</th>
                            <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Tarih</th>
                            <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Detaylar</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-white/5 bg-slate-900/20">
                        {isLoading ? (
                            <tr>
                                <td colSpan={5} className="px-6 py-12 text-center text-slate-500">
                                    <div className="flex flex-col items-center gap-3">
                                        <RefreshCw className="w-8 h-8 animate-spin text-primary/50" />
                                        <span>Günlükler yükleniyor...</span>
                                    </div>
                                </td>
                            </tr>
                        ) : filteredLogs.length === 0 ? (
                            <tr>
                                <td colSpan={5} className="px-6 py-12 text-center text-slate-500">
                                    Henüz bir kayıt bulunamadı.
                                </td>
                            </tr>
                        ) : (
                            filteredLogs.map((log) => (
                                <motion.tr
                                    initial={{ opacity: 0 }}
                                    animate={{ opacity: 1 }}
                                    key={log.id}
                                    className="hover:bg-white/2 transition-colors"
                                >
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="flex items-center gap-3">
                                            <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center border border-primary/20">
                                                <Activity className="text-primary" size={14} />
                                            </div>
                                            <span className="text-sm font-medium text-white">{log.action}</span>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="flex items-center gap-2 text-slate-300">
                                            <UserIcon size={14} className="text-slate-500" />
                                            <span className="text-sm">{log.userEmail}</span>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="flex items-center gap-2 text-slate-400">
                                            <Globe size={14} className="text-slate-500" />
                                            <span className="text-xs font-mono">{log.ipAddress || 'Bilinmiyor'}</span>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="flex items-center gap-2 text-slate-400">
                                            <Clock size={14} className="text-slate-500" />
                                            <span className="text-xs">
                                                {new Intl.DateTimeFormat('tr-TR', {
                                                    day: 'numeric',
                                                    month: 'short',
                                                    year: 'numeric',
                                                    hour: '2-digit',
                                                    minute: '2-digit'
                                                }).format(new Date(log.timestamp))}
                                            </span>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4">
                                        {log.metadata ? (
                                            <div className="group relative">
                                                <div className="flex items-center gap-1.5 cursor-help text-primary/80 hover:text-primary transition-colors">
                                                    <Info size={14} />
                                                    <span className="text-xs font-medium">Görüntüle</span>
                                                </div>
                                                <div className="absolute bottom-full right-0 mb-2 w-64 p-3 bg-slate-800 border border-white/10 rounded-xl shadow-2xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all z-50">
                                                    <pre className="text-[10px] text-slate-300 overflow-x-auto whitespace-pre-wrap font-mono">
                                                        {JSON.stringify(JSON.parse(log.metadata), null, 2)}
                                                    </pre>
                                                </div>
                                            </div>
                                        ) : (
                                            <span className="text-xs text-slate-600">-</span>
                                        )}
                                    </td>
                                </motion.tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            <div className="flex items-center gap-2 text-[11px] text-slate-500 bg-white/5 border border-white/5 rounded-lg p-3">
                <Info size={14} className="shrink-0" />
                <p>Güvenlik nedeniyle son 200 işlem günlüğü listelenmektedir. Daha eski kayıtlar için veritabanı yedeğini kontrol edin.</p>
            </div>
        </div>
    );
}
