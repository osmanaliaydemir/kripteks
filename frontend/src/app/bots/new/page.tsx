"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Coin, Strategy, Wallet } from "@/types";
import { BotService, MarketService, WalletService } from "@/lib/api";
import BotWizard from "@/components/wizard/BotWizard";
import { toast } from "sonner";
import { Loader2 } from "lucide-react";

export default function NewBotPage() {
    const router = useRouter();
    const [isLoading, setIsLoading] = useState(true);
    const [coins, setCoins] = useState<Coin[]>([]);
    const [strategies, setStrategies] = useState<Strategy[]>([]);
    const [wallet, setWallet] = useState<Wallet | null>(null);
    const [isCoinsLoading, setIsCoinsLoading] = useState(false);

    useEffect(() => {
        // Auth check
        const token = localStorage.getItem("token");
        if (!token) {
            router.push('/login');
            return;
        }

        fetchInitialData();
    }, [router]);

    const fetchInitialData = async () => {
        try {
            const [strategiesData, walletData, coinsData] = await Promise.all([
                MarketService.getStrategies("Trading"),
                WalletService.get(),
                MarketService.getCoins() // Pre-fetch coins
            ]);
            setStrategies(strategiesData);
            setWallet(walletData);
            setCoins(coinsData);
        } catch (error) {
            console.error("Veri hatası", error);
            toast.error("Veriler yüklenirken bir hata oluştu.");
        } finally {
            setIsLoading(false);
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
            router.push('/'); // Redirect to dashboard
        } catch (error: unknown) {
            const msg = error instanceof Error ? error.message : "Bot başlatılamadı!";
            toast.error("Hata", { description: msg });
            throw error; // Re-throw to handle loading state in child if needed
        }
    };

    const handleCancel = () => {
        router.back();
    };

    if (isLoading) {
        return (
            <div className="min-h-screen bg-slate-950 flex items-center justify-center">
                <Loader2 className="animate-spin text-primary w-10 h-10" />
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-slate-950 pb-20">
            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                <BotWizard
                    coins={coins}
                    strategies={strategies}
                    wallet={wallet}
                    onBotCreate={handleBotCreate}
                    onCancel={handleCancel}
                    isCoinsLoading={isCoinsLoading}
                    refreshCoins={refreshCoins}
                />
            </main>
        </div>
    );
}
