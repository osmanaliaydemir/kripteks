"use client";

import React from "react";

interface TabButtonProps {
    id: 'active' | 'history';
    label: string;
    count?: number;
    activeTab: string;
    setActiveTab: (id: 'active' | 'history') => void;
    icon: React.ReactNode;
}

export function TabButton({ id, label, count, activeTab, setActiveTab, icon }: TabButtonProps) {
    return (
        <button
            onClick={() => setActiveTab(id)}
            className={`px-4 py-2.5 rounded-lg text-xs font-bold transition-all flex items-center gap-2.5 ${activeTab === id
                ? 'bg-slate-800 text-white shadow-lg ring-1 ring-white/10'
                : 'text-slate-400 hover:text-white hover:bg-slate-800/50'
                }`}
        >
            {icon}
            {label}
            {count !== undefined && <span className={`px-1.5 py-0.5 rounded text-[10px] bg-slate-700 text-slate-300 ml-1`}>{count}</span>}
        </button>
    );
}
