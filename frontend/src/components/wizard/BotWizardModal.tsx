import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X, ChevronRight, ChevronLeft } from "lucide-react";
import { Coin, Strategy, Wallet } from "@/types";
import Step1_Strategy from "./steps/Step1_Strategy";
import Step2_Configuration from "./steps/Step2_Configuration";
import Step3_RiskManagement from "./steps/Step3_RiskManagement";
import Step4_Review from "./steps/Step4_Review";

interface BotWizardModalProps {
    isOpen: boolean;
    onClose: () => void;
    coins: Coin[];
    strategies: Strategy[];
    wallet: Wallet | null;
    onBotCreate: (payload: any) => Promise<void>;
    isCoinsLoading: boolean;
    refreshCoins: () => void;
}

export default function BotWizardModal({
    isOpen,
    onClose,
    coins,
    strategies,
    wallet,
    onBotCreate,
    isCoinsLoading,
    refreshCoins
}: BotWizardModalProps) {
    const [step, setStep] = useState(1);

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

    // Reset on open
    useEffect(() => {
        if (isOpen) {
            setStep(1);
            // Optional: reset form or keep last state
            if (strategies.length > 0 && !selectedStrategy) {
                setSelectedStrategy(strategies[0].id);
            }
        }
    }, [isOpen, strategies]);

    // Strategy defaults
    useEffect(() => {
        if (selectedStrategy === "strategy-market-buy") setSelectedInterval("1m");
        else if (selectedStrategy === "strategy-golden-rose") setSelectedInterval("1h");
        else if (selectedStrategy === "strategy-sma-crossover") setSelectedInterval("15m");
    }, [selectedStrategy]);

    if (!isOpen) return null;

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
            trailingStopDistance: isTrailingEnabled ? Number(trailingDistance) : null
        };

        await onBotCreate(payload);
        setIsStarting(false);
        onClose();
    };

    // Validation
    const isStep1Valid = !!selectedCoin && !!selectedStrategy;
    const isImmediate = selectedStrategy === "strategy-market-buy";
    const isInsufficientBalance = wallet && amount > wallet.available_balance;
    const isStep2Valid = amount > 0 && (!isImmediate || !isInsufficientBalance);

    return (
        <div className="fixed inset-0 z-60 flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-black/80 backdrop-blur-sm" onClick={onClose}></div>

            <motion.div
                initial={{ opacity: 0, scale: 0.95, y: 20 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.95, y: 20 }}
                className="relative bg-slate-950 border border-white/10 rounded-3xl w-full md:max-w-2xl overflow-hidden shadow-2xl flex flex-col max-h-[90vh]"
            >
                {/* Header / Progress */}
                <div className="px-4 py-4 md:px-8 md:py-6 border-b border-white/5 bg-slate-900/50 flex items-center justify-between shrink-0">
                    <div>
                        <h2 className="text-lg md:text-xl font-display font-bold text-white tracking-widest">Yeni Bot Oluştur</h2>
                        <div className="flex items-center gap-2 mt-2">
                            {[1, 2, 3, 4].map((s) => (
                                <div key={s} className={`h-1.5 rounded-full transition-all duration-500 ${s <= step ? 'w-8 bg-primary' : 'w-2 bg-slate-800'}`}></div>
                            ))}
                        </div>
                    </div>
                    <button onClick={onClose} className="p-2 -mr-2 text-slate-500 hover:text-white hover:bg-white/5 rounded-xl transition-colors">
                        <X size={24} />
                    </button>
                </div>

                {/* Body */}
                <div className="p-4 md:p-8 overflow-y-auto min-h-[400px]">
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
                    <div className="px-4 py-4 md:px-8 md:py-6 bg-slate-900/50 border-t border-white/5 flex justify-between items-center shrink-0">
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
