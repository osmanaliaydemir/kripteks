import { Coin, Strategy } from "@/types";
import SearchableSelect from "@/components/ui/SearchableSelect";
import { Activity, Zap, TrendingUp, BarChart2, Info } from "lucide-react";
import { motion } from "framer-motion";

interface Step1Props {
    coins: Coin[];
    strategies: Strategy[];
    selectedCoin: string;
    setSelectedCoin: (coin: string) => void;
    selectedStrategy: string;
    setSelectedStrategy: (strategyId: string) => void;
    isLoadingCoins: boolean;
    refreshCoins: () => void;
}

const STRATEGY_ICONS: Record<string, any> = {
    "strategy-golden-rose": Activity,
    "strategy-market-buy": Zap,
    "strategy-sma-crossover": TrendingUp,
    "default": BarChart2
};

const STRATEGY_COLORS: Record<string, string> = {
    "strategy-golden-rose": "text-primary bg-primary/10 border-primary/20",
    "strategy-market-buy": "text-amber-500 bg-amber-500/10 border-amber-500/20",
    "strategy-sma-crossover": "text-emerald-500 bg-emerald-500/10 border-emerald-500/20",
    "default": "text-slate-400 bg-slate-800 border-white/5"
};

export default function Step1_Strategy({
    coins,
    strategies,
    selectedCoin,
    setSelectedCoin,
    selectedStrategy,
    setSelectedStrategy,
    isLoadingCoins,
    refreshCoins
}: Step1Props) {
    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
            {/* Header */}
            <div className="space-y-1">
                <h3 className="text-lg font-display font-bold text-white">Varlık ve Strateji Seçimi</h3>
                <p className="text-sm text-slate-400">İşlem yapmak istediğiniz kripto çiftini ve kullanmak istediğiniz algoritmayı belirleyin.</p>
            </div>

            {/* Coin Selection */}
            <div className="space-y-2">
                <label className="text-xs font-bold text-slate-500 uppercase tracking-widest pl-1">Kripto Varlık</label>
                <div className="relative z-20">
                    <SearchableSelect
                        options={coins.map(c => ({ id: c.symbol, label: c.symbol, ...c }))}
                        value={selectedCoin}
                        onChange={setSelectedCoin}
                        placeholder="Coin Seçiniz (Örn: BTC/USDT)..."
                        onOpen={refreshCoins}
                        isLoading={isLoadingCoins}
                    />
                </div>
            </div>

            {/* Strategy Selection */}
            <div className="space-y-3">
                <label className="text-xs font-bold text-slate-500 uppercase tracking-widest pl-1">Strateji Algoritması</label>
                <div className="grid grid-cols-1 gap-3 max-h-[300px] overflow-y-auto pr-1">
                    {strategies.map((strategy) => {
                        const isSelected = selectedStrategy === strategy.id;
                        const Icon = STRATEGY_ICONS[strategy.id] || STRATEGY_ICONS["default"];
                        const colorClass = STRATEGY_COLORS[strategy.id] || STRATEGY_COLORS["default"];

                        return (
                            <motion.div
                                key={strategy.id}
                                onClick={() => setSelectedStrategy(strategy.id)}
                                whileHover={{ scale: 1.01 }}
                                whileTap={{ scale: 0.99 }}
                                className={`cursor-pointer rounded-xl p-4 border transition-all relative overflow-hidden group ${isSelected
                                    ? 'bg-slate-800/80 border-primary ring-1 ring-primary/50 shadow-lg shadow-primary/10'
                                    : 'bg-slate-900/40 border-white/5 hover:bg-slate-800 hover:border-white/10'
                                    }`}
                            >
                                <div className="flex items-start gap-4 relative z-10">
                                    <div className={`p-3 rounded-xl border ${colorClass} transition-colors`}>
                                        <Icon size={20} />
                                    </div>
                                    <div className="flex-1">
                                        <div className="flex justify-between items-center mb-1">
                                            <h4 className={`font-bold text-sm ${isSelected ? 'text-white' : 'text-slate-300'}`}>
                                                {strategy.name}
                                            </h4>
                                            {isSelected && (
                                                <span className="text-[10px] font-bold bg-primary text-slate-900 px-2 py-0.5 rounded-full">
                                                    SEÇİLDİ
                                                </span>
                                            )}
                                        </div>
                                        <p className="text-xs text-slate-500 leading-relaxed line-clamp-2 group-hover:line-clamp-none transition-all">
                                            {strategy.description || "Bu strateji için detaylı açıklama bulunmuyor."}
                                        </p>
                                    </div>
                                </div>

                                {isSelected && (
                                    <div className="absolute inset-0 bg-primary/5 pointer-events-none"></div>
                                )}
                            </motion.div>
                        );
                    })}
                </div>
            </div>
        </div>
    );
}
