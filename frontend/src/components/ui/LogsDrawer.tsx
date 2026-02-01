"use client";

import { useState, useEffect, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X, RefreshCw, Trash2, Info, AlertTriangle, AlertCircle, Search } from "lucide-react";
import { LogService } from "@/lib/api";
import { toast } from "sonner";

interface LogsDrawerProps {
    isOpen: boolean;
    onClose: () => void;
}

interface LogEntry {
    id: string;
    level: string;
    message: string;
    timestamp: string;
}

export default function LogsDrawer({ isOpen, onClose }: LogsDrawerProps) {
    const [logs, setLogs] = useState<LogEntry[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [filterLevel, setFilterLevel] = useState('All');
    const [searchTerm, setSearchTerm] = useState('');

    const loadLogs = useCallback(async () => {
        setIsLoading(true);
        try {
            const data = await LogService.getAll(100, filterLevel);
            setLogs(data);
        } catch (e) {
            console.error(e);
        } finally {
            setIsLoading(false);
        }
    }, [filterLevel]);

    useEffect(() => {
        if (isOpen) {
            loadLogs();
        }
    }, [isOpen, loadLogs]);

    const handleClearLogs = async () => {
        if (!confirm("Tüm sistem kayıtlarını temizlemek istediğinize emin misiniz?")) return;

        try {
            await LogService.clear();
            toast.success("Kayıtlar başarıyla temizlendi.");
            loadLogs();
        } catch (error) {
            toast.error("Kayıtlar temizlenemedi.");
        }
    };

    // Client-side filtering
    const filteredLogs = logs.filter(log =>
        log.message.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const getLevelIcon = (level: string) => {
        switch (level) {
            case 'Error': return <AlertCircle size={14} className="text-rose-500" />;
            case 'Warning': return <AlertTriangle size={14} className="text-amber-500" />;
            default: return <Info size={14} className="text-blue-400" />;
        }
    };

    return (
        <AnimatePresence>
            {isOpen && (
                <>
                    {/* Backdrop */}
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        onClick={onClose}
                        className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50"
                    />

                    {/* Drawer */}
                    <motion.div
                        initial={{ x: "100%" }}
                        animate={{ x: 0 }}
                        exit={{ x: "100%" }}
                        transition={{ type: "spring", stiffness: 300, damping: 30 }}
                        className="fixed right-0 top-0 h-full w-full max-w-md bg-slate-950 border-l border-white/10 shadow-2xl z-50 flex flex-col"
                    >
                        {/* Header */}
                        <div className="flex items-center justify-between p-5 border-b border-white/10 bg-white/5">
                            <div>
                                <h2 className="text-lg font-display font-bold text-white flex items-center gap-3">
                                    <div className="relative">
                                        <div className="w-2.5 h-2.5 rounded-full bg-amber-500 animate-pulse"></div>
                                        <div className="absolute inset-0 bg-amber-500/50 rounded-full blur-sm animate-pulse"></div>
                                    </div>
                                    Sistem Kayıtları
                                </h2>
                                <p className="text-xs text-slate-500 font-mono mt-1">Canlı Akış • Son 100 kayıt</p>
                            </div>
                            <div className="flex items-center gap-2">
                                <button
                                    onClick={loadLogs}
                                    className="p-2 hover:bg-white/10 rounded-lg text-slate-400 hover:text-white transition-colors"
                                    title="Yenile"
                                >
                                    <RefreshCw size={18} className={isLoading ? "animate-spin text-primary" : ""} />
                                </button>
                                <button
                                    onClick={onClose}
                                    className="p-2 hover:bg-white/10 rounded-lg text-slate-400 hover:text-white transition-colors"
                                >
                                    <X size={20} />
                                </button>
                            </div>
                        </div>

                        {/* Toolbar */}
                        <div className="p-4 border-b border-white/10 gap-3 flex flex-col bg-slate-900/50">
                            <div className="flex gap-2">
                                <div className="relative flex-1">
                                    <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
                                    <input
                                        type="text"
                                        placeholder="Kayıt ara..."
                                        value={searchTerm}
                                        onChange={(e) => setSearchTerm(e.target.value)}
                                        className="w-full bg-slate-950 border border-white/10 rounded-lg pl-9 pr-3 py-2 text-xs text-white focus:outline-none focus:border-primary/50 transition-all font-mono"
                                    />
                                </div>
                                <select
                                    value={filterLevel}
                                    onChange={(e) => setFilterLevel(e.target.value)}
                                    className="bg-slate-950 border border-white/10 rounded-lg px-3 py-2 text-xs text-slate-300 focus:outline-none focus:border-primary/50 transition-all"
                                >
                                    <option value="All">Tüm Seviyeler</option>
                                    <option value="Info">Bilgi (Info)</option>
                                    <option value="Warning">Uyarı (Warning)</option>
                                    <option value="Error">Hata (Error)</option>
                                </select>
                            </div>

                            <div className="flex justify-end">
                                <button
                                    onClick={handleClearLogs}
                                    className="text-xs text-slate-500 hover:text-rose-400 flex items-center gap-1.5 transition-colors px-2 py-1 rounded hover:bg-rose-500/10"
                                >
                                    <Trash2 size={12} />
                                    Kayıtları Temizle
                                </button>
                            </div>
                        </div>

                        {/* Log List */}
                        <div className="flex-1 overflow-y-auto p-2 space-y-1 font-mono">
                            {isLoading && logs.length === 0 ? (
                                <div className="text-center py-20 text-slate-500 text-xs flex flex-col items-center gap-3">
                                    <RefreshCw className="animate-spin text-primary opacity-50" size={24} />
                                    Veriler yükleniyor...
                                </div>
                            ) : filteredLogs.length > 0 ? (
                                filteredLogs.map((log) => (
                                    <div key={log.id} className={`p-3 rounded-lg border text-xs flex gap-3 transition-colors ${log.level === 'Error' ? 'border-rose-500/20 bg-rose-500/5 text-rose-200 hover:bg-rose-500/10' :
                                        log.level === 'Warning' ? 'border-amber-500/20 bg-amber-500/5 text-amber-200 hover:bg-amber-500/10' :
                                            'border-white/5 bg-slate-900/50 text-slate-300 hover:bg-white/5'
                                        }`}>
                                        <div className="shrink-0 mt-0.5 opacity-80">
                                            {getLevelIcon(log.level)}
                                        </div>
                                        <div className="flex-1 break-all">
                                            <div className="flex items-center justify-between mb-1 opacity-50 text-[10px]">
                                                <span className="uppercase tracking-wider font-bold">{log.level}</span>
                                                <span>{new Date(log.timestamp).toLocaleTimeString()}</span>
                                            </div>
                                            <p className="leading-relaxed font-medium">{log.message}</p>
                                        </div>
                                    </div>
                                ))
                            ) : (
                                <div className="text-center py-20 text-slate-500 text-sm flex flex-col items-center gap-3 opacity-50">
                                    <div className="w-12 h-12 bg-white/5 rounded-full flex items-center justify-center text-slate-400">
                                        <Info size={20} />
                                    </div>
                                    <p className="text-xs">Kriterlere uygun kayıt bulunamadı.</p>
                                </div>
                            )}
                        </div>
                    </motion.div>
                </>
            )}
        </AnimatePresence>
    );
}
