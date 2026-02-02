import { useEffect, useState } from "react";
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, Legend, Cell } from 'recharts';
import { AnalyticsService } from "@/lib/api";
import { TrendingUp, BarChart2, Target, Zap, ShieldAlert, Award, PieChart, Activity, Info } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

function InfoTooltip({ text }: { text: string }) {
    const [isVisible, setIsVisible] = useState(false);
    return (
        <div className="relative inline-block ml-1 align-middle" onMouseEnter={() => setIsVisible(true)} onMouseLeave={() => setIsVisible(false)}>
            <div className="p-0.5 rounded-full hover:bg-white/10 transition-colors cursor-help text-slate-500 hover:text-slate-300">
                <Info size={12} />
            </div>
            <AnimatePresence>
                {isVisible && (
                    <motion.div
                        initial={{ opacity: 0, scale: 0.9, y: 5 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.9, y: 5 }}
                        className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-56 p-3 bg-slate-900/95 backdrop-blur-md border border-white/10 rounded-xl shadow-2xl z-50 pointer-events-none"
                    >
                        <p className="text-[10px] leading-relaxed text-slate-300 font-semibold text-center">{text}</p>
                        <div className="absolute top-full left-1/2 -translate-x-1/2 border-[6px] border-transparent border-t-slate-900/95"></div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
}

export default function AnalyticsDashboard() {
    interface AnalyticsStats {
        totalPnl: number;
        winRate: number;
        totalTrades: number;
        winningTrades: number;
        losingTrades: number;
        bestPair: string;
        profitFactor: number;
        avgTradePnL: number;
        maxDrawdown: number;
    }

    const [stats, setStats] = useState<AnalyticsStats | null>(null);
    const [equityData, setEquityData] = useState<{ date: string; balance: number; dailyPnl: number }[]>([]);
    const [performanceData, setPerformanceData] = useState<{ strategyName: string; totalPnl: number; winRate: number; profitFactor: number; avgTrade: number }[]>([]);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        const fetchData = async () => {
            setIsLoading(true);
            try {
                const [statsData, equity, performance] = await Promise.all([
                    AnalyticsService.getStats(),
                    AnalyticsService.getEquityCurve(),
                    AnalyticsService.getStrategyPerformance()
                ]);
                setStats(statsData);
                setEquityData(equity);
                setPerformanceData(performance);
            } catch (e) {
                console.error(e);
            } finally {
                setIsLoading(false);
            }
        };

        fetchData();
    }, []);

    if (isLoading) {
        return (
            <div className="flex flex-col items-center justify-center h-96 gap-4">
                <div className="w-12 h-12 border-4 border-primary/20 border-t-primary rounded-full animate-spin"></div>
                <p className="text-slate-500 font-medium animate-pulse">Analiz verileri derleniyor...</p>
            </div>
        );
    }

    return (
        <div className="space-y-8 pb-8">
            {/* --- HEADER STATS --- */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
                <StatCard
                    title="Net Kar/Zarar"
                    value={stats?.totalPnl}
                    isCurrency
                    subValue={`${stats?.totalTrades} İşlem`}
                    icon={<Award size={18} />}
                    color="primary"
                    sparkData={equityData.map(p => ({ value: p.balance }))}
                    tooltip="Tüm canlı işlemlerden elde edilen toplam net getiri (Dolar bazında)."
                />
                <StatCard
                    title="Win Rate"
                    value={stats?.winRate}
                    isPercent
                    subValue={`${stats?.winningTrades} Galibiyet / ${stats?.losingTrades} Mağlubiyet`}
                    icon={<Target size={18} />}
                    color="emerald"
                    tooltip="Kârlı biten işlemlerin toplam işlem sayısına oranı."
                />
                <StatCard
                    title="Profit Factor"
                    value={stats?.profitFactor}
                    decimal={2}
                    subValue="Brüt Kar / Brüt Zarar"
                    icon={<Zap size={18} />}
                    color="amber"
                    tooltip="Toplam brüt kârın, toplam brüt zarara oranı. 1.0 üzeri kârlı bir sistem demektir."
                />
                <StatCard
                    title="Max Drawdown"
                    value={stats?.maxDrawdown}
                    isPercent
                    subValue="En Büyük Sermaye Kaybı"
                    icon={<ShieldAlert size={18} />}
                    color="rose"
                    tooltip="Sermayenizin süreç içinde gördüğü en büyük değer kaybı oranı."
                />
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* --- EQUITY CURVE (2/3 width on LG) --- */}
                <div className="lg:col-span-2 glass-card p-6 border border-white/5 relative group hover:z-50">
                    <div className="absolute top-0 right-0 w-64 h-64 bg-primary/5 rounded-full blur-3xl -mr-32 -mt-32 pointer-events-none"></div>

                    <div className="flex items-center justify-between mb-8">
                        <div className="flex items-center gap-3">
                            <div className="p-2.5 bg-primary/10 rounded-xl text-primary shadow-lg shadow-primary/5">
                                <TrendingUp size={22} />
                            </div>
                            <div>
                                <div className="flex items-center gap-1">
                                    <h3 className="text-lg font-display font-bold text-white">Sermaye Büyümesi</h3>
                                    <InfoTooltip text="Zaman içindeki toplam bakiye değişimini gösteren kümülatif PnL eğrisi." />
                                </div>
                                <p className="text-xs text-slate-500">Kümülatif PnL Eğrisi (Son 30 Gün)</p>
                            </div>
                        </div>
                        <div className="flex gap-2">
                            <div className={`px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase tracking-wider ${(stats?.totalPnl || 0) >= 0 ? 'bg-emerald-500/10 text-emerald-400' : 'bg-rose-500/10 text-rose-400'}`}>
                                Trend: {(stats?.totalPnl || 0) >= 0 ? 'Pozitif' : 'Negatif'}
                            </div>
                        </div>
                    </div>

                    <div className="h-80 w-full">
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={equityData}>
                                <defs>
                                    <linearGradient id="colorBalance" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#F59E0B" stopOpacity={0.4} />
                                        <stop offset="95%" stopColor="#F59E0B" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.03)" vertical={false} />
                                <XAxis
                                    dataKey="date"
                                    stroke="#475569"
                                    fontSize={10}
                                    tickLine={false}
                                    axisLine={false}
                                    dy={10}
                                    minTickGap={30}
                                />
                                <YAxis
                                    stroke="#475569"
                                    fontSize={10}
                                    tickLine={false}
                                    axisLine={false}
                                    tickFormatter={(value) => `$${value}`}
                                />
                                <Tooltip
                                    cursor={{ stroke: '#F59E0B', strokeWidth: 1.5, strokeDasharray: '5 5' }}
                                    contentStyle={{
                                        backgroundColor: '#0f172a',
                                        borderColor: 'rgba(255,255,255,0.1)',
                                        color: '#f8fafc',
                                        borderRadius: '16px',
                                        boxShadow: '0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)'
                                    }}
                                    itemStyle={{ color: '#F59E0B', fontWeight: 'bold' }}
                                    formatter={(value: any) => [`$${Number(value || 0).toFixed(2)}`, "Toplam Kar"]}
                                />
                                <Area
                                    type="monotone"
                                    dataKey="balance"
                                    stroke="#F59E0B"
                                    strokeWidth={3}
                                    fillOpacity={1}
                                    fill="url(#colorBalance)"
                                    animationDuration={2000}
                                />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* --- SIDE STATS & PERFORMANCE --- */}
                <div className="space-y-6">
                    {/* Strategy Performance Mini List */}
                    <div className="glass-card p-6 border border-white/5 h-full relative group hover:z-50">
                        <div className="flex items-center gap-3 mb-6">
                            <div className="p-2.5 bg-secondary/10 rounded-xl text-secondary">
                                <Activity size={20} />
                            </div>
                            <div className="flex items-center gap-1">
                                <h3 className="text-lg font-display font-bold text-white">Strateji Analizi</h3>
                                <InfoTooltip text="Kullanılan stratejilerin bireysel performans verileri ve başarı oranları." />
                            </div>
                        </div>

                        <div className="space-y-4">
                            {performanceData.length === 0 ? (
                                <div className="text-center py-12 text-slate-500 text-sm">Veri bulunamadı</div>
                            ) : performanceData.map((perf, i) => (
                                <motion.div
                                    key={perf.strategyName}
                                    initial={{ opacity: 0, x: 20 }}
                                    animate={{ opacity: 1, x: 0 }}
                                    transition={{ delay: i * 0.1 }}
                                    className="p-4 rounded-xl bg-slate-950/40 border border-white/5 group hover:border-primary/20 transition-all space-y-3"
                                >
                                    <div className="flex justify-between items-center">
                                        <span className="text-[10px] font-bold text-slate-300 group-hover:text-primary transition-colors tracking-tight">{perf.strategyName.replace('strategy-', '').toUpperCase()}</span>
                                        <span className={`text-[11px] font-mono font-bold ${perf.totalPnl >= 0 ? "text-emerald-400" : "text-rose-400"}`}>
                                            {perf.totalPnl >= 0 ? '+' : ''}${perf.totalPnl.toFixed(2)}
                                        </span>
                                    </div>
                                    <div className="space-y-1.5">
                                        <div className="w-full h-1 bg-slate-900 rounded-full overflow-hidden">
                                            <motion.div
                                                initial={{ width: 0 }}
                                                animate={{ width: `${perf.winRate}%` }}
                                                className={`h-full ${perf.winRate > 50 ? 'bg-emerald-500' : 'bg-amber-500'}`}
                                            />
                                        </div>
                                        <div className="flex justify-between text-[9px] text-slate-500 font-bold uppercase tracking-tighter">
                                            <span>Win Rate: %{perf.winRate.toFixed(1)}</span>
                                            <span>Avg: ${perf.avgTrade.toFixed(2)}</span>
                                        </div>
                                    </div>
                                </motion.div>
                            ))}
                        </div>

                        {stats?.bestPair && (
                            <div className="mt-8 pt-6 border-t border-white/5">
                                <div className="flex items-center justify-between">
                                    <div className="text-xs text-slate-400 font-bold uppercase tracking-wider">Favori Parite</div>
                                    <div className="px-3 py-1 bg-primary/10 rounded text-primary text-xs font-bold font-mono">{stats.bestPair}</div>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* --- MULTI PERFORMANCE CHART --- */}
            <div className="glass-card p-6 border border-white/5 relative group hover:z-50">
                <div className="flex items-center gap-3 mb-8">
                    <div className="p-2.5 bg-secondary/10 rounded-xl text-secondary">
                        <BarChart2 size={22} />
                    </div>
                    <div>
                        <div className="flex items-center gap-1">
                            <h3 className="text-lg font-display font-bold text-white">Karşılaştırmalı Performans</h3>
                            <InfoTooltip text="Tüm stratejilerin toplam kâr ve verimlilik (Profit Factor) açısından kıyaslanması." />
                        </div>
                        <p className="text-xs text-slate-500">Strateji Bazlı Kazanç ve Verimlilik</p>
                    </div>
                </div>

                <div className="h-80">
                    <ResponsiveContainer width="100%" height="100%">
                        <BarChart data={performanceData} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
                            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.03)" vertical={false} />
                            <XAxis
                                dataKey="strategyName"
                                stroke="#475569"
                                fontSize={11}
                                tickLine={false}
                                axisLine={false}
                                dy={10}
                                tickFormatter={(val) => val.replace('strategy-', '').toUpperCase()}
                            />
                            <YAxis stroke="#475569" fontSize={11} tickLine={false} axisLine={false} />
                            <Tooltip
                                cursor={{ fill: 'rgba(255,255,255,0.02)' }}
                                contentStyle={{ backgroundColor: '#0f172a', borderColor: 'rgba(255,255,255,0.1)', borderRadius: '12px' }}
                            />
                            <Legend wrapperStyle={{ paddingTop: '20px' }} />
                            <Bar dataKey="totalPnl" name="Toplam Kar ($)" fill="#10b981" radius={[6, 6, 0, 0]} barSize={40}>
                                {performanceData.map((entry, index) => (
                                    <Cell key={`cell-${index}`} fill={entry.totalPnl >= 0 ? '#10b981' : '#f43f5e'} />
                                ))}
                            </Bar>
                            <Bar dataKey="profitFactor" name="Profit Factor" fill="#8B5CF6" radius={[6, 6, 0, 0]} barSize={40} />
                        </BarChart>
                    </ResponsiveContainer>
                </div>
            </div>
        </div>
    );
}

