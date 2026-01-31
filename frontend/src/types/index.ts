export interface Bot {
    id: string;
    symbol: string;
    strategyName: string;
    amount: number;
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
