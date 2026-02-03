"use client";

import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
    Activity,
    TrendingUp,
    BarChart2,
    DollarSign,
    Clock,
    LogOut,
    X,
    Bot as BotIcon
} from "lucide-react";

const STRATEGY_DETAILS: Record<string, { title: string; description: string; timeline: { title: string; desc: string; icon: any; color: string }[] }> = {
    "strategy-golden-rose": {
        title: "Golden Rose Trend Strategy",
        description: "SMA 111-200-350 trend takibi ve Fibonacci 1.618 kar al hedefli özel strateji. Bitcoin halving döngüleri için optimize edilmiştir.",
        timeline: [
            { title: "Trend Analizi", desc: "SMA 111, SMA 200 ve SMA 350 indikatörleri taranarak uzun vadeli trend yönü ve gücü belirlenir.", icon: Activity, color: "text-slate-400 border-slate-500/20 bg-slate-500/10" },
            { title: "Giriş Sinyali", desc: "Fiyat, belirlenen hareketli ortalamaların (SMA) üzerine çıktığında ve trend onayı alındığında ALIM emri girilir.", icon: TrendingUp, color: "text-emerald-400 border-emerald-500/20 bg-emerald-500/10" },
            { title: "Döngü Tepesi", desc: "Bitcoin halving döngülerine göre hesaplanan tepe noktaları (x2) hedef alınır.", icon: BarChart2, color: "text-blue-400 border-blue-500/20 bg-blue-500/10" },
            { title: "Altın Oran Çıkış", desc: "Fibonacci 1.618 seviyesine ulaşıldığında 'Altın Oran Kar' realizasyonu yapılır ve pozisyon kapatılır.", icon: DollarSign, color: "text-amber-400 border-amber-500/20 bg-amber-500/10" }
        ]
    },
    "strategy-market-buy": {
        title: "Market Maker (Hızlı Al-Sat)",
        description: "Anlık fiyat hareketlerinden yararlanarak kısa vadeli (scalping) işlemler açar.",
        timeline: [
            { title: "Fırsat Yakalama", desc: "Ani fiyat düşüşlerinde (Dip Noktalar) tepki alımları hedeflenir.", icon: Activity, color: "text-slate-400 border-slate-500/20 bg-slate-500/10" },
            { title: "Hızlı Giriş", desc: "Destek noktasına temas edildiğinde milisaniyeler içinde ALIM yapılır.", icon: TrendingUp, color: "text-emerald-400 border-emerald-500/20 bg-emerald-500/10" },
            { title: "Kısa Bekleme", desc: "Pozisyon süresi minimumda tutulur, küçük karlar hedeflenir.", icon: Clock, color: "text-blue-400 border-blue-500/20 bg-blue-500/10" },
            { title: "Çıkış", desc: "%1-%2 gibi hedeflerde anında kar satışı gerçekleştirilir.", icon: DollarSign, color: "text-amber-400 border-amber-500/20 bg-amber-500/10" }
        ]
    },
    "strategy-sma-crossover": {
        title: "SMA Kesişimi (Trend)",
        description: "İki farklı hareketli ortalamanın (Örn: SMA 9 ve SMA 21) kesişimlerini takip eden klasik trend stratejisi.",
        timeline: [
            { title: "Veri Analizi", desc: "Kısa ve uzun vadeli ortalamalar sürekli hesaplanır.", icon: Activity, color: "text-slate-400 border-slate-500/20 bg-slate-500/10" },
            { title: "Golden Cross", desc: "Kısa vadeli ortalama, uzun vadeli ortalamayı yukarı kestiğinde ALIM sinyali üretilir.", icon: TrendingUp, color: "text-emerald-400 border-emerald-500/20 bg-emerald-500/10" },
            { title: "Trend Sürüşü", desc: "Kesişim devam ettiği sürece pozisyon korunur.", icon: Activity, color: "text-blue-400 border-blue-500/20 bg-blue-500/10" },
            { title: "Death Cross", desc: "Kısa vade, uzun vadeyi aşağı kestiğinde SATIŞ sinyali ile çıkılır.", icon: LogOut, color: "text-rose-400 border-rose-500/20 bg-rose-500/10" }
        ]
    }
};

interface StrategyModalProps {
    isOpen: boolean;
    onClose: () => void;
    strategyId: string | null;
}

export function StrategyModal({ isOpen, onClose, strategyId }: StrategyModalProps) {
    if (!isOpen || !strategyId) return null;

    const details = STRATEGY_DETAILS[strategyId] || {
        title: strategyId,
        description: "Bu strateji için detaylı bilgi bulunamadı.",
        timeline: []
    };

    return (
        <div className="fixed inset-0 z-100 flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={onClose}></div>
            <motion.div
                initial={{ opacity: 0, scale: 0.95, y: 20 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.95, y: 20 }}
                className="relative bg-slate-900 border border-white/10 rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl"
            >
                {/* Header */}
                <div className="p-6 pb-4 border-b border-white/5 flex items-start justify-between bg-slate-800/30">
                    <div>
                        <div className="flex items-center gap-2 mb-2">
                            <span className="p-1.5 rounded-lg bg-primary/10 text-primary"><Activity size={18} /></span>
                            <h2 className="text-lg font-bold text-white">{details.title}</h2>
                        </div>
                        <p className="text-xs text-slate-400 leading-relaxed max-w-sm">{details.description}</p>
                    </div>
                    <button onClick={onClose} className="p-2 -mr-2 -mt-2 text-slate-500 hover:text-white hover:bg-white/5 rounded-lg transition-colors">
                        <X size={20} />
                    </button>
                </div>

                {/* Timeline */}
                <div className="p-6 space-y-6 max-h-[60vh] overflow-y-auto">
                    {details.timeline.map((step, index) => (
                        <div key={index} className="relative pl-8 group">
                            {/* Vertical Line */}
                            {index !== details.timeline.length - 1 && (
                                <div className="absolute left-[15px] top-8 bottom-[-24px] w-0.5 bg-slate-800 group-hover:bg-slate-700 transition-colors"></div>
                            )}

                            {/* Node */}
                            <div className={`absolute left-0 top-1 w-8 h-8 rounded-xl flex items-center justify-center border transition-all shadow-lg ${step.color}`}>
                                <step.icon size={14} />
                            </div>

                            {/* Content */}
                            <div>
                                <h3 className="text-sm font-bold text-white mb-1 group-hover:text-primary transition-colors">{step.title}</h3>
                                <p className="text-xs text-slate-400 leading-relaxed bg-slate-950/50 p-3 rounded-lg border border-white/5">
                                    {step.desc}
                                </p>
                            </div>
                        </div>
                    ))}

                    {details.timeline.length === 0 && (
                        <div className="text-center py-8 text-slate-500">
                            <BotIcon size={32} className="mx-auto mb-2 opacity-50" />
                            <p className="text-xs">Strateji detayları hazırlanıyor...</p>
                        </div>
                    )}
                </div>

                {/* Footer */}
                <div className="p-4 bg-slate-950/50 border-t border-white/5 text-center">
                    <p className="text-[10px] text-slate-500">
                        * Piyasa koşullarına göre sinyal süreleri değişiklik gösterebilir.
                    </p>
                </div>
            </motion.div>
        </div>
    );
}
