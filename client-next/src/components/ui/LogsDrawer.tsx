"use client";

import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X, RefreshCw, Trash2, Filter, Info, AlertTriangle, AlertCircle, Search } from "lucide-react";
import { LogService } from "@/lib/api";
import { toast } from "sonner";

interface LogsDrawerProps {
    isOpen: boolean;
    onClose: () => void;
}

export default function LogsDrawer({ isOpen, onClose }: LogsDrawerProps) {
    const [logs, setLogs] = useState<any[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [filterLevel, setFilterLevel] = useState('All');
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        if (isOpen) {
            loadLogs();
        }
    }, [isOpen, filterLevel]); // Filtre değişince yeniden yükle

    const loadLogs = async () => {
        setIsLoading(true);
        try {
            const data = await LogService.getAll(100, filterLevel);
            setLogs(data);
        } catch (e) {
            console.error(e);
        } finally {
            setIsLoading(false);
        }
    };

    const handleClearLogs = async () => {
        if (!confirm("Tüm sistem loglarını silmek istediğinize emin misiniz?")) return;

        try {
            await LogService.clear();
            toast.success("Loglar temizlendi.");
            loadLogs();
        } catch (error) {
            toast.error("Loglar temizlenirken hata oluştu.");
        }
    };

    // İstemci tarafı filtreleme (Search için)
    const filteredLogs = logs.filter(log =>
        log.message.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const getLevelIcon = (level: string) => {
        switch (level) {
            case 'Error': return <AlertCircle size={16} className="text-red-500" />;
            case 'Warning': return <AlertTriangle size={16} className="text-yellow-500" />;
            default: return <Info size={16} className="text-blue-500" />;
        }
    };

    const getLevelClass = (level: string) => {
        switch (level) {
            case 'Error': return "border-red-500/20 bg-red-500/5 text-red-500";
            case 'Warning': return "border-yellow-500/20 bg-yellow-500/5 text-yellow-500";
            default: return "border-blue-500/20 bg-blue-500/5 text-blue-500";
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
                        className="fixed right-0 top-0 h-full w-full max-w-md bg-slate-900 border-l border-slate-800 shadow-2xl z-50 flex flex-col"
                    >
                        {/* Header */}
                        <div className="flex items-center justify-between p-4 border-b border-slate-800 bg-slate-950/50">
                            <div>
                                <h2 className="text-lg font-bold text-white flex items-center gap-2">
                                    <div className="w-2 h-2 rounded-full bg-orange-500 animate-pulse"></div>
                                    Sistem Logları
                                </h2>
                                <p className="text-xs text-slate-500">Son 100 sistem kaydı</p>
                            </div>
                            <div className="flex items-center gap-2">
                                <button
                                    onClick={loadLogs}
                                    className="p-2 hover:bg-slate-800 rounded-lg text-slate-400 hover:text-white transition-colors"
                                    title="Yenile"
                                >
                                    <RefreshCw size={18} className={isLoading ? "animate-spin" : ""} />
                                </button>
                                <button
                                    onClick={onClose}
                                    className="p-2 hover:bg-slate-800 rounded-lg text-slate-400 hover:text-white transition-colors"
                                >
                                    <X size={20} />
                                </button>
                            </div>
                        </div>

                        {/* Toolbar */}
                        <div className="p-4 border-b border-slate-800 gap-3 flex flex-col">
                            <div className="flex gap-2">
                                <div className="relative flex-1">
                                    <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
                                    <input
                                        type="text"
                                        placeholder="Loglarda ara..."
                                        value={searchTerm}
                                        onChange={(e) => setSearchTerm(e.target.value)}
                                        className="w-full bg-slate-950 border border-slate-800 rounded-lg pl-9 pr-3 py-2 text-xs text-white focus:outline-none focus:border-blue-500/50"
                                    />
                                </div>
                                <select
                                    value={filterLevel}
                                    onChange={(e) => setFilterLevel(e.target.value)}
                                    className="bg-slate-950 border border-slate-800 rounded-lg px-3 py-2 text-xs text-slate-300 focus:outline-none"
                                >
                                    <option value="All">Tümü</option>
                                    <option value="Info">Bilgi</option>
                                    <option value="Warning">Uyarı</option>
                                    <option value="Error">Hata</option>
                                </select>
                            </div>

                            <div className="flex justify-end">
                                <button
                                    onClick={handleClearLogs}
                                    className="text-xs text-slate-500 hover:text-red-400 flex items-center gap-1 transition-colors"
                                >
                                    <Trash2 size={12} />
                                    Tümünü Temizle
                                </button>
                            </div>
                        </div>

                        {/* Log List */}
                        <div className="flex-1 overflow-y-auto p-4 space-y-3 font-mono">
                            {isLoading && logs.length === 0 ? (
                                <div className="text-center py-10 text-slate-500 text-sm">Yükleniyor...</div>
                            ) : filteredLogs.length > 0 ? (
                                filteredLogs.map((log) => (
                                    <div key={log.id} className={`p-3 rounded-lg border text-xs flex gap-3 ${getLevelClass(log.level)}`}>
                                        <div className="shrink-0 mt-0.5">
                                            {getLevelIcon(log.level)}
                                        </div>
                                        <div className="flex-1 break-all">
                                            <div className="flex items-center justify-between mb-1 opacity-70">
                                                <span>{log.level.toUpperCase()}</span>
                                                <span>{new Date(log.timestamp).toLocaleString('tr-TR')}</span>
                                            </div>
                                            <p className="leading-relaxed font-semibold">{log.message}</p>
                                        </div>
                                    </div>
                                ))
                            ) : (
                                <div className="text-center py-10 text-slate-500 text-sm flex flex-col items-center gap-2">
                                    <div className="w-12 h-12 bg-slate-800 rounded-full flex items-center justify-center text-slate-600">
                                        <Info size={24} />
                                    </div>
                                    <p>Log kaydı bulunamadı.</p>
                                </div>
                            )}
                        </div>
                    </motion.div>
                </>
            )}
        </AnimatePresence>
    );
}
