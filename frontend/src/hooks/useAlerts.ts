import { useState, useEffect, useCallback } from 'react';
import axios from 'axios';
import { Alert, CreateAlertDto } from '@/types/alert';
import { useAuth } from '../context/AuthContext';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'https://api-kripteks.runasp.net/api';

export function useAlerts() {
    const { token, user } = useAuth();
    const [alerts, setAlerts] = useState<Alert[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const fetchAlerts = useCallback(async () => {
        if (!token) return;

        setLoading(true);
        try {
            const response = await axios.get(`${API_URL}/alerts`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setAlerts(response.data);
            setError(null);
        } catch (err) {
            setError('Alarmlar yüklenirken bir hata oluştu');
            console.error(err);
        } finally {
            setLoading(false);
        }
    }, [token]);

    const createAlert = async (data: CreateAlertDto) => {
        if (!token) return;

        try {
            const response = await axios.post(`${API_URL}/alerts`, data, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setAlerts(prev => [response.data, ...prev]);
            return response.data;
        } catch (err) {
            console.error(err);
            throw new Error('Alarm oluşturulamadı');
        }
    };

    const deleteAlert = async (id: string) => {
        if (!token) return;

        try {
            await axios.delete(`${API_URL}/alerts/${id}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setAlerts(prev => prev.filter(a => a.id !== id));
        } catch (err) {
            console.error(err);
            throw new Error('Alarm silinemedi');
        }
    };

    useEffect(() => {
        if (user) {
            fetchAlerts();
        }
    }, [user, fetchAlerts]);

    return {
        alerts,
        loading,
        error,
        createAlert,
        deleteAlert,
        refresh: fetchAlerts
    };
}
