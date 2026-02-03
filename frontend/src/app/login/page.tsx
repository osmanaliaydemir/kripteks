"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Activity, Mail, Lock, ChevronRight, Loader2, Eye, EyeOff } from "lucide-react";
import { toast } from "sonner";
import { API_URL } from "@/lib/api";

export default function LoginPage() {
    const router = useRouter();
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [showPassword, setShowPassword] = useState(false);
    const [isLoading, setIsLoading] = useState(false);

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!email || !password) {
            toast.error("Hata", { description: "Lütfen tüm alanları doldurun." });
            return;
        }

        setIsLoading(true);

        try {
            const res = await fetch(`${API_URL}/auth/login`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ email, password })
            });

            if (!res.ok) {
                const error = await res.text();
                throw new Error(error || "Giriş başarısız");
            }

            const data = await res.json();

            // Token'ı kaydet
            localStorage.setItem("token", data.token);
            localStorage.setItem("user", JSON.stringify(data.user)); // Opsiyonel: Kullanıcı bilgisi

            toast.success("Giriş Başarılı", { description: "Panele yönlendiriliyorsunuz..." });

            setTimeout(() => {
                router.push("/");
            }, 1000);

        } catch (error: any) {
            toast.error("Giriş Yapılamadı", { description: "Kullanıcı adı veya şifre hatalı." });
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4 relative overflow-hidden">
            {/* Background Effects */}
            <div className="absolute top-[-20%] left-[-10%] w-[50%] h-[50%] bg-primary/10 rounded-full blur-[120px] pointer-events-none"></div>
            <div className="absolute bottom-[-20%] right-[-10%] w-[50%] h-[50%] bg-secondary/10 rounded-full blur-[120px] pointer-events-none"></div>

            <div className="w-full max-w-md bg-slate-900/50 backdrop-blur-xl border border-slate-800 rounded-3xl p-8 shadow-2xl relative z-10">
                <div className="text-center mb-10">
                    <div className="flex items-center justify-center gap-4 mb-6 group">
                        <div className="relative">
                            <div className="absolute inset-0 bg-primary/40 rounded-xl blur-lg group-hover:blur-xl transition-all"></div>
                            <div className="bg-slate-900 border border-white/10 p-3 rounded-2xl shadow-lg relative">
                                <Activity className="text-secondary w-8 h-8" />
                            </div>
                        </div>
                        <div className="text-left">
                            <h1 className="text-3xl font-display font-bold text-white tracking-widest leading-none">
                                KRIP<span className="text-primary">TEKS</span>
                            </h1>
                            <p className="text-[10px] text-slate-400 font-mono tracking-[0.2em] uppercase opacity-80 mt-1">Otonom Motor v2.1</p>
                        </div>
                    </div>
                    <h2 className="text-xl font-bold text-white mb-2">Hoşgeldiniz</h2>
                    <p className="text-slate-400 text-sm">Bot yönetim paneline erişmek için giriş yapın.</p>
                </div>

                <form onSubmit={handleLogin} className="space-y-4">
                    <div className="space-y-2">
                        <label className="text-xs font-bold text-slate-500 uppercase tracking-wider ml-1">E-Posta</label>
                        <div className="relative">
                            <Mail className="absolute left-4 top-3.5 w-5 h-5 text-slate-500" />
                            <input
                                type="email"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                className="w-full bg-slate-950/50 border border-slate-700 rounded-xl pl-11 pr-4 py-3 text-white placeholder-slate-600 focus:border-primary/50 focus:ring-1 focus:ring-primary/20 transition-all outline-none"
                                placeholder="ornek@mail.com"
                            />
                        </div>
                    </div>

                    <div className="space-y-2">
                        <label className="text-xs font-bold text-slate-500 uppercase tracking-wider ml-1">Şifre</label>
                        <div className="relative">
                            <Lock className="absolute left-4 top-3.5 w-5 h-5 text-slate-500" />
                            <input
                                type={showPassword ? "text" : "password"}
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                className="w-full bg-slate-950/50 border border-slate-700 rounded-xl pl-11 pr-4 py-3 text-white placeholder-slate-600 focus:border-primary/50 focus:ring-1 focus:ring-primary/20 transition-all outline-none"
                                placeholder="••••••••"
                            />
                            <button
                                type="button"
                                onClick={() => setShowPassword(!showPassword)}
                                className="absolute right-4 top-3.5 text-slate-500 hover:text-slate-300 transition-colors"
                            >
                                {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                            </button>
                        </div>
                    </div>

                    <button
                        type="submit"
                        disabled={isLoading}
                        className="w-full bg-linear-to-r from-primary to-amber-600 hover:from-primary-light hover:to-primary text-slate-900 font-bold py-3.5 rounded-xl shadow-lg shadow-primary/20 active:scale-[0.98] transition-all flex items-center justify-center gap-2 mt-6 disabled:opacity-70 disabled:cursor-not-allowed"
                    >
                        {isLoading ? (
                            <Loader2 className="animate-spin" />
                        ) : (
                            <>
                                Giriş Yap
                                <ChevronRight className="w-5 h-5" />
                            </>
                        )}
                    </button>

                    <div className="text-center mt-4">
                        <p className="text-xs text-slate-500">
                            Kayıt olmak için sistem yöneticisine başvurun.
                        </p>
                    </div>
                </form>
            </div>
        </div>
    );
}
