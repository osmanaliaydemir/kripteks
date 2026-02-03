import { TrendingUp, Info } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

interface Step3Props {
    takeProfit: string;
    setTakeProfit: (val: string) => void;
    stopLoss: string;
    setStopLoss: (val: string) => void;
    isTrailingEnabled: boolean;
    setIsTrailingEnabled: (val: boolean) => void;
    trailingDistance: string;
    setTrailingDistance: (val: string) => void;
}

function InfoBox({ title, text }: { title: string; text: string }) {
    return (
        <div className="group relative ml-1 inline-flex">
            <Info size={12} className="text-slate-500 cursor-help hover:text-slate-300" />
            <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-48 p-2 bg-slate-900 border border-white/10 rounded-lg shadow-xl text-[10px] text-slate-300 opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-50">
                <span className="font-bold text-white block mb-0.5">{title}</span>
                {text}
            </div>
        </div>
    );
}

export default function Step3_RiskManagement({
    takeProfit,
    setTakeProfit,
    stopLoss,
    setStopLoss,
    isTrailingEnabled,
    setIsTrailingEnabled,
    trailingDistance,
    setTrailingDistance
}: Step3Props) {
    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
            {/* Header */}
            <div className="space-y-1">
                <h3 className="text-lg font-display font-bold text-white">Risk Yönetimi</h3>
                <p className="text-sm text-slate-400">Kar hedefleri ve zarar durdurma mekanizmalarını ayarlayın.</p>
            </div>

            {/* TP / SL Grid */}
            <div className="grid grid-cols-2 gap-4">
                {/* Take Profit */}
                <div className="space-y-2">
                    <div className="flex items-center gap-1">
                        <label className="text-xs font-bold text-emerald-500 uppercase tracking-widest pl-1">Kar Al %</label>
                        <InfoBox title="Kar Hedefi" text="Fiyat bu oranda yükseldiğinde pozisyon otomatik kapanır." />
                    </div>
                    <div className="relative">
                        <input
                            type="number"
                            placeholder="Opsiyonel"
                            className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-slate-200 text-sm outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500/50 transition-all font-mono"
                            value={takeProfit}
                            onChange={(e) => setTakeProfit(e.target.value)}
                        />
                        <span className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-500 font-bold">%</span>
                    </div>
                </div>

                {/* Stop Loss */}
                <div className="space-y-2">
                    <div className="flex items-center gap-1">
                        <label className="text-xs font-bold text-rose-500 uppercase tracking-widest pl-1">Zarar Durdur %</label>
                        <InfoBox title="Zarar Kes" text="Fiyat bu oranda düştüğünde işlem zararına kapatılır." />
                    </div>
                    <div className="relative">
                        <input
                            type="number"
                            placeholder="Opsiyonel"
                            className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-slate-200 text-sm outline-none focus:border-rose-500 focus:ring-1 focus:ring-rose-500/50 transition-all font-mono"
                            value={stopLoss}
                            onChange={(e) => setStopLoss(e.target.value)}
                        />
                        <span className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-500 font-bold">%</span>
                    </div>
                </div>
            </div>

            {/* Trailing Stop Card */}
            <div className={`p-4 rounded-xl border transition-all duration-300 ${isTrailingEnabled ? 'bg-amber-500/5 border-amber-500/30' : 'bg-slate-950/30 border-white/5'}`}>
                <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-3">
                        <div className={`p-2 rounded-lg transition-colors ${isTrailingEnabled ? 'bg-amber-500 text-slate-900' : 'bg-slate-800 text-slate-500'}`}>
                            <TrendingUp size={20} />
                        </div>
                        <div>
                            <div className="flex items-center gap-2">
                                <h4 className={`font-bold text-sm ${isTrailingEnabled ? 'text-white' : 'text-slate-400'}`}>İz Süren Stop (Trailing)</h4>
                                {isTrailingEnabled && <span className="text-[10px] font-bold bg-amber-500 text-slate-900 px-1.5 rounded">AKTİF</span>}
                            </div>
                            <p className="text-xs text-slate-500 mt-0.5">Kârı takip ederek stop seviyesini yükseltir.</p>
                        </div>
                    </div>

                    <button
                        onClick={() => setIsTrailingEnabled(!isTrailingEnabled)}
                        className={`w-12 h-6 rounded-full transition-all relative shadow-inner ${isTrailingEnabled ? 'bg-amber-500' : 'bg-slate-700'}`}
                    >
                        <motion.div
                            animate={{ x: isTrailingEnabled ? 26 : 2 }}
                            className="absolute top-1 w-4 h-4 bg-white rounded-full shadow-md"
                        />
                    </button>
                </div>

                <AnimatePresence>
                    {isTrailingEnabled && (
                        <motion.div
                            initial={{ height: 0, opacity: 0 }}
                            animate={{ height: "auto", opacity: 1 }}
                            exit={{ height: 0, opacity: 0 }}
                            className="overflow-hidden"
                        >
                            <div className="pt-2 border-t border-amber-500/20 space-y-4">
                                <div className="space-y-3">
                                    <div className="flex justify-between items-end">
                                        <label className="text-xs font-bold text-amber-500/80 uppercase tracking-wide">Takip Mesafesi</label>
                                        <span className="text-2xl font-mono font-bold text-white">%{trailingDistance}</span>
                                    </div>

                                    <div className="relative h-6 flex items-center">
                                        <input
                                            type="range"
                                            min="0.5"
                                            max="10"
                                            step="0.1"
                                            value={trailingDistance}
                                            onChange={(e) => setTrailingDistance(e.target.value)}
                                            className="w-full h-2 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-amber-500 relative z-10"
                                        />
                                        <div className="absolute left-0 right-0 h-2 bg-slate-800 rounded-lg overflow-hidden">
                                            <div className="h-full bg-amber-500/20" style={{ width: `${(Number(trailingDistance) / 10) * 100}%` }}></div>
                                        </div>
                                    </div>

                                    <div className="flex justify-between text-[10px] text-slate-500 font-mono">
                                        <span>%0.5 (Dar)</span>
                                        <span>%5.0 (Orta)</span>
                                        <span>%10.0 (Geniş)</span>
                                    </div>
                                </div>

                                <div className="bg-slate-900/50 p-3 rounded-lg border border-white/5">
                                    <p className="text-[11px] text-slate-400 leading-relaxed">
                                        <strong className="text-amber-500">Nasıl Çalışır?</strong> Fiyat yukarı çıktıkça stop seviyesi de aynı oranda yükselir.
                                        Fiyat zirveden <strong>%{trailingDistance}</strong> düştüğü anda kazancınızı korumak için satış yapılır.
                                    </p>
                                </div>
                            </div>
                        </motion.div>
                    )}
                </AnimatePresence>
            </div>
        </div>
    );
}
