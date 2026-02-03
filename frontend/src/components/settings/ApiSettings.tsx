"use client";

import React, { useState } from "react";
import { CheckCircle, AlertTriangle, Eye, EyeOff, Loader2, Save } from "lucide-react";
import { motion } from "framer-motion";

interface ApiSettingsProps {
    existingKey: string | null;
    apiKey: string;
    setApiKey: (val: string) => void;
    secretKey: string;
    setSecretKey: (val: string) => void;
    isSaving: boolean;
    onSave: () => void;
}

export function ApiSettings({ existingKey, apiKey, setApiKey, secretKey, setSecretKey, isSaving, onSave }: ApiSettingsProps) {
    const [showApiKey, setShowApiKey] = useState(false);
    const [showSecretKey, setShowSecretKey] = useState(false);

    return (
        <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="space-y-6 max-w-2xl"
        >
            {existingKey && (
                <div className="bg-emerald-500/10 border border-emerald-500/20 rounded-xl p-4 flex gap-3 items-center">
                    <CheckCircle className="text-emerald-500 shrink-0" size={20} />
                    <div>
                        <p className="text-sm font-bold text-emerald-500">API Bağlantısı Aktif</p>
                        <p className="text-xs text-emerald-500/80 font-mono">Anahtar: {existingKey}</p>
                    </div>
                </div>
            )}

            <div className="bg-amber-500/10 border border-amber-500/20 rounded-xl p-4 flex gap-3">
                <AlertTriangle className="text-amber-500 shrink-0" size={20} />
                <div>
                    <p className="text-sm font-bold text-amber-500 mb-1">Güvenlik Uyarısı</p>
                    <p className="text-xs text-amber-500/80 leading-relaxed">
                        API anahtarlarınız sunucularımızda şifrelenmiş olarak saklanır.
                        Güvenliğiniz için "Para Çekme (Withdrawal)" iznini <u>asla</u> aktifleştirmeyin.
                    </p>
                </div>
            </div>

            <div className="space-y-4">
                <div className="space-y-2">
                    <label className="text-sm font-medium text-slate-300">Binance API Anahtarı</label>
                    <div className="relative">
                        <input
                            type={showApiKey ? "text" : "password"}
                            value={apiKey}
                            onChange={(e) => setApiKey(e.target.value)}
                            placeholder="API Anahtarınızı giriniz"
                            className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-primary/50 focus:ring-1 focus:ring-primary/50 font-mono transition-all"
                        />
                        <button onClick={() => setShowApiKey(!showApiKey)} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 p-1">
                            {showApiKey ? <EyeOff size={16} /> : <Eye size={16} />}
                        </button>
                    </div>
                </div>

                <div className="space-y-2">
                    <label className="text-sm font-medium text-slate-300">Binance Gizli Anahtar (Secret Key)</label>
                    <div className="relative">
                        <input
                            type={showSecretKey ? "text" : "password"}
                            value={secretKey}
                            onChange={(e) => setSecretKey(e.target.value)}
                            placeholder="Gizli Anahtarınızı giriniz"
                            className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-primary/50 focus:ring-1 focus:ring-primary/50 font-mono transition-all"
                        />
                        <button onClick={() => setShowSecretKey(!showSecretKey)} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 p-1">
                            {showSecretKey ? <EyeOff size={16} /> : <Eye size={16} />}
                        </button>
                    </div>
                </div>
            </div>

            <div className="pt-4">
                <button
                    onClick={onSave}
                    disabled={isSaving}
                    className="w-full md:w-auto px-8 py-3 rounded-xl text-sm font-bold text-black bg-primary hover:bg-primary-light shadow-lg shadow-primary/20 flex items-center justify-center gap-2 transition-all disabled:opacity-50"
                >
                    {isSaving ? <Loader2 className="animate-spin w-4 h-4" /> : <Save size={18} />}
                    API Ayarlarını Kaydet
                </button>
            </div>
        </motion.div>
    );
}
