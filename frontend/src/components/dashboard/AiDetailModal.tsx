"use client";

import { X, Brain, TrendingUp, TrendingDown, Minus, Sparkles, Newspaper } from "lucide-react";
import { useEffect, useState } from "react";
import { createPortal } from "react-dom";

interface ProviderDetail {
    providerName: string;
    score: number;
    action: string;
    summary: string;
    reasoning: string;
}

interface AiDetailModalProps {
    isOpen: boolean;
    onClose: () => void;
    providerDetails: ProviderDetail[];
    consensusScore: number;
    analyzedAt: string;
}

export default function AiDetailModal({ isOpen, onClose, providerDetails, consensusScore, analyzedAt }: AiDetailModalProps) {
    const [isVisible, setIsVisible] = useState(false);
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    useEffect(() => {
        if (isOpen) {
            setIsVisible(true);
            document.body.style.overflow = 'hidden';
        } else {
            document.body.style.overflow = 'unset';
            const timeout = setTimeout(() => setIsVisible(false), 300);
            return () => clearTimeout(timeout);
        }
    }, [isOpen]);

    if (!mounted || (!isVisible && !isOpen)) return null;

    const getScoreColor = (score: number) => {
        if (score > 0.3) return "text-emerald-400";
        if (score < -0.3) return "text-rose-400";
        return "text-amber-400";
    };

    const getScoreBg = (score: number) => {
        if (score > 0.3) return "bg-emerald-500/10 border-emerald-500/20";
        if (score < -0.3) return "bg-rose-500/10 border-rose-500/20";
        return "bg-amber-500/10 border-amber-500/20";
    };

    const getActionColor = (action: string) => {
        if (action === "AL" || action === "BUY") return "bg-emerald-500/10 text-emerald-400 border-emerald-500/20";
        if (action === "PANİK SAT" || action === "PANIC SELL") return "bg-rose-500/10 text-rose-400 border-rose-500/20";
        if (action === "SAT" || action === "SELL") return "bg-orange-500/10 text-orange-400 border-orange-500/20";
        return "bg-slate-500/10 text-slate-400 border-slate-500/20";
    };

    const getProviderIcon = (name: string) => {
        if (name.toLowerCase().includes("deepseek")) return "🧠";
        if (name.toLowerCase().includes("gemini")) return "✨";
        return "🤖";
    };

    const modalContent = (
        <div
            className={`fixed inset-0 flex items-center justify-center p-4 transition-all duration-300 ${isOpen ? 'opacity-100' : 'opacity-0'}`}
            style={{ zIndex: 99999 }}
            onClick={onClose}
        >
            {/* Backdrop */}
            <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" />

            {/* Modal */}
            <div
                className={`relative w-full max-w-2xl max-h-[85vh] overflow-y-auto bg-slate-950 border border-white/10 rounded-3xl shadow-2xl transform transition-all duration-300 ${isOpen ? 'scale-100 translate-y-0' : 'scale-95 translate-y-4'}`}
                onClick={(e) => e.stopPropagation()}
            >
                {/* Header */}
                <div className="sticky top-0 bg-slate-950/95 backdrop-blur-md border-b border-white/5 p-6 flex items-center justify-between z-10">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-indigo-500/10 rounded-xl border border-indigo-500/20">
                            <Brain size={24} className="text-indigo-400" />
                        </div>
                        <div>
                            <h2 className="text-lg font-bold text-white">AI Analiz Detayları</h2>
                            <p className="text-xs text-slate-500 mt-0.5">
                                {providerDetails.length} model tarafından analiz edildi
                            </p>
                        </div>
                    </div>
                    <button
                        onClick={onClose}
                        className="p-2 hover:bg-white/5 rounded-xl transition-colors"
                    >
                        <X size={20} className="text-slate-400" />
                    </button>
                </div>

                {/* Content */}
                <div className="p-6 space-y-6">
                    {/* Consensus Summary */}
                    <div className="bg-gradient-to-br from-indigo-500/10 to-purple-500/10 border border-indigo-500/20 rounded-2xl p-5">
                        <div className="flex items-center justify-between mb-4">
                            <div className="flex items-center gap-2">
                                <Sparkles size={16} className="text-indigo-400" />
                                <span className="text-sm font-bold text-indigo-300 uppercase tracking-wider">Konsensüs Sonucu</span>
                            </div>
                            <span className="text-[10px] text-slate-500 font-mono">
                                {new Date(analyzedAt).toLocaleString('tr-TR')}
                            </span>
                        </div>
                        <div className="flex items-center gap-4">
                            <div className={`text-4xl font-black font-mono ${getScoreColor(consensusScore)}`}>
                                {consensusScore > 0 ? '+' : ''}{consensusScore.toFixed(2)}
                            </div>
                            <div className="flex-1">
                                <div className="h-2 bg-slate-800 rounded-full overflow-hidden">
                                    <div
                                        className={`h-full transition-all duration-500 ${consensusScore > 0 ? 'bg-emerald-500' : 'bg-rose-500'}`}
                                        style={{ width: `${Math.abs(consensusScore) * 50}%`, marginLeft: consensusScore < 0 ? `${50 - Math.abs(consensusScore) * 50}%` : '50%' }}
                                    />
                                </div>
                                <div className="flex justify-between mt-1 text-[10px] text-slate-600 font-mono">
                                    <span>-1.0</span>
                                    <span>0</span>
                                    <span>+1.0</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Provider Cards */}
                    <div className="space-y-4">
                        <h3 className="text-sm font-bold text-slate-400 uppercase tracking-wider flex items-center gap-2">
                            <span>Model Bazında Analizler</span>
                        </h3>

                        {providerDetails.map((provider, index) => (
                            <div
                                key={index}
                                className="bg-slate-900/50 border border-white/5 rounded-2xl p-5 space-y-4 hover:border-white/10 transition-colors"
                            >
                                {/* Provider Header */}
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center gap-3">
                                        <span className="text-2xl">{getProviderIcon(provider.providerName)}</span>
                                        <div>
                                            <h4 className="font-bold text-white">{provider.providerName}</h4>
                                            <p className="text-[10px] text-slate-500 uppercase tracking-wider">Yapay Zeka Modeli</p>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-3">
                                        <div className={`px-3 py-1.5 rounded-full border text-xs font-bold ${getActionColor(provider.action)}`}>
                                            {provider.action}
                                        </div>
                                        <div className={`px-3 py-1.5 rounded-xl border ${getScoreBg(provider.score)}`}>
                                            <span className={`text-sm font-mono font-bold ${getScoreColor(provider.score)}`}>
                                                {provider.score > 0 ? '+' : ''}{provider.score.toFixed(2)}
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                {/* Score Bar */}
                                <div className="h-1.5 bg-slate-800 rounded-full overflow-hidden">
                                    <div
                                        className={`h-full rounded-full transition-all duration-700 ${provider.score > 0 ? 'bg-emerald-500' : provider.score < 0 ? 'bg-rose-500' : 'bg-amber-500'}`}
                                        style={{ width: `${((provider.score + 1) / 2) * 100}%` }}
                                    />
                                </div>

                                {/* Summary */}
                                <div className="bg-slate-800/50 rounded-xl p-4 border border-white/5">
                                    <div className="flex items-center gap-2 mb-2">
                                        <Brain size={12} className="text-indigo-400" />
                                        <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">AI Yorumu</span>
                                    </div>
                                    <p className="text-sm text-slate-200 leading-relaxed">
                                        {provider.summary}
                                    </p>
                                </div>

                                {/* Reasoning */}
                                <div className="bg-slate-800/30 rounded-xl p-4 border border-white/5">
                                    <div className="flex items-center gap-2 mb-2">
                                        <Newspaper size={12} className="text-amber-400" />
                                        <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Analiz Edilen Veriler</span>
                                    </div>
                                    <p className="text-xs text-slate-400 leading-relaxed">
                                        {provider.reasoning}
                                    </p>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );

    return createPortal(modalContent, document.body);
}
