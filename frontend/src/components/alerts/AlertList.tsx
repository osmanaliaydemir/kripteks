import { motion } from 'framer-motion';
import { AlertCircle, Trash2, Bell, CheckCircle, TrendingUp, TrendingDown } from 'lucide-react';
import { Alert, AlertType, AlertCondition } from '@/types/alert';
import LoadingSkeleton from '../ui/LoadingSkeleton';

interface AlertListProps {
    alerts: Alert[];
    loading: boolean;
    onDelete: (id: string) => void;
}

export default function AlertList({ alerts, loading, onDelete }: AlertListProps) {
    if (loading) {
        return <LoadingSkeleton className="h-24 w-full" count={3} />;
    }

    if (alerts.length === 0) {
        return (
            <div className="flex flex-col items-center justify-center py-12 text-slate-500 bg-slate-900/30 rounded-2xl border border-white/5">
                <div className="w-16 h-16 bg-slate-800/50 rounded-full flex items-center justify-center mb-4">
                    <Bell className="w-8 h-8 text-slate-600" />
                </div>
                <h3 className="text-lg font-bold text-white mb-1">Alarm Bulunamadı</h3>
                <p className="text-sm">Henüz bir fiyat alarmı oluşturmadınız.</p>
            </div>
        );
    }

    const getConditionIcon = (condition: AlertCondition) => {
        switch (condition) {
            case AlertCondition.Above:
            case AlertCondition.CrossOver:
                return <TrendingUp className="text-emerald-500" size={20} />;
            case AlertCondition.Below:
            case AlertCondition.CrossUnder:
                return <TrendingDown className="text-rose-500" size={20} />;
            default:
                return <AlertCircle className="text-primary" size={20} />;
        }
    };

    const getConditionText = (condition: AlertCondition) => {
        switch (condition) {
            case AlertCondition.Above: return 'Yükselirse (>)';
            case AlertCondition.Below: return 'Düşerse (<)';
            case AlertCondition.CrossOver: return 'Yukarı Keserse';
            case AlertCondition.CrossUnder: return 'Aşağı Keserse';
        }
    };

    return (
        <div className="space-y-3">
            {alerts.map((alert) => (
                <motion.div
                    key={alert.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.95 }}
                    className="glass-card p-4 flex items-center justify-between group hover:border-primary/30 transition-all"
                >
                    <div className="flex items-center gap-4">
                        <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${alert.condition === AlertCondition.Above || alert.condition === AlertCondition.CrossOver
                                ? 'bg-emerald-500/10'
                                : 'bg-rose-500/10'
                            }`}>
                            {getConditionIcon(alert.condition)}
                        </div>

                        <div>
                            <div className="flex items-center gap-2">
                                <h4 className="font-bold text-white">{alert.symbol}</h4>
                                <span className="text-xs px-2 py-0.5 rounded-full bg-slate-800 text-slate-400 border border-white/5">
                                    {getConditionText(alert.condition)}
                                </span>
                            </div>
                            <div className="flex items-center gap-2 mt-1">
                                <span className="text-2xl font-mono font-bold text-primary tracking-tight">
                                    ${alert.targetValue.toLocaleString()}
                                </span>
                            </div>
                        </div>
                    </div>

                    <div className="flex items-center gap-4">
                        {alert.lastTriggeredAt && (
                            <div className="flex flex-col items-end text-right mr-2">
                                <div className="flex items-center gap-1 text-emerald-400 text-xs font-bold">
                                    <CheckCircle size={12} />
                                    Tetiklendi
                                </div>
                                <span className="text-[10px] text-slate-500">
                                    {new Date(alert.lastTriggeredAt).toLocaleTimeString()}
                                </span>
                            </div>
                        )}

                        <button
                            onClick={() => onDelete(alert.id)}
                            className="p-2 text-slate-500 hover:text-rose-500 hover:bg-rose-500/10 rounded-lg transition-colors"
                            title="Alarmı Sil"
                        >
                            <Trash2 size={18} />
                        </button>
                    </div>
                </motion.div>
            ))}
        </div>
    );
}
