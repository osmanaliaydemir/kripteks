"use client";

import React from "react";
import { Key, Bell, User, ShieldCheck } from "lucide-react";

interface SettingsSidebarProps {
    currentTab: 'api' | 'general' | 'users' | 'security';
    setCurrentTab: (tab: 'api' | 'general' | 'users' | 'security') => void;
}

export function SettingsSidebar({ currentTab, setCurrentTab }: SettingsSidebarProps) {
    const tabs = [
        { id: 'api', label: 'API Bağlantıları', icon: <Key size={18} /> },
        { id: 'general', label: 'Genel & Bildirim', icon: <Bell size={18} /> },
        { id: 'users', label: 'Kullanıcı Yönetimi', icon: <User size={18} /> },
        { id: 'security', label: 'Güvenlik & Şifre', icon: <ShieldCheck size={18} /> },
    ] as const;

    return (
        <div className="lg:col-span-1 space-y-2">
            {tabs.map((tab) => (
                <button
                    key={tab.id}
                    onClick={() => setCurrentTab(tab.id)}
                    className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-bold transition-all ${currentTab === tab.id
                        ? 'bg-primary text-black shadow-lg shadow-primary/20'
                        : 'text-slate-400 hover:bg-white/5 hover:text-white'
                        }`}
                >
                    <div className={`${currentTab === tab.id ? 'text-black' : 'text-slate-500'}`}>{tab.icon}</div>
                    {tab.label}
                </button>
            ))}
        </div>
    );
}
