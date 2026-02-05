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
        let isMounted = true;

        const checkConnection = async () => {
            const token = localStorage.getItem("token");
            const isPublicPage = pathname === "/login" || pathname === "/register";

            if (!token || isPublicPage) {
                if (connectionRef.current) {
                    console.log("Stopping SignalR connection due to public page or missing token");
                    const conn = connectionRef.current;
                    connectionRef.current = null;
                    setConnection(null);
                    setIsConnected(false);
                    try {
                        await conn.stop();
                    } catch (e) {
                        // Ignore stop errors
                    }
                }
                return;
            }

            // If already connected or connecting, don't start a new one
            if (connectionRef.current && connectionRef.current.state !== "Disconnected") {
                return;
            }

            console.log("Initializing SignalR globally...");
            const newConnection = new HubConnectionBuilder()
                .withUrl(HUB_URL, {
                    accessTokenFactory: () => localStorage.getItem("token") || ""
                })
                .withAutomaticReconnect()
                .build();

            connectionRef.current = newConnection;
            setConnection(newConnection);

            newConnection.onclose(() => isMounted && setIsConnected(false));
            newConnection.onreconnecting(() => isMounted && setIsConnected(false));
            newConnection.onreconnected(() => isMounted && setIsConnected(true));

            try {
                await newConnection.start();
                if (isMounted) {
                    console.log("SignalR Connected Globally!");
                    setIsConnected(true);
                }
            } catch (err: any) {
                if (isMounted && !err.message?.includes("stopped during negotiation")) {
                    console.error("SignalR Global Connection Error: ", err);
                    // Re-check after a delay
                    setTimeout(checkConnection, 5000);
                }
            }
        };

        checkConnection();

        return () => {
            isMounted = false;
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
