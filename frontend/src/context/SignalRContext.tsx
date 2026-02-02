"use client";

import React, { createContext, useContext, useEffect, useState, ReactNode, useRef } from 'react';
import { HubConnection, HubConnectionBuilder } from "@microsoft/signalr";
import { HUB_URL } from "@/lib/api";

interface SignalRContextType {
    connection: HubConnection | null;
    isConnected: boolean;
}

const SignalRContext = createContext<SignalRContextType | undefined>(undefined);

export function SignalRProvider({ children }: { children: ReactNode }) {
    const [connection, setConnection] = useState<HubConnection | null>(null);
    const [isConnected, setIsConnected] = useState(false);
    const connectionRef = useRef<HubConnection | null>(null);

    useEffect(() => {
        const token = localStorage.getItem("token");
        const isPublicPage = window.location.pathname === "/login" || window.location.pathname === "/register";

        if (!token || isPublicPage) return;

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
                // "stopped during negotiation" hatasını yoksay
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
            newConnection.stop();
        };
    }, []);

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
