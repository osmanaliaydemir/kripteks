export interface Bot {
    id: string;
    symbol: string;
    strategyName: string;
    amount: number;
    interval: string;
    status: 'Running' | 'Stopped' | 'Paused' | 'Completed' | 'WaitingForEntry';
    pnl: number;
    pnlPercent: number;
    entryPrice?: number;
    takeProfit?: number;
    stopLoss?: number;
    createdAt: string;
    logs?: { id: number; message: string; level: number; timestamp: string }[];
}

export interface Coin {
    id?: string;
    symbol: string;
    price: number;
}

export interface Strategy {
    id: string;
    name: string;
}

export interface Wallet {
    current_balance: number;
    available_balance: number;
    locked_balance: number;
    total_pnl: number;
}

export interface WalletTransaction {
    id: string;
    amount: number;
    type: string;
    description: string;
    createdAt: string;
}

export interface User {
    id?: string;
    firstName: string;
    lastName: string;
    email: string;
    role?: string;
    Role?: string; // Fallback for backend serialization mismatch
}

export interface DashboardStats {
    active_bots: number;
    total_volume: number;
    win_rate: number;
}

export interface Trade {
    date: string;
    type: "BUY" | "SELL";
    price: number;
    amount: number;
    pnl: number;
}

export interface LogEntry {
    id: string;
    level: string;
    message: string;
    timestamp: string;
}
