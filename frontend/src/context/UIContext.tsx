"use client";

import React, { createContext, useContext, useState, ReactNode } from 'react';
import LogsDrawer from '@/components/ui/LogsDrawer';
import WalletModal from '@/components/ui/WalletModal';

interface UIContextType {
    openLogs: () => void;
    closeLogs: () => void;
    openWallet: () => void;
    closeWallet: () => void;
}

const UIContext = createContext<UIContextType | undefined>(undefined);

export function UIProvider({ children }: { children: ReactNode }) {
    const [isLogsOpen, setIsLogsOpen] = useState(false);
    const [isWalletOpen, setIsWalletOpen] = useState(false);

    const openLogs = () => setIsLogsOpen(true);
    const closeLogs = () => setIsLogsOpen(false);

    const openWallet = () => setIsWalletOpen(true);
    const closeWallet = () => setIsWalletOpen(false);

    return (
        <UIContext.Provider value={{ openLogs, closeLogs, openWallet, closeWallet }}>
            {children}
            <LogsDrawer
                isOpen={isLogsOpen}
                onClose={closeLogs}
            />
            <WalletModal
                isOpen={isWalletOpen}
                onClose={closeWallet}
            />
        </UIContext.Provider>
    );
}

export function useUI() {
    const context = useContext(UIContext);
    if (context === undefined) {
        throw new Error('useUI must be used within a UIProvider');
    }
    return context;
}
