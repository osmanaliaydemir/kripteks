"use client";

import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X, Target, Zap, TrendingUp, BarChart3, Info, Activity } from "lucide-react";
import { Strategy } from "@/types";

interface StrategyDetailModalProps {
    isOpen: boolean;
    onClose: () => void;
    strategy: Strategy | null;
}

// Strateji teknik detayları
const strategyTechnicalDetails: Record<string, {
    indicators: { name: string; description: string; icon: React.ReactNode }[];
    scoringCriteria: { criterion: string; weight: number; description: string }[];
    idealConditions: string[];
    riskLevel: "Düşük" | "Orta" | "Yüksek";
    timeframe: string;
}> = {
    "strategy-golden-rose": {
        indicators: [
            { name: "SMA 111", description: "111 periyotluk basit hareketli ortalama", icon: <TrendingUp size={14} /> },
            { name: "EMA 50/200", description: "Golden cross tespiti için kısa/uzun vadeli EMA", icon: <Activity size={14} /> },
            { name: "RSI", description: "14 periyotluk relatif güç endeksi", icon: <Zap size={14} /> },
            { name: "Hacim SMA", description: "20 periyotluk hacim ortalaması", icon: <BarChart3 size={14} /> }
        ],
        scoringCriteria: [
            { criterion: "SMA 111 Kırılımı", weight: 30, description: "Fiyat SMA 111'i yukarı kesti" },
            { criterion: "Golden Cross (EMA)", weight: 25, description: "EMA 50 > EMA 200 (boğa yapısı)" },
            { criterion: "RSI Momentum", weight: 20, description: "RSI 50-70 arası güçlü momentum" },
            { criterion: "Hacim Onayı", weight: 15, description: "Hacim ortalamanın 1.3x üzerinde" },
            { criterion: "Trend Devamlılığı", weight: 10, description: "Son 5 mumda yükseliş trendi" }
        ],
        idealConditions: ["Boğa piyasası başlangıcı", "Golden cross oluşumu", "Artan hacim"],
        riskLevel: "Orta",
        timeframe: "4h - 1d"
    },
    "strategy-scout-breakout": {
        indicators: [
            { name: "SMA 111", description: "111 periyotluk basit hareketli ortalama", icon: <TrendingUp size={14} /> },
            { name: "RSI", description: "14 periyotluk relatif güç endeksi", icon: <Activity size={14} /> },
            { name: "Hacim SMA", description: "20 periyotluk hacim ortalaması", icon: <BarChart3 size={14} /> }
        ],
        scoringCriteria: [
            { criterion: "SMA 111 Üzerinde", weight: 30, description: "Fiyat SMA 111'in üzerinde mi" },
            { criterion: "RSI Momentum", weight: 25, description: "RSI 50-70 arasında ideal momentum" },
            { criterion: "Hacim Artışı", weight: 25, description: "Hacim ortalamanın 1.2x üzerinde" },
            { criterion: "Trend Yönü", weight: 20, description: "Son 10 mumda yukarı trend" }
        ],
        idealConditions: ["Boğa piyasası", "Yüksek hacim", "Net yukarı trend"],
        riskLevel: "Orta",
        timeframe: "1h - 4h"
    },
    "strategy-phoenix-momentum": {
        indicators: [
            { name: "RSI", description: "14 periyotluk relatif güç endeksi", icon: <Activity size={14} /> },
            { name: "Bollinger Bands", description: "20 periyot, 2 std sapma", icon: <TrendingUp size={14} /> },
            { name: "Hacim Analizi", description: "Ortalama hacim karşılaştırması", icon: <BarChart3 size={14} /> }
        ],
        scoringCriteria: [
            { criterion: "RSI Yükseliş", weight: 30, description: "RSI 30'dan yukarı ivme kazanıyor" },
            { criterion: "Bollinger Squeeze", weight: 25, description: "Bantlar sıkışmadan sonra genişleme" },
            { criterion: "Hacim Patlaması", weight: 25, description: "Hacim 1.5x üzeri artış" },
            { criterion: "Mum Yapısı", weight: 20, description: "Güçlü yeşil mum formasyonu" }
        ],
        idealConditions: ["Düşük volatilite sonrası", "Hacim artışı", "RSI toparlanması"],
        riskLevel: "Yüksek",
        timeframe: "15m - 1h"
    },
    "strategy-whale-accumulation": {
        indicators: [
            { name: "OBV", description: "On Balance Volume - Birikim/Dağıtım", icon: <BarChart3 size={14} /> },
            { name: "Bollinger Bandwidth", description: "Bant genişliği ile volatilite ölçümü", icon: <TrendingUp size={14} /> },
            { name: "OBV SMA", description: "OBV üzerinde 20 periyot SMA", icon: <Activity size={14} /> }
        ],
        scoringCriteria: [
            { criterion: "Bollinger Squeeze", weight: 25, description: "Bandwidth <%6 (düşük volatilite)" },
            { criterion: "OBV Trend", weight: 30, description: "OBV > OBV SMA (birikim işareti)" },
            { criterion: "Fiyat Konsolidasyonu", weight: 25, description: "Son 10 mumda dar range (<%5)" },
            { criterion: "Hacim Durgunluğu", weight: 20, description: "Hacim ortalamanın altında (sessiz piyasa)" }
        ],
        idealConditions: ["Düşük volatilite", "OBV yükselişte", "Fiyat dar aralıkta"],
        riskLevel: "Orta",
        timeframe: "4h - 1d"
    },
    "strategy-oversold-recovery": {
        indicators: [
            { name: "RSI", description: "14 periyotluk relatif güç endeksi", icon: <Activity size={14} /> },
            { name: "Stochastic RSI", description: "Daha hassas aşırı satım tespiti", icon: <Zap size={14} /> },
            { name: "Destek Seviyesi", description: "Son 20 mumun en düşük noktası", icon: <Target size={14} /> }
        ],
        scoringCriteria: [
            { criterion: "RSI Recovery", weight: 30, description: "RSI 30 altından yükseliyor" },
            { criterion: "Stochastic RSI Dönüşü", weight: 25, description: "K çizgisi 20'yi yukarı kesiyor" },
            { criterion: "Destek Yakınlığı", weight: 20, description: "Fiyat destek seviyesine %2 yakın" },
            { criterion: "Hacim Onayı", weight: 15, description: "Toparlanmada hacim artışı" },
            { criterion: "Bullish Divergence", weight: 10, description: "Fiyat düşük yapar, RSI yükselir" }
        ],
        idealConditions: ["Aşırı satım bölgesi", "Destek yakını", "Hacim artışı"],
        riskLevel: "Düşük",
        timeframe: "1h - 4h"
    },
    "strategy-trend-surfer": {
        indicators: [
            { name: "ADX", description: "Average Directional Index - Trend gücü", icon: <TrendingUp size={14} /> },
            { name: "EMA 50/200", description: "Hızlı ve yavaş üstel ortalamalar", icon: <Activity size={14} /> },
            { name: "+DI / -DI", description: "Yükseliş/düşüş göstergeleri", icon: <BarChart3 size={14} /> }
        ],
        scoringCriteria: [
            { criterion: "ADX Gücü", weight: 35, description: "ADX > 25 (güçlü trend)" },
            { criterion: "DI Yönü", weight: 25, description: "+DI > -DI (yükseliş trendi)" },
            { criterion: "EMA Pozisyonu", weight: 20, description: "EMA 50 > EMA 200 (boğa yapısı)" },
            { criterion: "Fiyat/EMA", weight: 10, description: "Fiyat EMA 50 üzerinde" },
            { criterion: "RSI Momentum", weight: 10, description: "RSI 50-70 arası ideal bölge" }
        ],
        idealConditions: ["Güçlü trend", "Golden cross", "Yükselen +DI"],
        riskLevel: "Orta",
        timeframe: "4h - 1d"
    },
    "strategy-breakout-hunter": {
        indicators: [
            { name: "Bollinger Bands", description: "20 periyot, 2 std sapma", icon: <TrendingUp size={14} /> },
            { name: "ATR", description: "Average True Range - Volatilite ölçer", icon: <Activity size={14} /> },
            { name: "Bandwidth", description: "Bollinger bant genişliği", icon: <BarChart3 size={14} /> }
        ],
        scoringCriteria: [
            { criterion: "Bollinger Squeeze", weight: 25, description: "Sıkışma sonrası bant genişlemesi" },
            { criterion: "ATR Patlaması", weight: 20, description: "ATR önceki ortalamadan 1.5x" },
            { criterion: "Üst Band Kırılımı", weight: 25, description: "Fiyat üst bandı geçti" },
            { criterion: "Hacim Onayı", weight: 20, description: "Kırılımda 2x hacim artışı" },
            { criterion: "Mum Yapısı", weight: 10, description: "Güçlü boğa mumu (%70+ gövde)" }
        ],
        idealConditions: ["Konsolidasyon sonrası", "Hacim patlaması", "Volatilite artışı"],
        riskLevel: "Yüksek",
        timeframe: "15m - 1h"
    },
    "strategy-divergence-detector": {
        indicators: [
            { name: "RSI", description: "14 periyotluk relatif güç endeksi", icon: <Activity size={14} /> },
            { name: "MACD", description: "Moving Average Convergence Divergence", icon: <TrendingUp size={14} /> },
            { name: "MACD Histogram", description: "MACD çizgisi ile sinyal farkı", icon: <BarChart3 size={14} /> }
        ],
        scoringCriteria: [
            { criterion: "RSI Divergence", weight: 35, description: "Fiyat düşük yapar, RSI yükselir" },
            { criterion: "MACD Divergence", weight: 25, description: "MACD histogram uyumsuzluğu" },
            { criterion: "RSI Bölgesi", weight: 20, description: "RSI 40 altı (oversold yakını)" },
            { criterion: "Hacim Onayı", weight: 10, description: "Dönüşte hacim artışı" },
            { criterion: "MACD Pozitif Dönüş", weight: 10, description: "Histogram negatiften yükseliyor" }
        ],
        idealConditions: ["Aşırı satım sonrası", "Fiyat-indikatör uyumsuzluğu", "Trend dönüşü"],
        riskLevel: "Orta",
        timeframe: "1h - 4h"
    }
};

