"use client";

import React, { createContext, useContext, useEffect, useState, ReactNode, useRef } from 'react';
import { HubConnection, HubConnectionBuilder } from "@microsoft/signalr";
import { HUB_URL } from "@/lib/api";
import { usePathname } from 'next/navigation';

interface SignalRContextType {
    connection: HubConnection | null;
    isConnected: boolean;
}

const SignalRContext = createContext<SignalRContextType | undefined>(undefined);

export function SignalRProvider({ children }: { children: ReactNode }) {
    const [connection, setConnection] = useState<HubConnection | null>(null);
    const [isConnected, setIsConnected] = useState(false);
    const connectionRef = useRef<HubConnection | null>(null);
    const pathname = usePathname();

    useEffect(() => {
        const token = localStorage.getItem("token");
        const isPublicPage = pathname === "/login" || pathname === "/register";

        if (!token || isPublicPage) {
            if (connectionRef.current) {
                connectionRef.current.stop();
                connectionRef.current = null;
                setConnection(null);
                setIsConnected(false);
            }
            return;
        }

        // Eğer zaten bağlı veya bağlanıyorsa tekrar deneme
        if (connectionRef.current) return;

        const newConnection = new HubConnectionBuilder()
            .withUrl(HUB_URL, {
                accessTokenFactory: () => localStorage.getItem("token") || ""
            })
            .withAutomaticReconnect()
            .build();

        connectionRef.current = newConnection;
        setConnection(newConnection);

        const startConnection = async () => {
            try {
                if (newConnection.state === "Disconnected") {
                    await newConnection.start();
                    console.log("SignalR Connected Globally!");
                    setIsConnected(true);
                }
            } catch (err: any) {
                if (!err.message?.includes("stopped during negotiation")) {
                    console.error("SignalR Global Connection Error: ", err);
                }
                setTimeout(startConnection, 5000);
            }
        };

        startConnection();

        newConnection.onclose(() => setIsConnected(false));
        newConnection.onreconnecting(() => setIsConnected(false));
        newConnection.onreconnected(() => setIsConnected(true));

        return () => {
            if (newConnection.state !== "Disconnected") {
                newConnection.stop();
            }
            connectionRef.current = null;
        };
    }, [pathname]);

    return (
        <SignalRContext.Provider value={{ connection, isConnected }}>
            {children}
        </SignalRContext.Provider>
    );
}

export function useSignalR() {
    const context = useContext(SignalRContext);
    if (context === undefined) {
        throw new Error('useSignalR must be used within a SignalRProvider');
    }
    return context;
}
