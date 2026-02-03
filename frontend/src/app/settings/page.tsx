"use client";

import React, { useState, useEffect, Suspense } from "react";
import { SettingsService, UserService, AuthService } from "@/lib/api";
import { toast } from "sonner";
import { AnimatePresence } from "framer-motion";
import { Settings as SettingsIcon, Loader2 } from "lucide-react";
import Navbar from "@/components/ui/Navbar";
import { User as UserType } from "@/types";
import { useSearchParams } from "next/navigation";

// Modular Components
import { SettingsSidebar } from "@/components/settings/SettingsSidebar";
import { ApiSettings } from "@/components/settings/ApiSettings";
import { GeneralSettings } from "@/components/settings/GeneralSettings";
import { UserManagement } from "@/components/settings/UserManagement";
import { SecuritySettings } from "@/components/settings/SecuritySettings";

function SettingsContent() {
    const searchParams = useSearchParams();
    const [currentTab, setCurrentTab] = useState<'api' | 'general' | 'users' | 'security'>('api');
    const [user, setUser] = useState<UserType | null>(null);

    // Shared States
    const [isSaving, setIsSaving] = useState(false);

    // API Keys States
    const [existingKey, setExistingKey] = useState<string | null>(null);
    const [apiKey, setApiKey] = useState("");
    const [secretKey, setSecretKey] = useState("");

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
                <SettingsSidebar currentTab={currentTab} setCurrentTab={setCurrentTab} />

                <div className="lg:col-span-3">
                    <div className="glass-card min-h-[500px] flex flex-col bg-slate-900/50 border border-white/5 shadow-2xl overflow-hidden rounded-2xl">
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
                                    <ApiSettings
                                        key="api"
                                        existingKey={existingKey}
                                        apiKey={apiKey}
                                        setApiKey={setApiKey}
                                        secretKey={secretKey}
                                        setSecretKey={setSecretKey}
                                        isSaving={isSaving}
                                        onSave={handleSaveApiKeys}
                                    />
                                )}

                                {currentTab === 'general' && (
                                    <GeneralSettings
                                        key="general"
                                        settings={generalSettings}
                                        setSettings={setGeneralSettings}
                                        isSaving={isSaving}
                                        onSave={handleSaveGeneralSettings}
                                    />
                                )}

                                {currentTab === 'users' && (
                                    <UserManagement
                                        key="users"
                                        users={users}
                                        isAddingUser={isAddingUser}
                                        setIsAddingUser={setIsAddingUser}
                                        newUser={newUser}
                                        setNewUser={setNewUser}
                                        handleAddUser={handleAddUser}
                                        handleDeleteUser={handleDeleteUser}
                                    />
                                )}

                                {currentTab === 'security' && (
                                    <SecuritySettings
                                        key="security"
                                        passwords={passwords}
                                        setPasswords={setPasswords}
                                        isChangingPassword={isChangingPassword}
                                        onChangePassword={handleChangePassword}
                                    />
                                )}
                            </AnimatePresence>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    );
}

export default function SettingsPage() {
    return (
        <Suspense fallback={<div className="min-h-screen bg-slate-950 flex items-center justify-center text-white"><Loader2 className="animate-spin mr-2" /> Yükleniyor...</div>}>
            <SettingsContent />
        </Suspense>
    );
}
