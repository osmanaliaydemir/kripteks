"use client";

import React from "react";
import { Bell, ShieldAlert, Loader2, Save } from "lucide-react";
import { motion } from "framer-motion";

interface GeneralSettingsProps {
    settings: {
        telegramBotToken: string;
        telegramChatId: string;
        enableTelegramNotifications: boolean;
        globalStopLossPercent: number;
        maxActiveBots: number;
        defaultTimeframe: string;
        defaultAmount: number;
    };
    setSettings: (settings: any) => void;
    isSaving: boolean;
    onSave: () => void;
}

export function GeneralSettings({ settings, setSettings, isSaving, onSave }: GeneralSettingsProps) {
    return (
        <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            className="space-y-8 max-w-2xl"
        >
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Telegram Settings */}
                <div className="space-y-4">
                    <div className="flex items-center gap-2 text-primary">
                        <Bell size={18} />
                        <h4 className="text-sm font-bold uppercase tracking-wider">Telegram Bildirimleri</h4>
                    </div>
                    <div className="space-y-4 bg-white/5 p-4 rounded-xl border border-white/5">
                        <div className="flex items-center justify-between">
                            <label className="text-xs font-bold text-slate-300">Bildirimleri Aktifleştir</label>
                            <button
                                onClick={() => setSettings({ ...settings, enableTelegramNotifications: !settings.enableTelegramNotifications })}
                                className={`w-10 h-5 rounded-full transition-all relative ${settings.enableTelegramNotifications ? 'bg-primary' : 'bg-slate-700'}`}
                            >
                                <div className={`absolute top-1 w-3 h-3 rounded-full bg-white transition-all ${settings.enableTelegramNotifications ? 'right-1' : 'left-1'}`} />
                            </button>
                        </div>
                        <div className="space-y-2">
                            <label className="text-[10px] font-bold text-slate-500 uppercase">Bot Token</label>
                            <input
                                type="text"
                                value={settings.telegramBotToken || ""}
                                onChange={(e) => setSettings({ ...settings, telegramBotToken: e.target.value })}
                                className="w-full bg-slate-950/50 border border-white/10 rounded-lg px-3 py-2 text-xs text-white outline-none focus:border-primary/50"
                                placeholder="54321:AAEf..."
                            />
                        </div>
                        <div className="space-y-2">
                            <label className="text-[10px] font-bold text-slate-500 uppercase">Chat ID</label>
                            <input
                                type="text"
                                value={settings.telegramChatId || ""}
                                onChange={(e) => setSettings({ ...settings, telegramChatId: e.target.value })}
                                className="w-full bg-slate-950/50 border border-white/10 rounded-lg px-3 py-2 text-xs text-white outline-none focus:border-primary/50"
                                placeholder="12345678"
                            />
                        </div>
                    </div>
                </div>

                {/* Risk Settings */}
                <div className="space-y-4">
                    <div className="flex items-center gap-2 text-amber-500">
                        <ShieldAlert size={18} />
                        <h4 className="text-sm font-bold uppercase tracking-wider">Risk Yönetimi</h4>
                    </div>
                    <div className="space-y-4 bg-white/5 p-4 rounded-xl border border-white/5">
                        <div className="space-y-2">
                            <label className="text-[10px] font-bold text-slate-500 uppercase">Global Stop Loss (%)</label>
                            <input
                                type="number"
                                value={settings.globalStopLossPercent ?? ""}
                                onChange={(e) => setSettings({ ...settings, globalStopLossPercent: Number(e.target.value) })}
                                className="w-full bg-slate-950/50 border border-white/10 rounded-lg px-3 py-2 text-xs text-white outline-none focus:border-primary/50"
                            />
                        </div>
                        <div className="space-y-2">
                            <label className="text-[10px] font-bold text-slate-500 uppercase">Max Aktif Bot</label>
                            <input
                                type="number"
                                value={settings.maxActiveBots ?? ""}
                                onChange={(e) => setSettings({ ...settings, maxActiveBots: Number(e.target.value) })}
                                className="w-full bg-slate-950/50 border border-white/10 rounded-lg px-3 py-2 text-xs text-white outline-none focus:border-primary/50"
                            />
                        </div>
                    </div>
                </div>
            </div>

            <button
                onClick={onSave}
                disabled={isSaving}
                className="px-8 py-3 rounded-xl text-sm font-bold text-black bg-primary hover:bg-primary-light flex items-center gap-2 transition-all disabled:opacity-50"
            >
                {isSaving ? <Loader2 className="animate-spin w-4 h-4" /> : <Save size={18} />}
                Genel Ayarları Kaydet
            </button>
        </motion.div>
    );
}
