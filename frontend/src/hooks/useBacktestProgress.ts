"use client";

import { useEffect, useState, useCallback, useRef } from 'react';
import { HubConnection, HubConnectionBuilder } from "@microsoft/signalr";

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:5072";
const BACKTEST_HUB_URL = `${API_BASE}/backtest-hub`;

interface BacktestProgress {
    sessionId: string;
    currentStep: number;
    totalSteps: number;
    currentParameters: string;
    currentPnlPercent: number | null;
    bestPnlPercent: number | null;
    status: 'idle' | 'running' | 'completed' | 'error';
    progressPercent: number;
}

interface UseBacktestProgressReturn {
    progress: BacktestProgress | null;
    isConnected: boolean;
    startSession: (sessionId: string) => Promise<void>;
    endSession: (sessionId: string) => Promise<void>;
    resetProgress: () => void;
}

export function useBacktestProgress(): UseBacktestProgressReturn {
    const [progress, setProgress] = useState<BacktestProgress | null>(null);
    const [isConnected, setIsConnected] = useState(false);
    const connectionRef = useRef<HubConnection | null>(null);

    useEffect(() => {
        let isMounted = true;
        let retryTimeout: NodeJS.Timeout;

        const startConnection = async () => {
            if (!connectionRef.current) {
                const newConnection = new HubConnectionBuilder()
                    .withUrl(BACKTEST_HUB_URL, {
                        accessTokenFactory: () => localStorage.getItem("token") || ""
                    })
                    .withAutomaticReconnect()
                    .build();

                connectionRef.current = newConnection;

                // Listen for progress updates
                newConnection.on("ReceiveProgress", (data: BacktestProgress) => {
                    if (isMounted) {
                        setProgress({
                            ...data,
                            progressPercent: data.totalSteps > 0
                                ? Math.round((data.currentStep / data.totalSteps) * 100)
                                : 0
                        });
                    }
                });

                // Listen for completion
                newConnection.on("ReceiveOptimizationComplete", (data: { sessionId: string; success: boolean }) => {
                    if (isMounted) {
                        setProgress(prev => prev ? { ...prev, status: data.success ? 'completed' : 'error' } : null);
                    }
                });

                newConnection.onclose(() => isMounted && setIsConnected(false));
                newConnection.onreconnecting(() => isMounted && setIsConnected(false));
                newConnection.onreconnected(() => isMounted && setIsConnected(true));
            }

            const conn = connectionRef.current;
            if (conn.state !== "Disconnected") return;

            try {
                await conn.start();
                if (isMounted) {
                    console.log("Backtest SignalR Connected!");
                    setIsConnected(true);
                }
            } catch (err: any) {
                if (isMounted && !err.message?.includes("stopped during negotiation")) {
                    console.error("Backtest SignalR Connection Error: ", err);
                    retryTimeout = setTimeout(startConnection, 5000);
                }
            }
        };

        startConnection();

        return () => {
            isMounted = false;
            if (retryTimeout) clearTimeout(retryTimeout);

            if (connectionRef.current && connectionRef.current.state !== "Disconnected") {
                const conn = connectionRef.current;
                connectionRef.current = null;
                conn.stop().catch(() => {
                    // Silent catch for stop errors on unmount
                });
            }
        };
    }, []);

    const startSession = useCallback(async (sessionId: string) => {
        if (connectionRef.current && connectionRef.current.state === "Connected") {
            await connectionRef.current.invoke("JoinBacktestSession", sessionId);
            setProgress({
                sessionId,
                currentStep: 0,
                totalSteps: 0,
                currentParameters: "",
                currentPnlPercent: null,
                bestPnlPercent: null,
                status: 'running',
                progressPercent: 0
            });
        }
    }, []);

    const endSession = useCallback(async (sessionId: string) => {
        if (connectionRef.current && connectionRef.current.state === "Connected") {
            await connectionRef.current.invoke("LeaveBacktestSession", sessionId);
        }
    }, []);

    const resetProgress = useCallback(() => {
        setProgress(null);
    }, []);

    return { progress, isConnected, startSession, endSession, resetProgress };
}
