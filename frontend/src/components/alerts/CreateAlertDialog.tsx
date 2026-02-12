import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Bell, Loader2 } from 'lucide-react';
import { AlertType, AlertCondition } from '@/types/alert';
import { useAlerts } from '@/hooks/useAlerts';
import { toast } from 'sonner';

interface CreateAlertDialogProps {
    isOpen: boolean;
    onClose: () => void;
}

export default function CreateAlertDialog({ isOpen, onClose }: CreateAlertDialogProps) {
    const { createAlert, loading } = useAlerts();
    const [symbol, setSymbol] = useState('');
    const [targetValue, setTargetValue] = useState('');
    const [condition, setCondition] = useState(AlertCondition.Above);
    const [isSubmitting, setIsSubmitting] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!symbol || !targetValue) return;

        setIsSubmitting(true);
        try {
            await createAlert({
                symbol: symbol.toUpperCase(),
                targetValue: parseFloat(targetValue),
                condition,
                type: AlertType.Price
            });
            toast.success('Alarm başarıyla oluşturuldu');
            onClose();
            // Reset form
            setSymbol('');
            setTargetValue('');
            setCondition(AlertCondition.Above);
        } catch (error) {
            toast.error('Alarm oluşturulamadı');
        } finally {
            setIsSubmitting(false);
        }
    };

    if (!isOpen) return null;

    return (
        <AnimatePresence>
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
                <motion.div
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0, scale: 0.95 }}
                    className="bg-slate-900 border border-white/10 rounded-2xl w-full max-w-md shadow-2xl overflow-hidden relative"
                >
                    {/* Header */}
                    <div className="flex items-center justify-between p-6 border-b border-white/5 bg-slate-800/30">
                        <h3 className="text-xl font-bold text-white flex items-center gap-2">
                            <Bell className="text-primary" />
                            Yeni Fiyat Alarmı
                        </h3>
                        <button
                            onClick={onClose}
                            className="text-slate-400 hover:text-white transition-colors p-1 rounded-lg hover:bg-white/5"
                        >
                            <X size={20} />
                        </button>
                    </div>

                    <form onSubmit={handleSubmit} className="p-6 space-y-5">
                        {/* Symbol Input */}
                        <div>
                            <label className="text-slate-400 text-sm font-medium mb-1.5 block">
                                Sembol
                            </label>
                            <input
                                type="text"
                                value={symbol}
                                onChange={(e) => setSymbol(e.target.value)}
                                placeholder="Örn: BTCUSDT"
                                className="w-full bg-slate-950 border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary/50 focus:ring-1 focus:ring-primary/50 transition-all placeholder:text-slate-600 uppercase font-mono"
                                required
                            />
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            {/* Condition */}
                            <div>
                                <label className="text-slate-400 text-sm font-medium mb-1.5 block">
                                    Koşul
                                </label>
                                <select
                                    value={condition}
                                    onChange={(e) => setCondition(e.target.value as AlertCondition)}
                                    className="w-full bg-slate-950 border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary/50 transition-all appearance-none"
                                >
                                    <option value={AlertCondition.Above}>Yükselirse (&gt;)</option>
                                    <option value={AlertCondition.Below}>Düşerse (&lt;)</option>
                                </select>
                            </div>

                            {/* Price */}
                            <div>
                                <label className="text-slate-400 text-sm font-medium mb-1.5 block">
                                    Hedef Fiyat ($)
                                </label>
                                <input
                                    type="number"
                                    step="0.00000001"
                                    value={targetValue}
                                    onChange={(e) => setTargetValue(e.target.value)}
                                    placeholder="0.00"
                                    className="w-full bg-slate-950 border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary/50 transition-all font-mono"
                                    required
                                />
                            </div>
                        </div>

                        {/* Actions */}
                        <div className="flex gap-3 pt-2">
                            <button
                                type="button"
                                onClick={onClose}
                                className="flex-1 py-3.5 rounded-xl bg-slate-800 text-slate-300 hover:bg-slate-700 font-bold transition-colors text-sm"
                            >
                                İptal
                            </button>
                            <button
                                type="submit"
                                disabled={isSubmitting || !symbol || !targetValue}
                                className="flex-1 py-3.5 rounded-xl bg-primary text-slate-900 hover:bg-amber-400 font-bold transition-all shadow-lg shadow-primary/20 hover:shadow-primary/30 active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                            >
                                {isSubmitting ? (
                                    <>
                                        <Loader2 className="animate-spin" size={18} />
                                        Oluşturuluyor...
                                    </>
                                ) : (
                                    'Alarm Oluştur'
                                )}
                            </button>
                        </div>
                    </form>
                </motion.div>
            </div>
        </AnimatePresence>
    );
}
