"use client";

import React, { createContext, useContext, useState, ReactNode } from 'react';
import LogsDrawer from '@/components/ui/LogsDrawer';
import WalletModal from '@/components/ui/WalletModal';
import AccessDeniedModal from '@/components/ui/AccessDeniedModal';

interface UIContextType {
    openLogs: () => void;
    closeLogs: () => void;
    openWallet: () => void;
    closeWallet: () => void;
    openAccessDenied: () => void;
    closeAccessDenied: () => void;
}

const UIContext = createContext<UIContextType | undefined>(undefined);

export function UIProvider({ children }: { children: ReactNode }) {
    const [isLogsOpen, setIsLogsOpen] = useState(false);
    const [isWalletOpen, setIsWalletOpen] = useState(false);
    const [isAccessDeniedOpen, setIsAccessDeniedOpen] = useState(false);

    const openLogs = () => setIsLogsOpen(true);
    const closeLogs = () => setIsLogsOpen(false);

    const openWallet = () => setIsWalletOpen(true);
    const closeWallet = () => setIsWalletOpen(false);

    const openAccessDenied = () => setIsAccessDeniedOpen(true);
    const closeAccessDenied = () => setIsAccessDeniedOpen(false);

    React.useEffect(() => {
        const handleUnauthorized = () => {
            openAccessDenied();
        };

        window.addEventListener('UNAUTHORIZED_ACTION', handleUnauthorized);
        return () => window.removeEventListener('UNAUTHORIZED_ACTION', handleUnauthorized);
    }, []);

    return (
        <UIContext.Provider value={{ openLogs, closeLogs, openWallet, closeWallet, openAccessDenied, closeAccessDenied }}>
            {children}
            <LogsDrawer
                isOpen={isLogsOpen}
                onClose={closeLogs}
            />
            <WalletModal
                isOpen={isWalletOpen}
                onClose={closeWallet}
            />
            <AccessDeniedModal
                isOpen={isAccessDeniedOpen}
                onClose={closeAccessDenied}
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
