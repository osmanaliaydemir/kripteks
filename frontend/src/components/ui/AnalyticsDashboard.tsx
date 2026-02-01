"use client";

import { useEffect, useState } from "react";
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, Legend } from 'recharts';
import { AnalyticsService } from "@/lib/api";
import { TrendingUp, BarChart2 } from "lucide-react";

export default function AnalyticsDashboard() {
    interface AnalyticsStats {
        totalPnl: number;
        winRate: number;
        totalTrades: number;
        bestPair: string;
    }

    const [stats, setStats] = useState<AnalyticsStats | null>(null);
    const [equityData, setEquityData] = useState<{ date: string; balance: number }[]>([]);
    const [performanceData, setPerformanceData] = useState<{ strategyName: string; totalPnl: number; winRate: number }[]>([]);
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
        return <div className="flex items-center justify-center h-64 text-slate-500">Analiz verileri yükleniyor...</div>;
    }

    return (
        <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <StatCard title="Toplam Kar/Zarar" value={stats?.totalPnl} isCurrency />
                <StatCard title="Kazanma Oranı" value={stats?.winRate} isPercent />
                <StatCard title="Toplam İşlem" value={stats?.totalTrades} />
                <StatCard title="En İyi Parite" value={stats?.bestPair} />
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Equity Curve */}
                <div className="glass-card p-6">
                    <h3 className="text-white font-display font-bold mb-6 flex items-center gap-3">
                        <div className="p-2 bg-primary/10 rounded-lg text-primary">
                            <TrendingUp size={20} />
                        </div>
                        Bakiye Büyümesi
                    </h3>
                    <div className="h-72">
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={equityData}>
                                <defs>
                                    <linearGradient id="colorBalance" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#F59E0B" stopOpacity={0.3} />
                                        <stop offset="95%" stopColor="#F59E0B" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                                <XAxis dataKey="date" stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} dy={10} />
                                <YAxis stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} tickFormatter={(value) => `$${value}`} />
                                <Tooltip
                                    cursor={{ stroke: '#F59E0B', strokeWidth: 1, strokeDasharray: '4 4' }}
                                    contentStyle={{ backgroundColor: '#020617', borderColor: 'rgba(255,255,255,0.1)', color: '#f8fafc', borderRadius: '12px' }}
                                    itemStyle={{ color: '#F59E0B' }}
                                    formatter={(value: number | undefined) => [value !== undefined ? `$${value.toFixed(2)}` : '-', "Bakiye"]}
                                />
                                <Area type="monotone" dataKey="balance" stroke="#F59E0B" strokeWidth={2} fillOpacity={1} fill="url(#colorBalance)" />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* Strategy Performance */}
                <div className="glass-card p-6">
                    <h3 className="text-white font-display font-bold mb-6 flex items-center gap-3">
                        <div className="p-2 bg-secondary/10 rounded-lg text-secondary">
                            <BarChart2 size={20} />
                        </div>
                        Strateji Performansı
                    </h3>
                    <div className="h-72">
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={performanceData}>
                                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                                <XAxis dataKey="strategyName" stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} dy={10} />
                                <YAxis stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} />
                                <Tooltip
                                    cursor={{ fill: 'rgba(255,255,255,0.05)' }}
                                    contentStyle={{ backgroundColor: '#020617', borderColor: 'rgba(255,255,255,0.1)', color: '#f8fafc', borderRadius: '12px' }}
                                />
                                <Legend wrapperStyle={{ paddingTop: '20px' }} />
                                <Bar dataKey="totalPnl" name="Toplam PnL ($)" fill="#10b981" radius={[4, 4, 4, 4]} barSize={30} />
                                <Bar dataKey="winRate" name="Kazanma Oranı (%)" fill="#8B5CF6" radius={[4, 4, 4, 4]} barSize={30} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </div>
            </div>
        </div>
    );
}

interface StatCardProps {
    title: string;
    value: string | number | undefined | null;
    isCurrency?: boolean;
    isPercent?: boolean;
}

function StatCard({ title, value, isCurrency = false, isPercent = false }: StatCardProps) {
    let displayValue = value;
    let colorClass = "text-white";

    if (value === undefined || value === null) {
        displayValue = "-";
        colorClass = "text-slate-500";
    } else {
        const numValue = Number(value);
        if (isCurrency) {
            displayValue = (numValue >= 0 ? '+' : '') + `$${numValue.toFixed(2)}`;
            colorClass = numValue >= 0 ? "text-emerald-400" : "text-rose-400";
        } else if (isPercent) {
            displayValue = `%${numValue.toFixed(1)}`;
            colorClass = numValue >= 50 ? "text-emerald-400" : "text-amber-400";
        }
    }

    return (
        <div className="glass-card p-5 flex flex-col justify-center relative overflow-hidden group hover:border-white/10 transition-colors">
            <span className="text-slate-400 text-xs font-bold uppercase tracking-widest mb-2 z-10">{title}</span>
            <span className={`text-2xl font-display font-bold ${colorClass} z-10`}>{displayValue}</span>
            <div className="absolute top-0 right-0 w-24 h-24 bg-white/5 rounded-full blur-2xl -mr-10 -mt-10 pointer-events-none group-hover:bg-white/10 transition-colors"></div>
        </div>
    );
}
