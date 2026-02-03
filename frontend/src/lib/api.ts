const BASE_URL = "http://localhost:5292";
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

    return res;
};

export const BotService = {
    getAll: async () => {
        const res = await fetchWithAuth(`${API_URL}/bots`);
        return res.json();
    },
    getById: async (id: string) => {
        const res = await fetchWithAuth(`${API_URL}/bots/${id}`);
        return res.json();
    },
    create: async (bot: any) => {
        const res = await fetchWithAuth(`${API_URL}/bots/start`, {
            method: "POST",
            body: JSON.stringify(bot)
        });
        return res.json();
    },
    update: async (id: string, bot: any) => {
        const res = await fetchWithAuth(`${API_URL}/bots/${id}`, {
            method: "PUT",
            body: JSON.stringify(bot)
        });
        return res.json();
    },
    delete: async (id: string) => {
        const res = await fetchWithAuth(`${API_URL}/bots/${id}`, {
            method: "DELETE"
        });
        return res.json();
    },
    start: async (id: string) => {
        const res = await fetchWithAuth(`${API_URL}/bots/${id}/start`, {
            method: "POST"
        });
        return res.json();
    },
    stop: async (id: string) => {
        const res = await fetchWithAuth(`${API_URL}/bots/${id}/stop`, {
            method: "POST"
        });
        return res.json();
    }
};

export const MarketService = {
    getMarkets: async () => {
        const res = await fetchWithAuth(`${API_URL}/stocks`);
        return res.json();
    },
    getCoins: async () => {
        const res = await fetchWithAuth(`${API_URL}/stocks`);
        return res.json();
    },
    getStrategies: async () => {
        const res = await fetchWithAuth(`${API_URL}/strategies`);
        return res.json();
    },
    getStats: async () => {
        const res = await fetchWithAuth(`${API_URL}/analytics/stats`);
        return res.json();
    }
};

export const WalletService = {
    getWallet: async () => {
        const res = await fetchWithAuth(`${API_URL}/wallet`);
        return res.json();
    },
    get: async () => {
        const res = await fetchWithAuth(`${API_URL}/wallet`);
        return res.json();
    },
    getTransactions: async () => {
        const res = await fetchWithAuth(`${API_URL}/wallet/transactions`);
        return res.json();
    }
};

export const AnalyticsService = {
    getStats: async () => {
        const res = await fetchWithAuth(`${API_URL}/analytics/stats`);
        return res.json();
    },
    getChartData: async () => {
        const res = await fetchWithAuth(`${API_URL}/analytics/chart`);
        return res.json();
    },
    getEquityCurve: async () => {
        const res = await fetchWithAuth(`${API_URL}/analytics/equity`);
        return res.json();
    },
    getStrategyPerformance: async () => {
        const res = await fetchWithAuth(`${API_URL}/analytics/performance`);
        return res.json();
    }
};

export const LogService = {
    getLogs: async (limit: number = 50) => {
        const res = await fetchWithAuth(`${API_URL}/logs?limit=${limit}`);
        return res.json();
    }
};

export const StrategyService = {
    getAll: async () => {
        const res = await fetchWithAuth(`${API_URL}/strategies`);
        return res.json();
    }
};

export const BacktestService = {
    run: async (data: any) => {
        const res = await fetchWithAuth(`${API_URL}/backtest`, {
            method: "POST",
            body: JSON.stringify(data)
        });
        return res.json();
    }
};

export const AuthService = {
    changePassword: async (currentPassword: string, newPassword: string) => {
        const res = await fetchWithAuth(`${API_URL}/auth/change-password`, {
            method: "POST",
            body: JSON.stringify({ currentPassword, newPassword })
        });
        if (!res.ok) {
            const json = await res.json();
            throw new Error(json.message || "Şifre değiştirilemedi");
        }
        return res.json();
    }
};

export const SettingsService = {
    getKeys: async () => {
        const res = await fetchWithAuth(`${API_URL}/settings/keys`);
        if (!res.ok) return null;
        return res.json();
    },
    saveKeys: async (apiKey: string, secretKey: string) => {
        const res = await fetchWithAuth(`${API_URL}/settings/keys`, {
            method: "POST",
            body: JSON.stringify({ apiKey, secretKey })
        });
        if (!res.ok) throw new Error("Kayıt başarısız");
        return res.json();
    },
    getGeneral: async () => {
        const res = await fetchWithAuth(`${API_URL}/settings/general`);
        if (!res.ok) return null;
        return res.json();
    },
    saveGeneral: async (data: any) => {
        const res = await fetchWithAuth(`${API_URL}/settings/general`, {
            method: "POST",
            body: JSON.stringify(data)
        });
        if (!res.ok) throw new Error("Ayarlar kaydedilemedi");
        return res.json();
    }
};

export const UserService = {
    getAll: async () => {
        const res = await fetchWithAuth(`${API_URL}/users`);
        return res.json();
    },
    create: async (data: any) => {
        const res = await fetchWithAuth(`${API_URL}/users`, {
            method: "POST",
            body: JSON.stringify(data)
        });
        if (!res.ok) {
            const json = await res.json();
            throw new Error(json.message || "Kullanıcı eklenemedi");
        }
        return res.json();
    },
    delete: async (id: string) => {
        const res = await fetchWithAuth(`${API_URL}/users/${id}`, {
            method: "DELETE"
        });
        if (!res.ok) {
            const json = await res.json();
            throw new Error(json.message || "Kullanıcı silinemedi");
        }
        return res.json();
    }
};

export const NotificationService = {
    getUnread: async () => {
        const res = await fetchWithAuth(`${API_URL}/notifications`);
        return res.json();
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
