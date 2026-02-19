"use client";

import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Loader2 } from "lucide-react";
import { BotService, WalletService, MarketService } from "@/lib/api";
import { toast } from "sonner";
import BotWizard from "@/components/wizard/BotWizard";
import { Coin, Strategy, Wallet } from "@/types";

interface QuickBuyModalProps {
    isOpen: boolean;
    onClose: () => void;
    symbol: string;
    currentPrice: number;
    signalScore: number;
    initialStrategy?: string;
}

export function QuickBuyModal({ isOpen, onClose, symbol, initialStrategy }: QuickBuyModalProps) {
    const [loading, setLoading] = useState(false);
    const [coins, setCoins] = useState<Coin[]>([]);
    const [strategies, setStrategies] = useState<Strategy[]>([]);
    const [wallet, setWallet] = useState<Wallet | null>(null);
    const [isCoinsLoading, setIsCoinsLoading] = useState(false);

    useEffect(() => {
        if (isOpen) {
            fetchInitialData();
        }
    }, [isOpen]);

    const fetchInitialData = async () => {
        setLoading(true);
        try {
            const [strategiesData, walletData, coinsData] = await Promise.all([
                MarketService.getStrategies("Trading"),
                WalletService.get(),
                MarketService.getCoins()
            ]);
            setStrategies(strategiesData);
            setWallet(walletData);
            setCoins(coinsData);
        } catch (error) {
            console.error("Veri çekilemedi", error);
            toast.error("Hızlı Alım verileri yüklenirken bir sorun oluştu.");
        } finally {
            setLoading(false);
        }
    };

    const refreshCoins = async () => {
        setIsCoinsLoading(true);
        try {
            const coinsData = await MarketService.getCoins();
            setCoins(coinsData);
        } catch (e) {
            console.error(e);
        } finally {
            setIsCoinsLoading(false);
        }
    };

    const handleBotCreate = async (payload: any) => {
        try {
            const res = await BotService.create(payload);
            if (res?._unauthorized) return;
            toast.success("Bot Başlatıldı", { description: `${payload.symbol} üzerinde işlem başladı.` });
            onClose(); // İşlem bitince modalı kapat
        } catch (error: unknown) {
            const msg = error instanceof Error ? error.message : "Bot başlatılamadı!";
            toast.error("Hata", { description: msg });
            throw error;
        }
    };

    return (
        <AnimatePresence>
            {isOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
                    {/* Backdrop */}
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        onClick={onClose}
                        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
                    />

                    {/* Modal Content */}
                    <div className="relative z-10 w-full max-w-4xl max-h-[95vh] overflow-y-auto custom-scrollbar rounded-3xl">
                        {loading ? (
                            <div className="flex items-center justify-center h-[600px] w-full bg-slate-900/95 border border-white/10 rounded-3xl mx-auto max-w-4xl">
                                <Loader2 className="w-10 h-10 animate-spin text-primary" />
                            </div>
                        ) : (
                            <BotWizard
                                coins={coins}
                                strategies={strategies}
                                wallet={wallet}
                                onBotCreate={handleBotCreate}
                                onCancel={onClose}
                                isCoinsLoading={isCoinsLoading}
                                refreshCoins={refreshCoins}
                                initialSymbol={symbol}
                                initialStrategyId={initialStrategy}
                                isLockedCoin={true}
                            />
                        )}
                    </div>
                </div>
            )}
        </AnimatePresence>
    );
}
