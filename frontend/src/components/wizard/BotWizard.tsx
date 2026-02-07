import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { X, ChevronRight, ChevronLeft } from "lucide-react";
import { Coin, Strategy, Wallet } from "@/types";
import { useSignalR } from "@/context/SignalRContext";
import Step1_Strategy from "./steps/Step1_Strategy";
import Step2_Configuration from "./steps/Step2_Configuration";
import Step3_RiskManagement from "./steps/Step3_RiskManagement";
import Step4_Review from "./steps/Step4_Review";

interface BotWizardProps {
    coins: Coin[];
    strategies: Strategy[];
    wallet: Wallet | null;
    onBotCreate: (payload: any) => Promise<void>;
    onCancel: () => void;
    isCoinsLoading: boolean;
    refreshCoins: () => void;
}

export default function BotWizard({
    coins,
    strategies,
    wallet,
    onBotCreate,
    onCancel,
    isCoinsLoading,
    refreshCoins
}: BotWizardProps) {
    const { isConnected: isSignalRConnected } = useSignalR();
    const [step, setStep] = useState(1);
    const [isStatusVisible, setIsStatusVisible] = useState(false);
    const [statusTimeout, setStatusTimeout] = useState<NodeJS.Timeout | null>(null);

    // Form State
    const [selectedCoin, setSelectedCoin] = useState("BTC/USDT");
    const [selectedStrategy, setSelectedStrategy] = useState("");
    const [amount, setAmount] = useState(100);
    const [selectedInterval, setSelectedInterval] = useState("1h");
    const [takeProfit, setTakeProfit] = useState("");
    const [stopLoss, setStopLoss] = useState("");
    const [isTrailingEnabled, setIsTrailingEnabled] = useState(false);
    const [trailingDistance, setTrailingDistance] = useState("2.5");
    const [isStarting, setIsStarting] = useState(false);

    // Grid Strategy Params
    const [gridLowerPrice, setGridLowerPrice] = useState("");
    const [gridUpperPrice, setGridUpperPrice] = useState("");
    const [gridCount, setGridCount] = useState("10");

    // DCA Strategy Params
    const [dcaCount, setDcaCount] = useState("5");
    const [dcaDeviation, setDcaDeviation] = useState("2");
    const [dcaScale, setDcaScale] = useState("2");

    // Initial default strategy selection
    useEffect(() => {
        if (strategies.length > 0 && !selectedStrategy) {
            setSelectedStrategy(strategies[0].id);
        }
    }, [strategies]);

    // Strategy defaults
    useEffect(() => {
        if (selectedStrategy === "strategy-market-buy") setSelectedInterval("1m");
        else if (selectedStrategy === "strategy-golden-rose") setSelectedInterval("1h");
        else if (selectedStrategy === "strategy-golden-cross") setSelectedInterval("4h");
        else if (selectedStrategy === "strategy-sma-crossover") setSelectedInterval("15m");
    }, [selectedStrategy]);

    const handleNext = () => setStep(prev => prev + 1);
    const handleBack = () => setStep(prev => prev - 1);

    const handleStart = async () => {
        setIsStarting(true);
        const payload = {
            symbol: selectedCoin,
            strategyId: selectedStrategy,
            amount: amount,
            interval: selectedInterval,
            takeProfit: takeProfit ? Number(takeProfit) : null,
            stopLoss: stopLoss ? Number(stopLoss) : null,
            isTrailingStop: isTrailingEnabled,
            trailingStopDistance: isTrailingEnabled ? Number(trailingDistance) : null,
            strategyParameters: selectedStrategy === 'strategy-grid' ? {
                lowerPrice: gridLowerPrice,
                upperPrice: gridUpperPrice,
                gridCount: gridCount
            } : selectedStrategy === 'strategy-dca' ? {
                dcaCount: dcaCount,
                priceDeviation: dcaDeviation,
                amountScale: dcaScale
            } : null
        };

        await onBotCreate(payload);
        setIsStarting(false);
    };

    // Validation
    const isStep1Valid = !!selectedCoin && !!selectedStrategy;
    const isImmediate = selectedStrategy === "strategy-market-buy";
    const isInsufficientBalance = wallet && amount > wallet.available_balance;
    const isGridValid = selectedStrategy !== "strategy-grid" || (!!gridLowerPrice && !!gridUpperPrice && !!gridCount);
    const isDcaValid = selectedStrategy !== "strategy-dca" || (!!dcaCount && !!dcaDeviation && !!dcaScale);
    const isStep2Valid = amount > 0 && (!isImmediate || !isInsufficientBalance) && isGridValid && isDcaValid;

    return (
        <div className="w-full max-w-4xl mx-auto">
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="bg-slate-950 border border-white/10 rounded-3xl overflow-hidden shadow-2xl flex flex-col min-h-[600px]"
            >
                {/* Header / Progress */}
                <div className="px-6 py-6 border-b border-white/5 bg-slate-900/50 flex items-center justify-between shrink-0">
                    <div>
                        <h2 className="text-xl font-display font-bold text-white tracking-widest">Yeni Bot Oluştur</h2>
                        <div className="flex items-center gap-2 mt-2">
                            {[1, 2, 3, 4].map((s) => (
                                <div key={s} className={`h-1.5 rounded-full transition-all duration-500 ${s <= step ? 'w-8 bg-primary' : 'w-2 bg-slate-800'}`}></div>
                            ))}
                        </div>
                    </div>

                    <div className="flex items-center gap-4">
                        {/* System Status Icon */}
                        <div
                            className="flex items-center gap-0 px-2 py-1 bg-slate-900/40 rounded-full border border-white/5 backdrop-blur-sm transition-all hover:bg-slate-800/50 cursor-pointer"
                            onMouseEnter={() => {
                                setIsStatusVisible(true);
                                if (statusTimeout) clearTimeout(statusTimeout);
                            }}
                            onMouseLeave={() => {
                                const timeout = setTimeout(() => setIsStatusVisible(false), 3000);
                                setStatusTimeout(timeout);
                            }}
                        >
                            <div className="relative flex h-2 w-2 shrink-0 my-0.5 mx-0.5">
                                <span className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${isSignalRConnected ? 'bg-emerald-400' : 'bg-rose-500'}`}></span>
                                <span className={`relative inline-flex rounded-full h-2 w-2 ${isSignalRConnected ? 'bg-emerald-500' : 'bg-rose-500'}`}></span>
                            </div>
                            <div className={`overflow-hidden transition-all duration-500 ease-in-out flex items-center ${isStatusVisible ? 'max-w-[200px] opacity-100' : 'max-w-0 opacity-0'}`}>
                                <span className="text-[10px] text-slate-300 font-medium tracking-wide whitespace-nowrap pl-2">
                                    {isSignalRConnected ? 'SİSTEM ÇEVRİMİÇİ' : 'BAĞLANTI YOK'}
                                </span>
                            </div>
                        </div>

                        <button onClick={onCancel} className="p-2 -mr-2 text-slate-500 hover:text-white hover:bg-white/5 rounded-xl transition-colors">
                            <X size={24} />
                        </button>
                    </div>
                </div>

                {/* Body */}
                <div className="p-6 md:p-8 flex-1">
                    {step === 1 && (
                        <Step1_Strategy
                            coins={coins}
                            strategies={strategies}
                            selectedCoin={selectedCoin}
                            setSelectedCoin={setSelectedCoin}
                            selectedStrategy={selectedStrategy}
                            setSelectedStrategy={setSelectedStrategy}
                            isLoadingCoins={isCoinsLoading}
                            refreshCoins={refreshCoins}
                        />
                    )}
                    {step === 2 && (
                        <Step2_Configuration
                            amount={amount}
                            setAmount={setAmount}
                            selectedInterval={selectedInterval}
                            setSelectedInterval={setSelectedInterval}
                            wallet={wallet}
                            isImmediate={isImmediate}
                            selectedStrategy={selectedStrategy}
                            gridLowerPrice={gridLowerPrice}
                            setGridLowerPrice={setGridLowerPrice}
                            gridUpperPrice={gridUpperPrice}
                            setGridUpperPrice={setGridUpperPrice}
                            gridCount={gridCount}
                            setGridCount={setGridCount}
                            dcaCount={dcaCount}
                            setDcaCount={setDcaCount}
                            dcaDeviation={dcaDeviation}
                            setDcaDeviation={setDcaDeviation}
                            dcaScale={dcaScale}
                            setDcaScale={setDcaScale}
                        />
                    )}
                    {step === 3 && (
                        <Step3_RiskManagement
                            takeProfit={takeProfit}
                            setTakeProfit={setTakeProfit}
                            stopLoss={stopLoss}
                            setStopLoss={setStopLoss}
                            isTrailingEnabled={isTrailingEnabled}
                            setIsTrailingEnabled={setIsTrailingEnabled}
                            trailingDistance={trailingDistance}
                            setTrailingDistance={setTrailingDistance}
                        />
                    )}
                    {step === 4 && (
                        <Step4_Review
                            selectedCoin={selectedCoin}
                            selectedStrategyId={selectedStrategy}
                            strategies={strategies}
                            amount={amount}
                            selectedInterval={selectedInterval}
                            takeProfit={takeProfit}
                            stopLoss={stopLoss}
                            isTrailingEnabled={isTrailingEnabled}
                            trailingDistance={trailingDistance}
                            onStart={handleStart}
                            isStarting={isStarting}
                        />
                    )}
                </div>

                {/* Footer Buttons */}
                {step < 4 && (
                    <div className="px-6 py-6 bg-slate-900/50 border-t border-white/5 flex justify-between items-center shrink-0">
                        {step > 1 ? (
                            <button
                                onClick={handleBack}
                                className="px-6 py-3 rounded-xl font-bold text-slate-400 hover:text-white hover:bg-white/5 transition-colors flex items-center gap-2"
                            >
                                <ChevronLeft size={18} />
                                Geri
                            </button>
                        ) : (
                            <div></div> // Spacer
                        )}

                        <button
                            onClick={handleNext}
                            disabled={step === 1 ? !isStep1Valid : !isStep2Valid}
                            className="bg-slate-100 hover:bg-white text-slate-900 px-8 py-3 rounded-xl font-bold font-display shadow-lg shadow-white/5 active:scale-95 transition-all flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            İleri
                            <ChevronRight size={18} />
                        </button>
                    </div>
                )}
            </motion.div>
        </div>
    );
}