export function StrategyDetailModal({ isOpen, onClose, strategy }: StrategyDetailModalProps) {
    const details = strategy ? strategyTechnicalDetails[strategy.id] : null;

    return (
        <AnimatePresence>
            {isOpen && strategy && (
                <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4"
                    onClick={onClose}
                >
                    <motion.div
                        initial={{ scale: 0.9, opacity: 0 }}
                        animate={{ scale: 1, opacity: 1 }}
                        exit={{ scale: 0.9, opacity: 0 }}
                        onClick={(e) => e.stopPropagation()}
                        className="bg-slate-900/95 border border-white/10 rounded-3xl max-w-2xl w-full max-h-[85vh] overflow-hidden shadow-2xl"
                    >
                        {/* Header */}
                        <div className="p-6 border-b border-white/5 flex items-center justify-between bg-white/2">
                            <div className="flex items-center gap-3">
                                <div className="p-2 bg-primary/10 rounded-xl text-primary border border-primary/20">
                                    <Target size={18} />
                                </div>
                                <div>
                                    <h3 className="font-bold text-white text-sm">{strategy.name}</h3>
                                    <p className="text-[10px] text-slate-500 uppercase tracking-widest">Strateji Detayları</p>
                                </div>
                            </div>
                            <button
                                onClick={onClose}
                                className="p-2 hover:bg-white/10 rounded-xl transition-colors text-slate-400 hover:text-white"
                            >
                                <X size={18} />
                            </button>
                        </div>

                        {/* Content */}
                        <div className="p-6 overflow-y-auto max-h-[calc(85vh-80px)] space-y-6 custom-scrollbar">
                            {/* Description */}
                            <div className="p-4 rounded-2xl bg-primary/5 border border-primary/10">
                                <div className="flex items-start gap-3">
                                    <Info size={16} className="text-primary mt-0.5 shrink-0" />
                                    <p className="text-xs text-slate-300 leading-relaxed">{strategy.description}</p>
                                </div>
                            </div>

                            {details ? (
                                <>
                                    {/* Risk Level & Timeframe */}
                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="p-4 rounded-2xl bg-white/3 border border-white/5">
                                            <label className="text-[9px] uppercase font-bold text-slate-500 tracking-widest">Risk Seviyesi</label>
                                            <div className={`mt-2 text-sm font-bold ${details.riskLevel === "Düşük" ? "text-emerald-400" : details.riskLevel === "Orta" ? "text-amber-400" : "text-rose-400"}`}>
                                                {details.riskLevel}
                                            </div>
                                        </div>
                                        <div className="p-4 rounded-2xl bg-white/3 border border-white/5">
                                            <label className="text-[9px] uppercase font-bold text-slate-500 tracking-widest">Önerilen Zaman Dilimi</label>
                                            <div className="mt-2 text-sm font-bold text-white">{details.timeframe}</div>
                                        </div>
                                    </div>

                                    {/* Technical Indicators */}
                                    <div className="space-y-3">
                                        <h4 className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-2">
                                            <Zap size={12} /> Kullanılan Teknik İndikatörler
                                        </h4>
                                        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                                            {details.indicators.map((ind, idx) => (
                                                <div key={idx} className="p-3 rounded-xl bg-white/3 border border-white/5 space-y-2">
                                                    <div className="flex items-center gap-2">
                                                        <div className="p-1.5 bg-primary/10 rounded-lg text-primary">{ind.icon}</div>
                                                        <span className="text-xs font-bold text-white">{ind.name}</span>
                                                    </div>
                                                    <p className="text-[10px] text-slate-400 leading-relaxed">{ind.description}</p>
                                                </div>
                                            ))}
                                        </div>
                                    </div>

                                    {/* Scoring Criteria */}
                                    <div className="space-y-3">
                                        <h4 className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-2">
                                            <Target size={12} /> Puanlama Kriterleri
                                        </h4>
                                        <div className="space-y-2">
                                            {details.scoringCriteria.map((crit, idx) => (
                                                <div key={idx} className="p-3 rounded-xl bg-white/3 border border-white/5 flex items-center justify-between gap-4">
                                                    <div className="flex-1 min-w-0">
                                                        <div className="text-xs font-bold text-white">{crit.criterion}</div>
                                                        <p className="text-[10px] text-slate-500 truncate">{crit.description}</p>
                                                    </div>
                                                    <div className="shrink-0 flex items-center gap-2">
                                                        <div className="w-16 h-1.5 bg-white/5 rounded-full overflow-hidden">
                                                            <div
                                                                className="h-full bg-primary rounded-full"
                                                                style={{ width: `${crit.weight}%` }}
                                                            />
                                                        </div>
                                                        <span className="text-xs font-mono text-primary w-8 text-right">{crit.weight}%</span>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    </div>

                                    {/* Ideal Conditions */}
                                    <div className="space-y-3">
                                        <h4 className="text-[10px] uppercase font-bold text-slate-500 tracking-widest flex items-center gap-2">
                                            <TrendingUp size={12} /> İdeal Piyasa Koşulları
                                        </h4>
                                        <div className="flex flex-wrap gap-2">
                                            {details.idealConditions.map((cond, idx) => (
                                                <span key={idx} className="px-3 py-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-[10px] font-bold">
                                                    {cond}
                                                </span>
                                            ))}
                                        </div>
                                    </div>
                                </>
                            ) : (
                                <div className="text-center py-8 text-slate-500">
                                    <Info size={32} className="mx-auto mb-2 opacity-40" />
                                    <p className="text-xs">Bu strateji için detaylı teknik bilgi henüz eklenmedi.</p>
                                </div>
                            )}
                        </div>
                    </motion.div>
                </motion.div>
            )}
        </AnimatePresence>
    );
}
