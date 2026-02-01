const BASE_URL = "http://localhost:5112";
export const API_URL = `${BASE_URL}/api`;
export const HUB_URL = `${BASE_URL}/bot-hub`;

const getHeaders = () => {
    const token = typeof window !== 'undefined' ? localStorage.getItem("token") : null;
    return {
        "Content-Type": "application/json",
        ...(token ? { "Authorization": `Bearer ${token}` } : {})
    };
};

export const BotService = {
    getAll: async () => {
        const res = await fetch(`${API_URL}/bots`, { headers: getHeaders() });
        if (res.status === 401) { window.location.href = '/login'; return []; }
        if (!res.ok) throw new Error("Bot verileri alınamadı");
        return res.json();
    },

    start: async (data: any) => {
        // Backend "POST /bots/start" bekliyor
        const res = await fetch(`${API_URL}/bots/start`, {
            method: "POST",
            headers: getHeaders(), // Content-Type zaten içinde
            body: JSON.stringify(data),
        });
        // Hata mesajını backend'den oku
        if (!res.ok) {
            const errorText = await res.text();
            throw new Error(errorText || "Bot başlatılamadı");
        }
        return res.json();
    },

    stop: async (id: string) => {
        const res = await fetch(`${API_URL}/bots/${id}/stop`, { method: "POST", headers: getHeaders() });
        if (!res.ok) throw new Error("Bot durdurulamadı");
        return res.json();
    }
};

export const MarketService = {
    getStrategies: async () => {
        const res = await fetch(`${API_URL}/Strategies`, { headers: getHeaders() });
        if (!res.ok) return [];
        return res.json();
    },

    getCoins: async () => {
        const res = await fetch(`${API_URL}/Stocks`, { headers: getHeaders() });
        if (!res.ok) return [];
        return res.json();
    },

    getStats: async () => {
        const res = await fetch(`${API_URL}/SummaryStats`, { headers: getHeaders() });
        if (!res.ok) return null;
        return res.json();
    }
};

export const WalletService = {
    get: async () => {
        const res = await fetch(`${API_URL}/wallet`, { headers: getHeaders() });
        if (!res.ok) return null;
        return res.json();
    },

    getTransactions: async () => {
        const res = await fetch(`${API_URL}/wallet/transactions`, { headers: getHeaders() });
        if (!res.ok) return [];
        return res.json();
    }
};

export const AnalyticsService = {
    getStats: async () => {
        const res = await fetch(`${API_URL}/analytics/stats`, { headers: getHeaders() });
        if (!res.ok) return null;
        return res.json();
    },
    getEquityCurve: async () => {
        const res = await fetch(`${API_URL}/analytics/equity`, { headers: getHeaders() });
        if (!res.ok) return [];
        return res.json();
    },
    getStrategyPerformance: async () => {
        const res = await fetch(`${API_URL}/analytics/performance`, { headers: getHeaders() });
        if (!res.ok) return [];
        return res.json();
    }
}

export const SettingsService = {
    getKeys: async () => {
        const res = await fetch(`${API_URL}/settings/keys`, { headers: getHeaders() });
        if (!res.ok) return null;
        return res.json();
    },
    saveKeys: async (apiKey: string, secretKey: string) => {
        const res = await fetch(`${API_URL}/settings/keys`, {
            method: "POST",
            headers: getHeaders(),
            body: JSON.stringify({ apiKey, secretKey })
        });
        if (!res.ok) throw new Error("Kayıt başarısız");
        return res.json();
    }
};

export const UserService = {
    getAll: async () => {
        const res = await fetch(`${API_URL}/users`, { headers: getHeaders() });
        if (!res.ok) return [];
        return res.json();
    },
    create: async (data: any) => {
        const res = await fetch(`${API_URL}/users`, {
            method: "POST",
            headers: { ...getHeaders(), "Content-Type": "application/json" },
            body: JSON.stringify(data)
        });
        if (!res.ok) {
            const json = await res.json();
            throw new Error(json.message || "Kullanıcı oluşturulurken hata oluştu");
        }
        return res.json();
    }
};

export const LogService = {
    getAll: async (limit = 100, level?: string) => {
        let url = `${API_URL}/logs?limit=${limit}`;
        if (level && level !== 'All') url += `&level=${level}`;

        const res = await fetch(url, { headers: getHeaders() });
        if (!res.ok) return [];
        return res.json();
    },
    clear: async () => {
        const res = await fetch(`${API_URL}/logs`, {
            method: "DELETE",
            headers: getHeaders()
        });
        if (!res.ok) throw new Error("Loglar temizlenemedi");
        return res.json();
    }
};

export const BacktestService = {
    runBacktest: async (params: any) => {
        const res = await fetch(`${API_URL}/backtest/run`, {
            method: "POST",
            headers: getHeaders(),
            body: JSON.stringify(params)
        });
        if (!res.ok) {
            let errorMessage = "Backtest başlatılamadı";
            try {
                const errorData = await res.json();
                errorMessage = errorData.message || errorData.title || JSON.stringify(errorData);
            } catch {
                errorMessage = await res.text();
            }
            throw new Error(errorMessage);
        }
        return res.json();
    }
};
