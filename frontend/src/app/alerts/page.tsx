"use client";

import { useEffect, useState } from 'react';
import { useAlerts } from '@/hooks/useAlerts';
import AlertList from '@/components/alerts/AlertList';
import CreateAlertDialog from '@/components/alerts/CreateAlertDialog';
import { motion, AnimatePresence } from 'framer-motion';
import { Bell, Plus, Loader2 } from 'lucide-react';
import Navbar from '@/components/ui/Navbar';
import { useAuth } from '../../context/AuthContext';
import { toast } from 'sonner';

export default function AlertsPage() {
    const { user } = useAuth();
    const { alerts, loading, deleteAlert, refresh } = useAlerts();
    const [isCreateOpen, setIsCreateOpen] = useState(false);
    const [deletingId, setDeletingId] = useState<string | null>(null);

    useEffect(() => {
        // Initial fetch handled by hook
    }, []);

    const handleDelete = async (id: string) => {
        if (confirm('Bu alarmı silmek istediğinize emin misiniz?')) {
            setDeletingId(id);
            try {
                await deleteAlert(id);
                toast.success('Alarm silindi');
            } catch (error) {
                toast.error('Alarm silinemedi');
            } finally {
                setDeletingId(null);
            }
        }
    };

    return (
        <main className="min-h-screen bg-slate-950 pb-20">
            <Navbar user={user} />

            <div className="max-w-4xl mx-auto px-4 py-8">
                {/* Header Section */}
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
                    <div>
                        <h1 className="text-3xl font-bold text-white mb-2 flex items-center gap-3">
                            <div className="p-2 bg-linear-to-br from-primary/20 to-amber-500/20 rounded-xl border border-white/5">
                                <Bell className="text-primary w-8 h-8" />
                            </div>
                            Fiyat Alarmları
                        </h1>
                        <p className="text-slate-400 max-w-xl">
                            Piyasa hareketlerini kaçırmamak için kritik seviyelere alarm kurun,
                            fiyat hedefinize ulaştığında anında bildirim alın.
                        </p>
                    </div>

                    <button
                        onClick={() => setIsCreateOpen(true)}
                        className="flex items-center gap-2 px-6 py-3 bg-primary text-slate-900 font-bold rounded-xl hover:bg-amber-400 transition-all shadow-lg shadow-primary/20 active:scale-95 group"
                    >
                        <Plus className="w-5 h-5 group-hover:rotate-90 transition-transform" />
                        Yeni Alarm Ekle
                    </button>
                </div>

                {/* Stats Grid */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
                    <div className="glass-card p-4 flex items-center gap-4 bg-slate-900/40">
                        <div className="w-12 h-12 rounded-xl bg-emerald-500/10 flex items-center justify-center text-emerald-500">
                            <Bell size={24} />
                        </div>
                        <div>
                            <p className="text-xs text-slate-500 font-bold uppercase tracking-wider">Aktif Alarmlar</p>
                            <h3 className="text-2xl font-bold text-white">{alerts.filter(a => a.isEnabled).length}</h3>
                        </div>
                    </div>

                    <div className="glass-card p-4 flex items-center gap-4 bg-slate-900/40">
                        <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center text-primary">
                            <Loader2 size={24} />
                        </div>
                        <div>
                            <p className="text-xs text-slate-500 font-bold uppercase tracking-wider">Toplam</p>
                            <h3 className="text-2xl font-bold text-white">{alerts.length}</h3>
                        </div>
                    </div>
                </div>

                {/* Alerts List */}
                <div className="bg-slate-900/50 border border-white/5 rounded-2xl p-6 min-h-[400px]">
                    <div className="flex items-center justify-between mb-6">
                        <h2 className="text-lg font-bold text-white">Alarm Listesi</h2>
                        <button
                            onClick={refresh}
                            className="text-xs font-bold text-primary hover:text-amber-400 transition-colors uppercase tracking-wider"
                        >
                            Yenile
                        </button>
                    </div>

                    <AlertList
                        alerts={alerts}
                        loading={loading}
                        onDelete={handleDelete}
                    />
                </div>
            </div>

            <CreateAlertDialog
                isOpen={isCreateOpen}
                onClose={() => setIsCreateOpen(false)}
            />
        </main>
    );
}
