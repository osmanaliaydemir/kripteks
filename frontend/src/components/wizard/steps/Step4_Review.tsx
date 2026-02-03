import { Zap, TrendingUp, AlertTriangle } from "lucide-react";
import { Strategy } from "@/types";

interface Step4Props {
    selectedCoin: string;
    selectedStrategyId: string;
    strategies: Strategy[];
    amount: number;
    selectedInterval: string;
    takeProfit: string;
    stopLoss: string;
    isTrailingEnabled: boolean;
    trailingDistance: string;
    onStart: () => void;
    isStarting: boolean;
}

export default function Step4_Review({
    selectedCoin,
    selectedStrategyId,
    strategies,
    amount,
    selectedInterval,
    takeProfit,
    stopLoss,
    isTrailingEnabled,
    trailingDistance,
    onStart,
    isStarting
}: Step4Props) {
    const strategyName = strategies.find(s => s.id === selectedStrategyId)?.name || selectedStrategyId;

    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
            {/* Header */}
            <div className="space-y-1 text-center">
                <div className="w-16 h-16 bg-gradient-to-br from-primary to-amber-500 rounded-full mx-auto flex items-center justify-center shadow-lg shadow-primary/20 mb-4 animate-pulse">
                    <Zap size={32} className="text-white fill-white" />
                </div>
                <h3 className="text-2xl font-display font-bold text-white">Hazır mısınız?</h3>
                <p className="text-sm text-slate-400">Aşağıdaki ayarlar ile otonom işlem botu başlatılacak.</p>
            </div>

            {/* Summary Card */}
            <div className="bg-slate-900/50 rounded-2xl border border-white/5 overflow-hidden">
                <div className="p-4 border-b border-white/5 flex items-center justify-between">
                    <span className="text-xs font-bold text-slate-500 uppercase tracking-widest">BOT ÖZETİ</span>
                    <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/10 text-emerald-500 border border-emerald-500/20">
                        {isTrailingEnabled ? 'AKILLI STOP' : 'STANDART'}
                    </span>
                </div>

                <div className="p-4 space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <p className="text-[10px] text-slate-500 font-bold uppercase mb-0.5">Varlık</p>
                            <p className="text-lg font-bold text-white font-mono">{selectedCoin}</p>
                        </div>
                        <div className="text-right">
                            <p className="text-[10px] text-slate-500 font-bold uppercase mb-0.5">Yatırım</p>
                            <p className="text-lg font-bold text-primary font-mono">${amount}</p>
                        </div>
                    </div>

                    <div className="h-px bg-white/5"></div>

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <p className="text-[10px] text-slate-500 font-bold uppercase mb-0.5">Strateji</p>
                            <p className="text-sm font-medium text-slate-300">{strategyName}</p>
                        </div>
                        <div className="text-right">
                            <p className="text-[10px] text-slate-500 font-bold uppercase mb-0.5">Zaman Dilimi</p>
                            <p className="text-sm font-medium text-slate-300 font-mono">{selectedInterval}</p>
                        </div>
                    </div>

                    <div className="h-px bg-white/5"></div>

                    <div className="grid grid-cols-3 gap-2">
                        <div className="bg-slate-950/50 p-2 rounded-lg border border-white/5">
                            <p className="text-[9px] text-emerald-500 font-bold uppercase mb-1">Kar Hedefi</p>
                            <p className="text-sm font-mono text-white">{takeProfit ? `%${takeProfit}` : '-'}</p>
                        </div>
                        <div className="bg-slate-950/50 p-2 rounded-lg border border-white/5">
                            <p className="text-[9px] text-rose-500 font-bold uppercase mb-1">Zarar Kes</p>
                            <p className="text-sm font-mono text-white">{stopLoss ? `%${stopLoss}` : '-'}</p>
                        </div>
                        <div className="bg-slate-950/50 p-2 rounded-lg border border-white/5">
                            <p className="text-[9px] text-amber-500 font-bold uppercase mb-1">Trailing</p>
                            <p className="text-sm font-mono text-white">{isTrailingEnabled ? `%${trailingDistance}` : 'KAPALI'}</p>
                        </div>
                    </div>
                </div>
            </div>

            {/* Warning */}
            <div className="flex gap-3 p-3 rounded-xl bg-amber-500/5 border border-amber-500/10">
                <AlertTriangle size={18} className="text-amber-500 shrink-0" />
                <p className="text-[11px] text-slate-400 leading-relaxed">
                    Bot başlatıldıktan sonra piyasa koşullarına göre otomatik alım-satım yapacaktır.
                    <strong className="text-slate-300"> İşlem ücretleri (Commission)</strong> ve <strong className="text-slate-300">Slippage</strong> kâr oranını etkileyebilir.
                </p>
            </div>

            <div className="pt-2">
                <button
                    onClick={onStart}
                    disabled={isStarting}
                    className="w-full bg-linear-to-r from-primary to-amber-500 hover:to-amber-400 text-slate-900 font-display font-bold py-4 rounded-xl shadow-lg shadow-primary/20 active:scale-[0.98] transition-all flex justify-center items-center gap-2"
                >
                    {isStarting ? (
                        <>Başlatılıyor...</>
                    ) : (
                        <>
                            <Zap className="fill-current" size={20} />
                            BOTU BAŞLAT
                        </>
                    )}
                </button>
            </div>
        </div>
    );
}
