const BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:5292";
export const API_URL = `${BASE_URL}/api`;
export const HUB_URL = `${BASE_URL}/bot-hub`;

const getHeaders = () => {
    const token = typeof window !== "undefined" ? localStorage.getItem("token") : "";
    return {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`
    };
};

const fetchWithAuth = async (url: string, options: RequestInit = {}) => {
    const res = await fetch(url, {
        ...options,
        headers: {
            ...getHeaders(),
            ...options.headers
        }
    });

    if (res.status === 401) {
        if (typeof window !== "undefined") {
            localStorage.removeItem("token");
            localStorage.removeItem("user");
            window.location.href = "/login";
        }
    }

    if (res.status === 403) {
        if (typeof window !== "undefined") {
            window.dispatchEvent(new CustomEvent('UNAUTHORIZED_ACTION'));
        }
    }

    return res;
};

const handleResponse = async (res: Response) => {
    if (res.status === 403) return { _unauthorized: true };

    if (!res.ok) {
        let errorMsg = "Bir hata oluştu";
        try {
            const errorData = await res.json();
            errorMsg = errorData.message || errorMsg;
        } catch {
            // Non-JSON error body or empty
            errorMsg = `Hata: ${res.status} ${res.statusText}`;
        }
        throw new Error(errorMsg);
    }

    // Success case: Try to parse JSON
    try {
        const text = await res.text();
        return text ? JSON.parse(text) : {};
    } catch {
        return {};
    }
};

export const BotService = {
    getAll: async (page: number = 1, pageSize: number = 100) => {
        const res = await fetchWithAuth(`${API_URL}/bots?page=${page}&pageSize=${pageSize}`);
        return handleResponse(res);
    },
    getById: async (id: string) => {
        const res = await fetchWithAuth(`${API_URL}/bots/${id}`);
        return handleResponse(res);
    },
    create: async (bot: any) => {
        const res = await fetchWithAuth(`${API_URL}/bots/start`, {
            method: "POST",
            body: JSON.stringify(bot)
        });
        return handleResponse(res);
    },
    update: async (id: string, bot: any) => {
        const res = await fetchWithAuth(`${API_URL}/bots/${id}`, {
            method: "PUT",
            body: JSON.stringify(bot)
        });
        return handleResponse(res);
    },
    delete: async (id: string) => {
        const res = await fetchWithAuth(`${API_URL}/bots/${id}`, {
            method: "DELETE"
        });
        return handleResponse(res);
    },
    start: async (id: string) => {
        const res = await fetchWithAuth(`${API_URL}/bots/${id}/start`, {
            method: "POST"
        });
        return handleResponse(res);
    },
    stop: async (id: string) => {
        const res = await fetchWithAuth(`${API_URL}/bots/${id}/stop`, {
            method: "POST"
        });
        return handleResponse(res);
    },
    stopAll: async () => {
        const res = await fetchWithAuth(`${API_URL}/bots/stop-all`, {
            method: "POST"
        });
        return handleResponse(res);
    },
    clearHistory: async () => {
        const res = await fetchWithAuth(`${API_URL}/bots/clear-history`, {
            method: "POST"
        });
        return handleResponse(res);
    },
    getBotLogs: async (botId: string, page: number = 1, pageSize: number = 50) => {
        const res = await fetchWithAuth(`${API_URL}/bots/${botId}/logs?page=${page}&pageSize=${pageSize}`);
        return handleResponse(res);
    }
};

export const MarketService = {
    getMarkets: async (market: string = "crypto") => {
        const res = await fetchWithAuth(`${API_URL}/stocks?market=${market}`);
        return handleResponse(res);
    },
    getCoins: async (market: string = "crypto") => {
        const res = await fetchWithAuth(`${API_URL}/stocks?market=${market}`);
        return handleResponse(res);
    },
    getStrategies: async (category?: string) => {
        const query = category ? `?category=${category}` : '';
        const res = await fetchWithAuth(`${API_URL}/strategies${query}`);
        return handleResponse(res);
    },
    getStats: async () => {
        const res = await fetchWithAuth(`${API_URL}/analytics/stats`);
        return handleResponse(res);
    }
};

export const WalletService = {
    getWallet: async () => {
        const res = await fetchWithAuth(`${API_URL}/wallet`);
        return handleResponse(res);
    },
    get: async () => {
        const res = await fetchWithAuth(`${API_URL}/wallet`);
        return handleResponse(res);
    },
    getTransactions: async (page: number = 1, pageSize: number = 20) => {
        const res = await fetchWithAuth(`${API_URL}/wallet/transactions?page=${page}&pageSize=${pageSize}`);
        return handleResponse(res);
    }
};

export const AnalyticsService = {
    getStats: async () => {
        const res = await fetchWithAuth(`${API_URL}/analytics/stats`);
        return handleResponse(res);
    },
    getChartData: async () => {
        const res = await fetchWithAuth(`${API_URL}/analytics/chart`);
        return handleResponse(res);
    },
    getEquityCurve: async () => {
        const res = await fetchWithAuth(`${API_URL}/analytics/equity`);
        return handleResponse(res);
    },
    getStrategyPerformance: async () => {
        const res = await fetchWithAuth(`${API_URL}/analytics/performance`);
        return handleResponse(res);
    },
    getNews: async (symbol: string = "BTC") => {
        const res = await fetchWithAuth(`${API_URL}/analytics/news?symbol=${symbol}`);
        return handleResponse(res);
    },
    getSentiment: async (symbol: string = "BTC") => {
        const res = await fetchWithAuth(`${API_URL}/analytics/sentiment?symbol=${symbol}`);
        return handleResponse(res);
    }
};

export const LogService = {
    getLogs: async (limit: number = 50) => {
        const res = await fetchWithAuth(`${API_URL}/logs?limit=${limit}`);
        return handleResponse(res);
    },
    clear: async () => {
        const res = await fetchWithAuth(`${API_URL}/logs`, {
            method: "DELETE"
        });
        return handleResponse(res);
    }
};

export const StrategyService = {
    getAll: async () => {
        const res = await fetchWithAuth(`${API_URL}/strategies`);
        return handleResponse(res);
    }
};

export const BacktestService = {
    run: async (data: any) => {
        const res = await fetchWithAuth(`${API_URL}/backtest/run`, {
            method: "POST",
            body: JSON.stringify(data)
        });
        return handleResponse(res);
    },
    scan: async (data: any) => {
        const res = await fetchWithAuth(`${API_URL}/backtest/scan`, {
            method: "POST",
            body: JSON.stringify(data)
        });
        return handleResponse(res);
    },
    optimizeBacktest: async (data: any) => {
        const res = await fetchWithAuth(`${API_URL}/backtest/optimize`, {
            method: "POST",
            body: JSON.stringify(data)
        });
        return handleResponse(res);
    },
    optimizeBacktestWithProgress: async (sessionId: string, data: any) => {
        const res = await fetchWithAuth(`${API_URL}/backtest/optimize-with-progress/${sessionId}`, {
            method: "POST",
            body: JSON.stringify(data)
        });
        return handleResponse(res);
    },
    save: async (data: any) => {
        const res = await fetchWithAuth(`${API_URL}/backtest/save`, {
            method: "POST",
            body: JSON.stringify(data)
        });
        return handleResponse(res);
    },
    getHistory: async (skip: number = 0, take: number = 50) => {
        const res = await fetchWithAuth(`${API_URL}/backtest/history?skip=${skip}&take=${take}`);
        return handleResponse(res);
    },
    getById: async (id: string) => {
        const res = await fetchWithAuth(`${API_URL}/backtest/${id}`);
        return handleResponse(res);
    },
    toggleFavorite: async (id: string) => {
        const res = await fetchWithAuth(`${API_URL}/backtest/${id}/favorite`, {
            method: "POST"
        });
        return handleResponse(res);
    },
    delete: async (id: string) => {
        const res = await fetchWithAuth(`${API_URL}/backtest/${id}`, {
            method: "DELETE"
        });
        return handleResponse(res);
    },

};

export const ScannerService = {
    scan: async (data: any) => {
        const res = await fetchWithAuth(`${API_URL}/scanner/scan`, {
            method: "POST",
            body: JSON.stringify(data)
        });
        return handleResponse(res);
    },
    getFavorites: async () => {
        const res = await fetchWithAuth(`${API_URL}/scanner/favorites`);
        return handleResponse(res);
    },
    saveFavorite: async (data: any) => {
        const res = await fetchWithAuth(`${API_URL}/scanner/favorites`, {
            method: "POST",
            body: JSON.stringify(data)
        });
        return handleResponse(res);
    },
    deleteFavorite: async (id: string) => {
        const res = await fetchWithAuth(`${API_URL}/scanner/favorites/${id}`, {
            method: "DELETE"
        });
        return handleResponse(res);
    }
};

export const AuthService = {
    changePassword: async (currentPassword: string, newPassword: string) => {
        const res = await fetchWithAuth(`${API_URL}/auth/change-password`, {
            method: "POST",
            body: JSON.stringify({ currentPassword, newPassword })
        });
        return handleResponse(res);
    }
};

export const SettingsService = {
    getKeys: async () => {
        const res = await fetchWithAuth(`${API_URL}/settings/keys`);
        if (res.status === 403 || res.status === 404) return null;
        return handleResponse(res);
    },
    saveKeys: async (apiKey: string, secretKey: string) => {
        const res = await fetchWithAuth(`${API_URL}/settings/keys`, {
            method: "POST",
            body: JSON.stringify({ apiKey, secretKey })
        });
        return handleResponse(res);
    },
    getGeneral: async () => {
        const res = await fetchWithAuth(`${API_URL}/settings/general`);
        if (res.status === 403 || res.status === 404) return null;
        return handleResponse(res);
    },
    saveGeneral: async (data: any) => {
        const res = await fetchWithAuth(`${API_URL}/settings/general`, {
            method: "POST",
            body: JSON.stringify(data)
        });
        return handleResponse(res);
    },
    getAuditLogs: async () => {
        const res = await fetchWithAuth(`${API_URL}/settings/audit-logs`);
        return handleResponse(res);
    }
};

export const UserService = {
    getAll: async () => {
        const res = await fetchWithAuth(`${API_URL}/users`);
        return handleResponse(res);
    },
    create: async (data: any) => {
        const res = await fetchWithAuth(`${API_URL}/users`, {
            method: "POST",
            body: JSON.stringify(data)
        });
        return handleResponse(res);
    },
    delete: async (id: string) => {
        const res = await fetchWithAuth(`${API_URL}/users/${id}`, {
            method: "DELETE"
        });
        return handleResponse(res);
    }
};

export const NotificationService = {
    getUnread: async (page: number = 1, pageSize: number = 20) => {
        const res = await fetchWithAuth(`${API_URL}/notifications?page=${page}&pageSize=${pageSize}`);
        return handleResponse(res);
    },
    markAsRead: async (id: string) => {
        await fetchWithAuth(`${API_URL}/notifications/${id}/read`, {
            method: "PUT"
        });
    },
    markAllAsRead: async () => {
        await fetchWithAuth(`${API_URL}/notifications/read-all`, {
            method: "PUT"
        });
    }
};