interface StatCardProps {
    title: string;
    value: string | number | undefined | null;
    subValue?: string;
    isCurrency?: boolean;
    isPercent?: boolean;
    decimal?: number;
    icon?: React.ReactNode;
    color?: 'primary' | 'emerald' | 'amber' | 'rose' | 'slate';
    tooltip?: string;
    sparkData?: { value: number }[];
}

function StatCard({ title, value, subValue, isCurrency, isPercent, decimal = 1, icon, color = 'primary', sparkData, tooltip }: StatCardProps) {
    const colorMap = {
        primary: 'text-primary bg-primary/5 border-primary/10',
        emerald: 'text-emerald-400 bg-emerald-500/5 border-emerald-500/10',
        amber: 'text-amber-400 bg-amber-500/5 border-amber-500/10',
        rose: 'text-rose-400 bg-rose-500/5 border-rose-500/10',
        slate: 'text-slate-400 bg-slate-500/5 border-slate-500/10'
    };

    let displayValue: string | number = "-";
    if (value !== undefined && value !== null) {
        const numValue = Number(value);
        if (isCurrency) {
            displayValue = `$${numValue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
        } else if (isPercent) {
            displayValue = `%${numValue.toFixed(decimal)}`;
        } else {
            displayValue = numValue.toFixed(decimal);
        }
    }

    return (
        <motion.div
            whileHover={{ y: -4 }}
            className="glass-card p-6 border border-white/5 relative group h-full hover:z-50"
        >
            <div className="flex justify-between items-start mb-4 relative z-10">
                <div className={`p-2.5 rounded-xl ${colorMap[color].split(' ')[1]} ${colorMap[color].split(' ')[0]}`}>
                    {icon}
                </div>
                {sparkData && (
                    <div className="h-10 w-20">
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={sparkData}>
                                <Area type="monotone" dataKey="value" stroke="currentColor" fill="currentColor" fillOpacity={0.1} strokeWidth={2} />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                )}
            </div>

            <div className="relative z-10">
                <div className="flex items-center gap-1 mb-1">
                    <p className="text-slate-500 text-[10px] font-bold uppercase tracking-widest">{title}</p>
                    {tooltip && <InfoTooltip text={tooltip} />}
                </div>
                <h3 className={`text-2xl font-display font-bold ${colorMap[color].split(' ')[0]}`}>{displayValue}</h3>
                {subValue && <p className="text-[10px] text-slate-500 mt-2 font-medium">{subValue}</p>}
            </div>

            <div className={`absolute bottom-0 right-0 w-24 h-24 rounded-full blur-3xl opacity-5 -mr-12 -mb-12 transition-all group-hover:opacity-10 pointer-events-none ${colorMap[color].split(' ')[1]}`}></div>
        </motion.div>
    );
}
