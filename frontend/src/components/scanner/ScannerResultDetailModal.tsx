import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
    X,
    Info,
    TrendingUp,
    Activity,
    CheckCircle2,
    XCircle,
    BarChart2,
    Clock,
    DollarSign
} from 'lucide-react';
import { ScannerResultItem } from '@/types';
import { InfoTooltip } from '@/components/dashboard/InfoTooltip';

interface ScannerResultDetailModalProps {
    isOpen: boolean;
    onClose: () => void;
    result: ScannerResultItem | null;
}

export const ScannerResultDetailModal: React.FC<ScannerResultDetailModalProps> = ({
    isOpen,
    onClose,
    result
}) => {
    if (!result) return null;

    const getScoreColor = (score: number) => {
        if (score > 70) return "text-emerald-400";
        if (score > 40) return "text-amber-400";
        return "text-rose-400";
    };

    const getScoreBg = (score: number) => {
        if (score > 70) return "bg-emerald-500/10 border-emerald-500/20";
        if (score > 40) return "bg-amber-500/10 border-amber-500/20";
        return "bg-rose-500/10 border-rose-500/20";
    };

    return (
        <AnimatePresence>
            {isOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        onClick={onClose}
                        className="absolute inset-0 bg-slate-950/80 backdrop-blur-sm"
                    />

                    <motion.div
                        initial={{ opacity: 0, scale: 0.95, y: 20 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.95, y: 20 }}
                        className="relative w-full max-w-lg bg-slate-900 border border-white/10 rounded-[32px] overflow-hidden shadow-2xl shadow-primary/20"
                    >
                        {/* Header */}
                        <div className="p-6 border-b border-white/5 flex items-center justify-between">
                            <div className="flex items-center gap-4">
                                <div className="p-3 bg-primary/10 rounded-2xl text-primary">
                                    <TrendingUp size={24} />
                                </div>
                                <div>
                                    <h3 className="text-xl font-black text-white tracking-tight">{result.symbol}</h3>
                                    <p className="text-xs text-slate-500 font-medium uppercase tracking-widest">Analiz Detayları</p>
                                </div>
                            </div>
                            <button
                                onClick={onClose}
                                className="p-2 hover:bg-white/5 rounded-xl text-slate-500 hover:text-white transition-all"
                            >
                                <X size={20} />
                            </button>
                        </div>

                        {/* Content */}
                        <div className="p-8 space-y-8">
                            {/* Score & Action Row */}
                            <div className="grid grid-cols-2 gap-4">
                                <div className={`p-6 rounded-[24px] border ${getScoreBg(result.signalScore)} flex flex-col items-center justify-center gap-3`}>
                                    <span className={`text-4xl font-black ${getScoreColor(result.signalScore)}`}>
                                        {Math.round(result.signalScore)}
                                    </span>
                                    <span className="text-[10px] uppercase font-bold tracking-widest opacity-60 flex items-center gap-1">
                                        Sinyal Skoru
                                        <InfoTooltip text="Paritenin seçilen strateji kurallarına (RSI, MA kesişimleri vb.) olan yakınlığını 0-100 arası puanlar. 70 üzeri güçlü alım, 30 altı zayıf sinyaldir." />
                                    </span>
                                </div>
                                <div className="p-6 rounded-[24px] bg-white/5 border border-white/5 flex flex-col items-center justify-center gap-3">
                                    <div className="flex items-center gap-2">
                                        {result.suggestedAction.toString() === "Buy" || result.suggestedAction.toString() === "1" ? (
                                            <CheckCircle2 size={32} className="text-emerald-400" />
                                        ) : result.suggestedAction.toString() === "Sell" || result.suggestedAction.toString() === "2" ? (
                                            <XCircle size={32} className="text-rose-400" />
                                        ) : (
                                            <Clock size={32} className="text-slate-500" />
                                        )}
                                    </div>
                                    <span className="text-[10px] uppercase font-bold tracking-widest text-slate-400 flex items-center gap-1">
                                        Önerilen Aksiyon
                                        <InfoTooltip text="Analiz sonucunda oluşan matematiksel karardır. Skor eşiklerine ve strateji teyidine göre Alım, Satım veya Bekle sinyali üretir." />
                                    </span>
                                    <span className={`text-xs font-black ${result.suggestedAction.toString() === "Buy" || result.suggestedAction.toString() === "1" ? "text-emerald-400" :
                                        result.suggestedAction.toString() === "Sell" || result.suggestedAction.toString() === "2" ? "text-rose-400" : "text-slate-500"
                                        }`}>
                                        {result.suggestedAction.toString() === "Buy" || result.suggestedAction.toString() === "1" ? "ALIM UYGUN" :
                                            result.suggestedAction.toString() === "Sell" || result.suggestedAction.toString() === "2" ? "SATIŞ UYGUN" : "BEKLE"}
                                    </span>
                                </div>
                            </div>

                            {/* Info Grid */}
                            <div className="space-y-4">
                                <div className="flex items-center gap-3 p-4 bg-white/2 border border-white/5 rounded-2xl">
                                    <div className="p-2 bg-slate-800 rounded-lg text-slate-400">
                                        <DollarSign size={16} />
                                    </div>
                                    <div className="flex-1">
                                        <p className="text-[10px] uppercase font-bold text-slate-500 tracking-widest">Son Fiyat</p>
                                        <p className="text-sm font-bold text-white">
                                            ${result.lastPrice.toLocaleString(undefined, {
                                                minimumFractionDigits: result.lastPrice < 0.001 ? 8 : result.lastPrice < 1 ? 4 : 2,
                                                maximumFractionDigits: result.lastPrice < 1 ? 8 : 2
                                            })}
                                        </p>
                                    </div>
                                </div>

                                <div className="flex items-start gap-4 p-5 bg-white/2 border border-white/5 rounded-2xl">
                                    <div className="p-2 bg-slate-800 rounded-lg text-slate-400 mt-1">
                                        <Activity size={16} />
                                    </div>
                                    <div className="flex-1 space-y-2">
                                        <p className="text-[10px] uppercase font-bold text-slate-500 tracking-widest">Analiz Yorumu</p>
                                        <p className="text-sm text-slate-300 leading-relaxed font-medium">
                                            {result.comment || "Bu parite için ek veri yorumu bulunmamaktadır."}
                                        </p>
                                    </div>
                                </div>
                            </div>

                            {/* Footer Info */}
                            <div className="p-4 rounded-2xl bg-primary/5 border border-primary/10 flex items-center gap-3">
                                <Info size={16} className="text-primary" />
                                <p className="text-[10px] text-slate-400 font-medium">
                                    Bu veriler seçilen strateji ve zaman dilimine göre anlık olarak hesaplanmıştır. Yatırım tavsiyesi değildir.
                                </p>
                            </div>
                        </div>

                        {/* Actions */}
                        <div className="p-6 bg-white/2 border-t border-white/5 flex gap-3">
                            <button
                                onClick={onClose}
                                className="flex-1 py-3 bg-white/5 hover:bg-white/10 rounded-xl font-bold text-xs text-white transition-all uppercase tracking-widest"
                            >
                                Kapat
                            </button>
                            <button
                                onClick={() => {
                                    const cleanSymbol = result.symbol.replace("/", "");
                                    window.open(`https://tr.tradingview.com/chart/RbphTzbt/?symbol=BINANCE:${cleanSymbol}`, '_blank');
                                }}
                                className="flex-1 py-3 bg-primary hover:bg-primary-light rounded-xl font-bold text-xs text-white transition-all uppercase tracking-widest flex items-center justify-center gap-2"
                            >
                                <Activity size={14} /> Grafiğe Bak
                            </button>
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>
    );
};
