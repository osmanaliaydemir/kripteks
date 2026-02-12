export enum AlertType {
    Price = 'Price',
    Indicator = 'Indicator'
}

export enum AlertCondition {
    Above = 'Above',
    Below = 'Below',
    CrossOver = 'CrossOver',
    CrossUnder = 'CrossUnder'
}

export interface Alert {
    id: string;
    symbol: string;
    type: AlertType;
    targetValue: number;
    condition: AlertCondition;
    indicatorName?: string;
    timeframe?: string;
    isEnabled: boolean;
    createdAt: string;
    lastTriggeredAt?: string;
}

export interface CreateAlertDto {
    symbol: string;
    type: AlertType;
    targetValue: number;
    condition: AlertCondition;
    indicatorName?: string;
    timeframe?: string;
}

export interface UpdateAlertDto {
    targetValue: number;
    isEnabled: boolean;
    cooldownMinutes: number;
}
