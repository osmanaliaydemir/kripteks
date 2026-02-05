export interface Log {
    id: number | string;
    message: string;
    level: string; // 'Info' | 'Warning' | 'Error'
    timestamp: string;
    botId?: string;
}

export interface Trade {
    id: string;
    botId: string;
    symbol: string;
    type: 0 | 1; // 0=Buy, 1=Sell (Backend Enum)
    price: number;
    quantity: number;
    total: number;
    timestamp: string;
}

export interface Bot {
    id: string;
    symbol: string;
    strategyId?: string;
    strategyName: string;
    amount: number;
    interval: string;
    status: 'Running' | 'Stopped' | 'Paused' | 'Completed' | 'WaitingForEntry';
    pnl: number;
    pnlPercent: number;
    currentPnl: number;
    entryPrice?: number;
    takeProfit?: number;
    stopLoss?: number;
    createdAt: string;
    isTrailingStop: boolean;
    trailingStopDistance?: number;
    maxPriceReached?: number;
    logs?: Log[];
    trades?: Trade[];
}

export interface Coin {
    id?: string;
    symbol: string;
    price: number;
}

export interface Strategy {
    id: string;
    name: string;
    description?: string;
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

export interface ScannerResultItem {
    symbol: string;
    signalScore: number;
    suggestedAction: string | number; // backend may send string (Buy/Sell) or number (1/2)
    comment: string;
    lastPrice: number;
}

export interface ScannerFavoriteList {
    id: string;
    name: string;
    symbols: string[];
    createdAt: string;
}
