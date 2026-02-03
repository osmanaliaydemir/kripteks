"use client";

import React, { useState } from "react";
import { ShieldCheck, Lock, Eye, EyeOff, Loader2, Save } from "lucide-react";
import { motion } from "framer-motion";

interface SecuritySettingsProps {
    passwords: any;
    setPasswords: (val: any) => void;
    isChangingPassword: boolean;
    onChangePassword: () => void;
}

export function SecuritySettings({ passwords, setPasswords, isChangingPassword, onChangePassword }: SecuritySettingsProps) {
    const [showPass, setShowPass] = useState({ current: false, new: false, confirm: false });

    return (
        <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            className="max-w-md space-y-6"
        >
            <div className="bg-blue-500/5 border border-blue-500/10 rounded-xl p-4 flex gap-3">
                <ShieldCheck className="text-blue-400 shrink-0" size={20} />
                <p className="text-[11px] text-blue-400/80 leading-relaxed font-medium">Hemen aşağıdan şifrenizi güncelleyebilirsiniz. Güçlü bir şifre kullanmanızı (en az 6 karakter, harf ve rakam) öneririz.</p>
            </div>

            <div className="space-y-4">
                <div className="space-y-2">
                    <label className="text-xs font-bold text-slate-400 uppercase">Mevcut Şifre</label>
                    <div className="relative">
                        <input
                            type={showPass.current ? "text" : "password"}
                            value={passwords.current}
                            onChange={(e) => setPasswords({ ...passwords, current: e.target.value })}
                            placeholder="••••••••"
                            className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-10 pr-12 py-3 text-sm text-white focus:border-primary/50 outline-none transition-all"
                        />
                        <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-600" size={16} />
                        <button
                            onClick={() => setShowPass({ ...showPass, current: !showPass.current })}
                            className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 p-1"
                        >
                            {showPass.current ? <EyeOff size={16} /> : <Eye size={16} />}
                        </button>
                    </div>
                </div>
                <div className="space-y-2">
                    <label className="text-xs font-bold text-slate-400 uppercase">Yeni Şifre</label>
                    <div className="relative">
                        <input
                            type={showPass.new ? "text" : "password"}
                            value={passwords.new}
                            onChange={(e) => setPasswords({ ...passwords, new: e.target.value })}
                            placeholder="••••••••"
                            className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-10 pr-12 py-3 text-sm text-white focus:border-primary/50 outline-none transition-all"
                        />
                        <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-600" size={16} />
                        <button
                            onClick={() => setShowPass({ ...showPass, new: !showPass.new })}
                            className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 p-1"
                        >
                            {showPass.new ? <EyeOff size={16} /> : <Eye size={16} />}
                        </button>
                    </div>
                </div>
                <div className="space-y-2">
                    <label className="text-xs font-bold text-slate-400 uppercase">Yeni Şifre (Tekrar)</label>
                    <div className="relative">
                        <input
                            type={showPass.confirm ? "text" : "password"}
                            value={passwords.confirm}
                            onChange={(e) => setPasswords({ ...passwords, confirm: e.target.value })}
                            placeholder="••••••••"
                            className="w-full bg-slate-950/50 border border-white/10 rounded-xl px-10 pr-12 py-3 text-sm text-white focus:border-primary/50 outline-none transition-all"
                        />
                        <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-600" size={16} />
                        <button
                            onClick={() => setShowPass({ ...showPass, confirm: !showPass.confirm })}
                            className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 p-1"
                        >
                            {showPass.confirm ? <EyeOff size={16} /> : <Eye size={16} />}
                        </button>
                    </div>
                </div>

                <button
                    onClick={onChangePassword}
                    disabled={isChangingPassword}
                    className="w-full py-3 bg-primary hover:bg-primary-light border border-primary/20 rounded-xl text-xs font-bold text-black flex items-center justify-center gap-2 transition-all disabled:opacity-50"
                >
                    {isChangingPassword ? <Loader2 className="animate-spin w-4 h-4" /> : <Save size={16} />}
                    Şifreyi Güncelle
                </button>
            </div>
        </motion.div>
    );
}
