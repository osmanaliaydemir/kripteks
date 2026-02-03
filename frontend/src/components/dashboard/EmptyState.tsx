"use client";

import React from "react";

interface EmptyStateProps {
    title: string;
    description: string;
    icon: React.ReactNode;
}

export function EmptyState({ title, description, icon }: EmptyStateProps) {
    return (
        <div className="flex flex-col items-center justify-center py-20 bg-slate-900/40 border border-dashed border-slate-800 rounded-3xl">
            <div className="w-16 h-16 bg-slate-800/50 rounded-full flex items-center justify-center mb-4 text-slate-600">
                {icon}
            </div>
            <h3 className="text-white font-display font-bold text-lg mb-2">{title}</h3>
            <p className="text-slate-500 text-sm max-w-xs text-center">{description}</p>
        </div>
    );
}
