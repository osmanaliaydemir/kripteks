import { Wallet } from "@/types";
import { Info, DollarSign, Clock } from "lucide-react";

interface Step2Props {
    amount: number;
    setAmount: (val: number) => void;
    selectedInterval: string;
    setSelectedInterval: (val: string) => void;
    wallet: Wallet | null;
    isImmediate: boolean; // For market buy strategy, immediate execution flag

    // Grid Strategy Params (Optional)
    selectedStrategy?: string;
    gridLowerPrice?: string;
    setGridLowerPrice?: (val: string) => void;
    gridUpperPrice?: string;
    setGridUpperPrice?: (val: string) => void;
    gridCount?: string;
    setGridCount?: (val: string) => void;

    // DCA Strategy Params (Optional)
    dcaCount?: string;
    setDcaCount?: (val: string) => void;
    dcaDeviation?: string;
    setDcaDeviation?: (val: string) => void;
    dcaScale?: string;
    setDcaScale?: (val: string) => void;
}

export default function Step2_Configuration({
    amount,
    setAmount,
    selectedInterval,
    setSelectedInterval,
    wallet,
    isImmediate,
    selectedStrategy,
    gridLowerPrice,
    setGridLowerPrice,
    gridUpperPrice,
    setGridUpperPrice,
    gridCount,
    setGridCount,
    dcaCount,
    setDcaCount,
    dcaDeviation,
    setDcaDeviation,
    dcaScale,
    setDcaScale
}: Step2Props) {

    const isInsufficientBalance = wallet && amount > wallet.available_balance;

    // Percent helper
    const setAmountByPercent = (percent: number) => {
        if (wallet?.available_balance) {
            setAmount(Math.floor(wallet.available_balance * (percent / 100)));
        }
    };

    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
            {/* Header */}
            <div className="space-y-1">
                <h3 className="text-lg font-display font-bold text-white">Yapılandırma</h3>
                <p className="text-sm text-slate-400">Botun işlem bütçesini ve analiz zaman dilimini belirleyin.</p>
            </div>

            {/* Time Interval */}
            <div className="space-y-2">
                <label className="text-xs font-bold text-slate-500 uppercase tracking-widest pl-1">Zaman Dilimi</label>
                <div className="relative">
                    <select
                        className="w-full bg-slate-950/50 border border-white/10 rounded-xl pl-10 pr-4 py-3 text-slate-200 outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all appearance-none text-sm font-mono"
                        value={selectedInterval}
                        onChange={(e) => setSelectedInterval(e.target.value)}
                    >
                        {['1m', '3m', '5m', '15m', '30m', '1h', '2h', '4h', '1d'].map(t => <option key={t} value={t}>{t}</option>)}
                    </select>
                    <Clock className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none" size={16} />
                </div>
                <p className="text-[10px] text-slate-500 pl-1">
                    Grafik verileri seçilen bu periyotta analiz edilecektir. Scalping için kısa (1m-15m), trend takibi için uzun (1h-4h) süreler önerilir.
                </p>
            </div>

            {/* Amount */}
            <div className="space-y-3 pt-2">
                <div className="flex justify-between items-center px-1">
                    <label className="text-xs font-bold text-slate-500 uppercase tracking-widest">Yatırım Tutarı (USDT)</label>
                    {wallet && (
                        <span className={`text-[10px] font-mono flex items-center gap-1 ${isInsufficientBalance ? 'text-rose-400' : 'text-slate-500'}`}>
                            Kullanılabilir:
                            <span className="text-slate-300 font-bold">${wallet.available_balance?.toLocaleString('en-US', { maximumFractionDigits: 0 })}</span>
                        </span>
                    )}
                </div>

                <div className="relative group/input">
                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 font-bold group-focus-within/input:text-primary transition-colors">
                        <DollarSign size={16} />
                    </span>
                    <input
                        type="number"
                        value={amount}
                        onChange={(e) => setAmount(Number(e.target.value))}
                        className={`w-full bg-slate-950/50 border rounded-xl pl-10 pr-4 py-3 text-white font-mono text-lg focus:ring-1 transition-all outline-none ${isInsufficientBalance ? 'border-rose-500/50 focus:border-rose-500 focus:ring-rose-500' : 'border-white/10 focus:border-primary focus:ring-primary'}`}
                    />
                </div>

                {/* Percentage Buttons */}
                <div className="flex gap-2">
                    {[25, 50, 75, 100].map(p => (
                        <button
                            key={p}
                            onClick={() => setAmountByPercent(p)}
                            className="flex-1 bg-slate-800/50 hover:bg-slate-700 text-[10px] font-bold py-2 rounded-lg text-slate-400 hover:text-white transition-colors border border-white/5 active:scale-95"
                        >
                            % {p}
                        </button>
                    ))}
                </div>

                {/* Warnings */}
                {isInsufficientBalance && !isImmediate && (
                    <div className="bg-amber-500/10 border border-amber-500/20 rounded-lg p-3 flex gap-2 items-start">
                        <Info className="text-amber-500 shrink-0 mt-0.5" size={14} />
                        <p className="text-[11px] text-amber-500 font-medium leading-relaxed">
                            Yetersiz bakiye. Bot kurulacak, ancak bakiyeniz tamamlanana kadar sinyal gelse bile işlem açamayacak.
                        </p>
                    </div>
                )}
                {isImmediate && isInsufficientBalance && (
                    <div className="bg-rose-500/10 border border-rose-500/20 rounded-lg p-3 flex gap-2 items-start">
                        <Info className="text-rose-500 shrink-0 mt-0.5" size={14} />
                        <p className="text-[11px] text-rose-500 font-medium leading-relaxed">
                            Hemen alım (Market Buy) stratejisi için yeterli bakiyeniz bulunmuyor. Lütfen tutarı düşürün.
                        </p>
                    </div>
                )}
            </div>

            {/* Grid Strategy Specific Configuration */}
            {selectedStrategy === "strategy-grid" && (
                <div className="space-y-4 pt-4 border-t border-white/10">
                    <h4 className="text-sm font-display font-bold text-amber-500">Grid Strateji Ayarları</h4>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <label className="text-xs font-bold text-slate-500 uppercase tracking-widest pl-1">Alt Limit</label>
                            <input
                                type="number"
                                value={gridLowerPrice}
                                onChange={(e) => setGridLowerPrice?.(e.target.value)}
                                className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-white font-mono focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all"
                                placeholder="Örn: 25000"
                            />
                        </div>
                        <div className="space-y-2">
                            <label className="text-xs font-bold text-slate-500 uppercase tracking-widest pl-1">Üst Limit</label>
                            <input
                                type="number"
                                value={gridUpperPrice}
                                onChange={(e) => setGridUpperPrice?.(e.target.value)}
                                className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-white font-mono focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all"
                                placeholder="Örn: 35000"
                            />
                        </div>
                    </div>
                    <div className="space-y-2">
                        <label className="text-xs font-bold text-slate-500 uppercase tracking-widest pl-1">Grid Sayısı (Kademe)</label>
                        <input
                            type="number"
                            value={gridCount}
                            onChange={(e) => setGridCount?.(e.target.value)}
                            className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-white font-mono focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all"
                            placeholder="Örn: 10"
                        />
                        <p className="text-[10px] text-slate-500 pl-1">
                            Belirtilen aralık {gridCount} parçaya bölünecek ve her seviyede alım-satım emri oluşturulacak.
                        </p>
                    </div>
                </div>
            )}

            {/* DCA Strategy Specific Configuration */}
            {selectedStrategy === "strategy-dca" && (
                <div className="space-y-4 pt-4 border-t border-white/10">
                    <h4 className="text-sm font-display font-bold text-amber-500">DCA Bot Ayarları</h4>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <label className="text-xs font-bold text-slate-500 uppercase tracking-widest pl-1">Düşüş Sapması (%)</label>
                            <input
                                type="number"
                                value={dcaDeviation}
                                onChange={(e) => setDcaDeviation?.(e.target.value)}
                                className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-white font-mono focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all"
                                placeholder="Örn: 2"
                            />
                            <p className="text-[10px] text-slate-500 pl-1">
                                Maliyet ortalamasının her %{dcaDeviation} altına düştüğünde alım yapar.
                            </p>
                        </div>
                        <div className="space-y-2">
                            <label className="text-xs font-bold text-slate-500 uppercase tracking-widest pl-1">Miktar Çarpanı (X)</label>
                            <input
                                type="number"
                                value={dcaScale}
                                onChange={(e) => setDcaScale?.(e.target.value)}
                                className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-white font-mono focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all"
                                placeholder="Örn: 2"
                            />
                        </div>
                    </div>
                    <div className="space-y-2">
                        <label className="text-xs font-bold text-slate-500 uppercase tracking-widest pl-1">Maksimum Ek Alım (Step)</label>
                        <input
                            type="number"
                            value={dcaCount}
                            onChange={(e) => setDcaCount?.(e.target.value)}
                            className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-white font-mono focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all"
                            placeholder="Örn: 5"
                        />
                        <p className="text-[10px] text-slate-500 pl-1">
                            En fazla {dcaCount} kere maliyet düşürme alımı yapacak (Martingale).
                        </p>
                    </div>
                </div>
            )}
        </div>
    );
}
