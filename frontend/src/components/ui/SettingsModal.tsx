import React, { useState, useEffect } from "react";
import { SettingsService, UserService } from "@/lib/api";
import { toast } from "sonner";
import { AnimatePresence, motion } from "framer-motion";
import { AlertTriangle, CheckCircle, Eye, EyeOff, Key, Save, Settings, Trash, User, UserPlus, X, BadgeCheck } from "lucide-react";

interface SettingsModalProps {
    isOpen: boolean;
    onClose: () => void;
    activeTab?: 'api' | 'general' | 'users';
}

export default function SettingsModal({ isOpen, onClose, activeTab = 'api' }: SettingsModalProps) {
    const [currentTab, setCurrentTab] = useState<'api' | 'general' | 'users'>(activeTab);
    const [showApiKey, setShowApiKey] = useState(false);
    const [showSecretKey, setShowSecretKey] = useState(false);
    const [existingKey, setExistingKey] = useState<string | null>(null);

    // Form States
    const [apiKey, setApiKey] = useState("");
    const [secretKey, setSecretKey] = useState("");
    const [isSaving, setIsSaving] = useState(false);

    // User Management States
    const [users, setUsers] = useState<any[]>([]);
    const [isAddingUser, setIsAddingUser] = useState(false);
    const [showUserPassword, setShowUserPassword] = useState(false);
    const [newUser, setNewUser] = useState({ firstName: "", lastName: "", email: "", password: "", role: "User" });

    // Prop değiştiğinde tab'ı güncelle
    useEffect(() => {
        setCurrentTab(activeTab);
    }, [activeTab]);

    // Tab veya Modal durumu değiştiğinde veriyi yükle
    useEffect(() => {
        if (isOpen) {
            if (currentTab === 'api') loadKeys();
            if (currentTab === 'users') loadUsers();
        }
    }, [isOpen, currentTab]);

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
            toast.error("Hata", { description: "Kullanıcı listesi güncellenemedi." });
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
            toast.success("Kullanıcı Silindi", { description: "Kullanıcı başarıyla sistemden kaldırıldı." });
            loadUsers();
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : "Silme işlemi başarısız.";
            toast.error("Hata", { description: errorMessage });
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
            setShowUserPassword(false);
            setIsAddingUser(false);
            loadUsers();
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : "Kullanıcı eklenemedi.";
            toast.error("Hata", { description: errorMessage });
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

    if (!isOpen) return null;

    return (
        <AnimatePresence>
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 bg-black/60 backdrop-blur-sm">
                <motion.div
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0, scale: 0.95 }}
                    className="w-full max-w-4xl bg-slate-900 border border-slate-800 rounded-2xl shadow-2xl overflow-hidden flex flex-col md:flex-row h-[600px] max-h-[85vh]"
                >
                    {/* SIDEBAR */}
                    <div className="w-full md:w-64 bg-slate-950/50 border-r border-slate-800 p-4 flex flex-col gap-2">
                        <div className="mb-6 px-2">
                            <h2 className="text-lg font-bold text-white font-display">Ayarlar</h2>
                            <p className="text-xs text-slate-500">Sistem yapılandırması</p>
                        </div>

                        <button
                            onClick={() => setCurrentTab('api')}
                            className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all ${currentTab === 'api' ? 'bg-amber-500/10 text-amber-500 border border-amber-500/20 shadow-sm' : 'text-slate-400 hover:bg-slate-800 hover:text-white'}`}
                        >
                            <Key size={18} />
                            API Bağlantıları
                        </button>

                        <button
                            onClick={() => setCurrentTab('general')}
                            className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all ${currentTab === 'general' ? 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/20 shadow-sm' : 'text-slate-400 hover:bg-slate-800 hover:text-white'}`}
                        >
                            <Settings size={18} />
                            Genel Ayarlar
                        </button>

                        <button
                            onClick={() => setCurrentTab('users')}
                            className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all ${currentTab === 'users' ? 'bg-purple-500/10 text-purple-400 border border-purple-500/20 shadow-sm' : 'text-slate-400 hover:bg-slate-800 hover:text-white'}`}
                        >
                            <User size={18} />
                            Kullanıcılar
                        </button>
                    </div>

                    {/* CONTENT AREA */}
                    <div className="flex-1 flex flex-col min-h-0 bg-slate-900">
                        {/* Header */}
                        <div className="h-16 border-b border-slate-800 flex items-center justify-between px-6 shrink-0">
                            <div>
                                <h3 className="text-lg font-bold text-white font-display">
                                    {currentTab === 'api' && 'Borsa API Bağlantıları'}
                                    {currentTab === 'general' && 'Sistem Ayarları'}
                                    {currentTab === 'users' && 'Kullanıcı Yönetimi'}
                                </h3>
                            </div>
                            <button onClick={onClose} className="p-2 hover:bg-slate-800 rounded-lg text-slate-400 hover:text-white transition-colors">
                                <X size={20} />
                            </button>
                        </div>

                        {/* Scrollable Content */}
                        <div className="flex-1 overflow-y-auto p-6 md:p-8">

                            {/* --- API TAB --- */}
                            {currentTab === 'api' && (
                                <div className="space-y-6 max-w-2xl">
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
                                                Güvenliğiniz için &quot;Para Çekme (Withdrawal)&quot; iznini <u>asla</u> aktifleştirmeyin.
                                                Sadece &quot;Spot Trading&quot; ve &quot;Futures Trading&quot; izinleri yeterlidir.
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
                                                    className="w-full bg-slate-950/50 border border-slate-800 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-amber-500/50 focus:ring-1 focus:ring-amber-500/50 font-mono transition-all"
                                                />
                                                <button
                                                    onClick={() => setShowApiKey(!showApiKey)}
                                                    className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 p-1"
                                                >
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
                                                    className="w-full bg-slate-950/50 border border-slate-800 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-amber-500/50 focus:ring-1 focus:ring-amber-500/50 font-mono transition-all"
                                                />
                                                <button
                                                    onClick={() => setShowSecretKey(!showSecretKey)}
                                                    className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 p-1"
                                                >
                                                    {showSecretKey ? <EyeOff size={16} /> : <Eye size={16} />}
                                                </button>
                                            </div>
                                        </div>
                                    </div>

                                    <div className="pt-4 flex items-center justify-end gap-3">
                                        <button onClick={onClose} className="px-5 py-2.5 rounded-xl text-xs font-bold text-slate-400 hover:text-white hover:bg-slate-800 bg-transparent border border-transparent transition-all">
                                            İptal
                                        </button>
                                        <button
                                            onClick={handleSaveApiKeys}
                                            disabled={isSaving}
                                            className="px-6 py-2.5 rounded-xl text-xs font-bold text-black bg-amber-500 hover:bg-amber-400 shadow-lg shadow-amber-500/20 flex items-center gap-2 transition-all disabled:opacity-50"
                                        >
                                            {isSaving ? (
                                                <div className="w-4 h-4 border-2 border-black/30 border-t-black rounded-full animate-spin"></div>
                                            ) : (
                                                <Save size={16} />
                                            )}
                                            API Ayarlarını Kaydet
                                        </button>
                                    </div>
                                </div>
                            )}

                            {/* --- GENERAL TAB --- */}
                            {currentTab === 'general' && (
                                <div className="flex flex-col items-center justify-center h-64 text-center">
                                    <div className="w-16 h-16 bg-slate-800 rounded-2xl flex items-center justify-center mb-4">
                                        <Settings className="text-slate-500" size={32} />
                                    </div>
                                    <h3 className="text-white font-bold mb-1">Genel Ayarlar</h3>
                                    <p className="text-slate-500 text-sm max-w-xs">Bu panel yapım aşamasındadır. Yakında buradan sistem parametrelerini yönetebileceksiniz.</p>
                                </div>
                            )}

                            {/* --- USERS TAB --- */}
                            {currentTab === 'users' && (
                                <div className="space-y-6">
                                    <div className="flex items-center justify-between">
                                        <div>
                                            <h4 className="text-base font-bold text-white">Sistem Yöneticileri</h4>
                                            <p className="text-xs text-slate-500">Sisteme erişimi olan kullanıcılar</p>
                                        </div>
                                        <button
                                            onClick={() => setIsAddingUser(!isAddingUser)}
                                            className="px-4 py-2 bg-purple-600 hover:bg-purple-500 text-white rounded-lg text-xs font-bold flex items-center gap-2 shadow-lg shadow-purple-500/20 transition-all"
                                        >
                                            <UserPlus size={16} />
                                            Yeni Ekle
                                        </button>
                                    </div>

                                    {/* Add User Form */}
                                    {isAddingUser && (
                                        <motion.div
                                            initial={{ opacity: 0, height: 0 }}
                                            animate={{ opacity: 1, height: 'auto' }}
                                            className="bg-slate-950/50 border border-slate-800 rounded-xl p-4 mb-4 overflow-hidden"
                                        >
                                            <div className="grid grid-cols-2 gap-4 mb-4">
                                                <div>
                                                    <label className="text-xs font-medium text-slate-400 mb-1 block">Ad</label>
                                                    <input
                                                        type="text"
                                                        value={newUser.firstName}
                                                        onChange={(e) => setNewUser({ ...newUser, firstName: e.target.value })}
                                                        className="w-full bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500/50"
                                                    />
                                                </div>
                                                <div>
                                                    <label className="text-xs font-medium text-slate-400 mb-1 block">Soyad</label>
                                                    <input
                                                        type="text"
                                                        value={newUser.lastName}
                                                        onChange={(e) => setNewUser({ ...newUser, lastName: e.target.value })}
                                                        className="w-full bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500/50"
                                                    />
                                                </div>
                                                <div className="col-span-2">
                                                    <label className="text-xs font-medium text-slate-400 mb-1 block">E-Posta</label>
                                                    <input
                                                        type="email"
                                                        value={newUser.email}
                                                        onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
                                                        className="w-full bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500/50"
                                                    />
                                                </div>
                                                <div className="col-span-2">
                                                    <label className="text-xs font-medium text-slate-400 mb-1 block">Rol</label>
                                                    <select
                                                        value={newUser.role}
                                                        onChange={(e) => setNewUser({ ...newUser, role: e.target.value })}
                                                        className="w-full bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500/50 appearance-none cursor-pointer"
                                                    >
                                                        <option value="Admin">Yönetici (Tam Erişim)</option>
                                                        <option value="Trader">Trader (Sadece İşlem)</option>
                                                        <option value="User">User (İzleme Yetkisi)</option>
                                                    </select>
                                                </div>
                                                <div className="col-span-2">
                                                    <label className="text-xs font-medium text-slate-400 mb-1 block">Şifre</label>
                                                    <div className="relative">
                                                        <input
                                                            type={showUserPassword ? "text" : "password"}
                                                            value={newUser.password}
                                                            onChange={(e) => setNewUser({ ...newUser, password: e.target.value })}
                                                            className="w-full bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500/50 pr-10"
                                                        />
                                                        <button
                                                            type="button"
                                                            onClick={() => setShowUserPassword(!showUserPassword)}
                                                            className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 p-1"
                                                        >
                                                            {showUserPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                                                        </button>
                                                    </div>
                                                </div>
                                            </div>
                                            <div className="flex justify-end gap-3">
                                                <button onClick={() => setIsAddingUser(false)} className="text-xs font-bold text-slate-400 hover:text-white px-3 py-1.5">İptal</button>
                                                <button onClick={handleAddUser} className="text-xs font-bold bg-purple-600 hover:bg-purple-500 text-white px-4 py-1.5 rounded-lg shadow-lg shadow-purple-500/20">Kaydet</button>
                                            </div>
                                        </motion.div>
                                    )}

                                    {/* Users List */}
                                    <div className="bg-slate-950/30 border border-slate-800/50 rounded-xl overflow-hidden">
                                        <table className="w-full text-left border-collapse">
                                            <thead>
                                                <tr className="border-b border-slate-800/50 text-xs text-slate-500 uppercase">
                                                    <th className="px-4 py-3 font-medium">Kullanıcı</th>
                                                    <th className="px-4 py-3 font-medium">E-Posta</th>
                                                    <th className="px-4 py-3 font-medium">Rol</th>
                                                    <th className="px-4 py-3 font-medium text-right">İşlem</th>
                                                </tr>
                                            </thead>
                                            <tbody className="divide-y divide-slate-800/50">
                                                {users.map((u, i) => (
                                                    <tr key={i} className="hover:bg-slate-800/20 transition-colors">
                                                        <td className="px-4 py-3">
                                                            <div className="flex items-center gap-3">
                                                                <div className="w-8 h-8 rounded-full bg-linear-to-tr from-purple-500 to-pink-500 flex items-center justify-center text-white text-xs font-bold">
                                                                    {u.firstName?.[0] || 'U'}
                                                                </div>
                                                                <span className="text-sm font-bold text-white">{u.firstName} {u.lastName}</span>
                                                            </div>
                                                        </td>
                                                        <td className="px-4 py-3 text-sm text-slate-400">{u.email}</td>
                                                        <td className="px-4 py-3">
                                                            <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-green-500/10 text-green-400 border border-green-500/20 flex items-center w-fit gap-1">
                                                                <BadgeCheck size={12} />
                                                                {u.role || u.Role || 'User'}
                                                            </span>
                                                        </td>
                                                        <td className="px-4 py-3 text-right">
                                                            <button
                                                                onClick={() => handleDeleteUser(u.id, u.role)}
                                                                className="text-slate-500 hover:text-red-400 transition-colors p-1"
                                                            >
                                                                <Trash size={16} />
                                                            </button>
                                                        </td>
                                                    </tr>
                                                ))}
                                                {users.length === 0 && (
                                                    <tr>
                                                        <td colSpan={4} className="px-4 py-8 text-center text-slate-500 text-sm">
                                                            Hiç kullanıcı bulunamadı.
                                                        </td>
                                                    </tr>
                                                )}
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            )}
                        </div>
                    </div>
                </motion.div>
            </div>
        </AnimatePresence>
    );
}
