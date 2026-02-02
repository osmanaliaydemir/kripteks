"use client";

import React, { useState, useEffect, Suspense } from "react";
import { SettingsService, UserService, AuthService } from "@/lib/api";
import { toast } from "sonner";
import { motion, AnimatePresence } from "framer-motion";
import {
    AlertTriangle,
    CheckCircle,
    Eye,
    EyeOff,
    Key,
    Save,
    Settings as SettingsIcon,
    Trash,
    User,
    UserPlus,
    BadgeCheck,
    Bell,
    ShieldCheck,
    Lock,
    Loader2,
    Settings2,
    ShieldAlert
} from "lucide-react";
import Navbar from "@/components/ui/Navbar";
import { User as UserType } from "@/types";
import { useSearchParams } from "next/navigation";

function SettingsContent() {
    const searchParams = useSearchParams();
    const [currentTab, setCurrentTab] = useState<'api' | 'general' | 'users' | 'security'>('api');
    const [user, setUser] = useState<UserType | null>(null);

    // API Keys States
    const [showApiKey, setShowApiKey] = useState(false);
    const [showSecretKey, setShowSecretKey] = useState(false);
    const [existingKey, setExistingKey] = useState<string | null>(null);
    const [apiKey, setApiKey] = useState("");
    const [secretKey, setSecretKey] = useState("");
    const [isSaving, setIsSaving] = useState(false);

    // General Settings States
    const [generalSettings, setGeneralSettings] = useState({
        telegramBotToken: "",
        telegramChatId: "",
        enableTelegramNotifications: false,
        globalStopLossPercent: 5,
        maxActiveBots: 10,
        defaultTimeframe: "1h",
        defaultAmount: 100
    });

    // Password States
    const [passwords, setPasswords] = useState({ current: "", new: "", confirm: "" });
    const [isChangingPassword, setIsChangingPassword] = useState(false);

    // User Management States
    const [users, setUsers] = useState<any[]>([]);
    const [isAddingUser, setIsAddingUser] = useState(false);
    const [newUser, setNewUser] = useState({ firstName: "", lastName: "", email: "", password: "", role: "User" });
    const [showPass, setShowPass] = useState({ current: false, new: false, confirm: false, newUser: false });

    useEffect(() => {
        const tab = searchParams.get('tab');
        if (tab && ['api', 'general', 'users', 'security'].includes(tab)) {
            setCurrentTab(tab as any);
        }
    }, [searchParams]);

    useEffect(() => {
        const token = localStorage.getItem("token");
        if (!token) {
            window.location.href = '/login';
            return;
        }

        try {
            const userData = localStorage.getItem("user");
            if (userData) setUser(JSON.parse(userData));
        } catch (e) {
            console.error(e);
        }

        loadKeys();
        loadUsers();
        loadGeneralSettings();
    }, []);

    const loadKeys = async () => {
        try {
            const data = await SettingsService.getKeys();
            if (data && data.hasKeys) {
                setExistingKey(data.apiKey);
            }
        } catch (e) {
            console.error(e);
        }
    };

    const loadUsers = async () => {
        try {
            const data = await UserService.getAll();
            setUsers(data);
        } catch (e) {
            console.error(e);
        }
    };

    const loadGeneralSettings = async () => {
        try {
            const data = await SettingsService.getGeneral();
            if (data) setGeneralSettings(data);
        } catch (e) {
            console.error(e);
        }
    };

    const handleSaveApiKeys = async () => {
        if (!apiKey || !secretKey) {
            toast.error("Eksik Bilgi", { description: "Lütfen API Key ve Secret Key giriniz." });
            return;
        }

        setIsSaving(true);
        try {
            await SettingsService.saveKeys(apiKey, secretKey);
            toast.success("Başarılı", { description: "API anahtarları güvenli bir şekilde kaydedildi." });
            setApiKey("");
            setSecretKey("");
            loadKeys();
        } catch (error) {
            toast.error("Hata", { description: "Kaydedilirken bir sorun oluştu." });
        } finally {
            setIsSaving(false);
        }
    };

    const handleSaveGeneralSettings = async () => {
        setIsSaving(true);
        try {
            await SettingsService.saveGeneral(generalSettings);
            toast.success("Başarılı", { description: "Sistem ayarları güncellendi." });
        } catch (error) {
            toast.error("Hata", { description: "Ayarlar kaydedilemedi." });
        } finally {
            setIsSaving(false);
        }
    };

    const handleChangePassword = async () => {
        if (passwords.new !== passwords.confirm) {
            toast.error("Hata", { description: "Yeni şifreler uyuşmuyor!" });
            return;
        }
        if (passwords.new.length < 6) {
            toast.error("Hata", { description: "Şifre en az 6 karakter olmalıdır." });
            return;
        }

        setIsChangingPassword(true);
        try {
            await AuthService.changePassword(passwords.current, passwords.new);
            toast.success("Başarılı", { description: "Şifreniz değiştirildi." });
            setPasswords({ current: "", new: "", confirm: "" });
        } catch (error: any) {
            toast.error("Hata", { description: error.message || "İşlem başarısız." });
        } finally {
            setIsChangingPassword(false);
        }
    };

    const handleAddUser = async () => {
        const { firstName, lastName, email, password } = newUser;
        if (!firstName || !lastName || !email || !password) {
            toast.error("Eksik Bilgi", { description: "Lütfen tüm alanları doldurunuz." });
            return;
        }

        try {
            await UserService.create(newUser);
            toast.success("Başarılı", { description: "Yeni kullanıcı eklendi." });
            setNewUser({ firstName: "", lastName: "", email: "", password: "", role: "User" });
            setIsAddingUser(false);
            loadUsers();
        } catch (error: any) {
            toast.error("Hata", { description: error.message || "Kullanıcı eklenemedi." });
        }
    };

    const handleDeleteUser = async (id: string, role: string) => {
        if (role === 'Admin') {
            toast.error("İşlem Engellendi", { description: "Yönetici yetkisine sahip kullanıcılar silinemez!" });
            return;
        }

        if (!confirm("Bu kullanıcıyı silmek istediğinize emin misiniz?")) return;

        try {
            await UserService.delete(id);
            toast.success("Başarı", { description: "Kullanıcı silindi." });
            loadUsers();
        } catch (error: any) {
            toast.error("Hata", { description: error.message || "Silme başarısız." });
        }
    };

    return (
        <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-20 min-h-screen bg-slate-950">
            <Navbar user={user} />

            <div className="flex items-center gap-3 mt-4 mb-8">
                <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center border border-primary/20">
                    <SettingsIcon className="text-primary" size={20} />
                </div>
                <div>
                    <h2 className="text-xl font-display font-bold text-white tracking-tight">Sistem Ayarları</h2>
                    <p className="text-xs text-slate-400">Platform yapılandırmasını ve kullanıcıları yönetin</p>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
                {/* Sidebar Navigation */}
                <div className="lg:col-span-1 space-y-2">
                    <TabButton
                        active={currentTab === 'api'}
                        icon={<Key size={18} />}
                        label="API Bağlantıları"
                        onClick={() => setCurrentTab('api')}
                    />
                    <TabButton
                        active={currentTab === 'general'}
                        icon={<Bell size={18} />}
                        label="Genel & Bildirim"
                        onClick={() => setCurrentTab('general')}
                    />
                    <TabButton
                        active={currentTab === 'users'}
                        icon={<User size={18} />}
                        label="Kullanıcı Yönetimi"
                        onClick={() => setCurrentTab('users')}
                    />
                    <TabButton
                        active={currentTab === 'security'}
                        icon={<ShieldCheck size={18} />}
                        label="Güvenlik & Şifre"
                        onClick={() => setCurrentTab('security')}
                    />
                </div>

                {/* Main Content Area */}
                <div className="lg:col-span-3">
                    <div className="glass-card min-h-[500px] flex flex-col bg-slate-900/50 border border-white/5 shadow-2xl overflow-hidden">
                        <div className="p-6 border-b border-white/5 bg-white/5">
                            <h3 className="text-lg font-bold text-white font-display">
                                {currentTab === 'api' && 'Borsa API Bağlantıları'}
                                {currentTab === 'general' && 'Sistem & Bildirim Ayarları'}
                                {currentTab === 'users' && 'Kullanıcı Yönetimi'}
                                {currentTab === 'security' && 'Şifre ve Güvenlik İşlemleri'}
                            </h3>
                        </div>

                        <div className="p-8">
                            <AnimatePresence mode="wait">
                                {currentTab === 'api' && (
                                    <motion.div
                                        key="api"
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
                                                onClick={handleSaveApiKeys}
                                                disabled={isSaving}
                                                className="w-full md:w-auto px-8 py-3 rounded-xl text-sm font-bold text-black bg-primary hover:bg-primary-light shadow-lg shadow-primary/20 flex items-center justify-center gap-2 transition-all disabled:opacity-50"
                                            >
                                                {isSaving ? <Loader2 className="animate-spin w-4 h-4" /> : <Save size={18} />}
                                                API Ayarlarını Kaydet
                                            </button>
                                        </div>
                                    </motion.div>
                                )}

                                {currentTab === 'general' && (
                                    <motion.div
                                        key="general"
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
                                                            onClick={() => setGeneralSettings({ ...generalSettings, enableTelegramNotifications: !generalSettings.enableTelegramNotifications })}
                                                            className={`w-10 h-5 rounded-full transition-all relative ${generalSettings.enableTelegramNotifications ? 'bg-primary' : 'bg-slate-700'}`}
                                                        >
                                                            <div className={`absolute top-1 w-3 h-3 rounded-full bg-white transition-all ${generalSettings.enableTelegramNotifications ? 'right-1' : 'left-1'}`} />
                                                        </button>
                                                    </div>
                                                    <div className="space-y-2">
                                                        <label className="text-[10px] font-bold text-slate-500 uppercase">Bot Token</label>
                                                        <input
                                                            type="text"
                                                            value={generalSettings.telegramBotToken || ""}
                                                            onChange={(e) => setGeneralSettings({ ...generalSettings, telegramBotToken: e.target.value })}
                                                            className="w-full bg-slate-950/50 border border-white/10 rounded-lg px-3 py-2 text-xs text-white outline-none focus:border-primary/50"
                                                            placeholder="54321:AAEf..."
                                                        />
                                                    </div>
                                                    <div className="space-y-2">
                                                        <label className="text-[10px] font-bold text-slate-500 uppercase">Chat ID</label>
                                                        <input
                                                            type="text"
                                                            value={generalSettings.telegramChatId || ""}
                                                            onChange={(e) => setGeneralSettings({ ...generalSettings, telegramChatId: e.target.value })}
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
                                                            value={generalSettings.globalStopLossPercent ?? ""}
                                                            onChange={(e) => setGeneralSettings({ ...generalSettings, globalStopLossPercent: Number(e.target.value) })}
                                                            className="w-full bg-slate-950/50 border border-white/10 rounded-lg px-3 py-2 text-xs text-white outline-none focus:border-primary/50"
                                                        />
                                                    </div>
                                                    <div className="space-y-2">
                                                        <label className="text-[10px] font-bold text-slate-500 uppercase">Max Aktif Bot</label>
                                                        <input
                                                            type="number"
                                                            value={generalSettings.maxActiveBots ?? ""}
                                                            onChange={(e) => setGeneralSettings({ ...generalSettings, maxActiveBots: Number(e.target.value) })}
                                                            className="w-full bg-slate-950/50 border border-white/10 rounded-lg px-3 py-2 text-xs text-white outline-none focus:border-primary/50"
                                                        />
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <button
                                            onClick={handleSaveGeneralSettings}
                                            disabled={isSaving}
                                            className="px-8 py-3 rounded-xl text-sm font-bold text-black bg-primary hover:bg-primary-light flex items-center gap-2 transition-all disabled:opacity-50"
                                        >
                                            {isSaving ? <Loader2 className="animate-spin w-4 h-4" /> : <Save size={18} />}
                                            Genel Ayarları Kaydet
                                        </button>
                                    </motion.div>
                                )}

                                {currentTab === 'users' && (
                                    <motion.div
                                        key="users"
                                        initial={{ opacity: 0, x: 20 }}
                                        animate={{ opacity: 1, x: 0 }}
                                        className="space-y-6"
                                    >
                                        <div className="flex items-center justify-between bg-white/5 p-4 rounded-xl border border-white/5">
                                            <div>
                                                <h4 className="text-sm font-bold text-white">Aktif Kullanıcılar</h4>
                                                <p className="text-[10px] text-slate-500 uppercase tracking-widest">Sistem yetkili listesi</p>
                                            </div>
                                            <button
                                                onClick={() => setIsAddingUser(!isAddingUser)}
                                                className="px-4 py-2 bg-primary hover:bg-primary-light text-black rounded-lg text-xs font-bold flex items-center gap-2 transition-all"
                                            >
                                                <UserPlus size={16} />
                                                Yeni Kullanıcı
                                            </button>
                                        </div>

                                        {isAddingUser && (
                                            <div className="bg-slate-950/50 border border-white/10 rounded-xl p-6 space-y-4">
                                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                                    <div className="space-y-2">
                                                        <label className="text-xs font-bold text-slate-400 uppercase">Ad</label>
                                                        <input type="text" value={newUser.firstName} onChange={(e) => setNewUser({ ...newUser, firstName: e.target.value })} className="w-full bg-slate-900 border border-white/5 rounded-lg px-4 py-2.5 text-sm text-white focus:border-primary/50 outline-none" />
                                                    </div>
                                                    <div className="space-y-2">
                                                        <label className="text-xs font-bold text-slate-400 uppercase">Soyad</label>
                                                        <input type="text" value={newUser.lastName} onChange={(e) => setNewUser({ ...newUser, lastName: e.target.value })} className="w-full bg-slate-900 border border-white/5 rounded-lg px-4 py-2.5 text-sm text-white focus:border-primary/50 outline-none" />
                                                    </div>
                                                    <div className="col-span-full space-y-2">
                                                        <label className="text-xs font-bold text-slate-400 uppercase">E-Posta</label>
                                                        <input type="email" value={newUser.email} onChange={(e) => setNewUser({ ...newUser, email: e.target.value })} className="w-full bg-slate-900 border border-white/5 rounded-lg px-4 py-2.5 text-sm text-white focus:border-primary/50 outline-none" />
                                                    </div>
                                                    <div className="col-span-full space-y-2">
                                                        <label className="text-xs font-bold text-slate-400 uppercase">Geçici Şifre</label>
                                                        <div className="relative">
                                                            <input
                                                                type={showPass.newUser ? "text" : "password"}
                                                                value={newUser.password}
                                                                onChange={(e) => setNewUser({ ...newUser, password: e.target.value })}
                                                                className="w-full bg-slate-900 border border-white/5 rounded-lg px-4 py-2.5 pr-10 text-sm text-white focus:border-primary/50 outline-none"
                                                            />
                                                            <button
                                                                onClick={() => setShowPass({ ...showPass, newUser: !showPass.newUser })}
                                                                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 p-1"
                                                            >
                                                                {showPass.newUser ? <EyeOff size={16} /> : <Eye size={16} />}
                                                            </button>
                                                        </div>
                                                    </div>
                                                    <div className="col-span-full space-y-2">
                                                        <label className="text-xs font-bold text-slate-400 uppercase">Yetki / Rol</label>
                                                        <div className="flex gap-4">
                                                            <button
                                                                onClick={() => setNewUser({ ...newUser, role: 'User' })}
                                                                className={`flex-1 py-2.5 rounded-lg text-xs font-bold border transition-all ${newUser.role === 'User' ? 'bg-primary/20 border-primary text-primary' : 'bg-slate-900 border-white/5 text-slate-400'}`}
                                                            >
                                                                Standart Kullanıcı (User)
                                                            </button>
                                                            <button
                                                                onClick={() => setNewUser({ ...newUser, role: 'Admin' })}
                                                                className={`flex-1 py-2.5 rounded-lg text-xs font-bold border transition-all ${newUser.role === 'Admin' ? 'bg-amber-500/20 border-amber-500 text-amber-500' : 'bg-slate-900 border-white/5 text-slate-400'}`}
                                                            >
                                                                Yönetici (Admin)
                                                            </button>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div className="flex justify-end gap-3 pt-4 border-t border-white/5">
                                                    <button onClick={() => setIsAddingUser(false)} className="text-xs font-bold text-slate-400 px-4 py-2 hover:text-white transition-colors">İptal</button>
                                                    <button onClick={handleAddUser} className="text-xs font-bold bg-primary text-black px-6 py-2 rounded-lg hover:bg-primary-light transition-all">Kullanıcıyı Kaydet</button>
                                                </div>
                                            </div>
                                        )}

                                        <div className="grid gap-3">
                                            {users.map((u, i) => (
                                                <div key={i} className="bg-slate-900/40 border border-white/5 p-4 rounded-xl flex items-center justify-between group hover:border-white/10 transition-all">
                                                    <div className="flex items-center gap-4">
                                                        <div className="w-10 h-10 rounded-xl bg-linear-to-br from-slate-800 to-slate-900 flex items-center justify-center text-primary font-bold">
                                                            {u.firstName?.[0]}
                                                        </div>
                                                        <div>
                                                            <p className="text-sm font-bold text-white leading-none mb-1">{u.firstName} {u.lastName}</p>
                                                            <div className="flex items-center gap-2">
                                                                <p className="text-[10px] text-slate-500 font-mono">{u.email}</p>
                                                                <span className="w-1 h-1 rounded-full bg-slate-700"></span>
                                                                <span className="text-[9px] font-bold text-primary/80 uppercase tracking-tighter">{u.role || u.Role}</span>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <button onClick={() => handleDeleteUser(u.id, u.role)} className="p-2 text-slate-600 hover:text-rose-400 hover:bg-rose-500/10 rounded-lg transition-all opacity-0 group-hover:opacity-100">
                                                        <Trash size={16} />
                                                    </button>
                                                </div>
                                            ))}
                                        </div>
                                    </motion.div>
                                )}

                                {currentTab === 'security' && (
                                    <motion.div
                                        key="security"
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
                                                onClick={handleChangePassword}
                                                disabled={isChangingPassword}
                                                className="w-full py-3 bg-primary hover:bg-primary-light border border-primary/20 rounded-xl text-xs font-bold text-black flex items-center justify-center gap-2 transition-all disabled:opacity-50"
                                            >
                                                {isChangingPassword ? <Loader2 className="animate-spin w-4 h-4" /> : <Save size={16} />}
                                                Şifreyi Güncelle
                                            </button>
                                        </div>
                                    </motion.div>
                                )}
                            </AnimatePresence>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    );
}

function TabButton({ active, icon, label, onClick }: { active: boolean; icon: React.ReactNode; label: string; onClick: () => void }) {
    return (
        <button
            onClick={onClick}
            className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-bold transition-all ${active
                ? 'bg-primary text-black shadow-lg shadow-primary/20'
                : 'text-slate-400 hover:bg-white/5 hover:text-white'
                }`}
        >
            <div className={`${active ? 'text-black' : 'text-slate-500'}`}>{icon}</div>
            {label}
        </button>
    );
}

export default function SettingsPage() {
    return (
        <Suspense fallback={<div className="min-h-screen bg-slate-950 flex items-center justify-center text-white"><Loader2 className="animate-spin mr-2" /> Yükleniyor...</div>}>
            <SettingsContent />
        </Suspense>
    );
}
