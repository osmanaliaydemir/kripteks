"use client";

import { useEffect, useState } from "react";
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, Legend } from 'recharts';
import { AnalyticsService } from "@/lib/api";
import { TrendingUp, TrendingDown, Crosshair, BarChart2 } from "lucide-react";

export default function AnalyticsDashboard() {
    const [stats, setStats] = useState<any>(null);
    const [equityData, setEquityData] = useState<any[]>([]);
    const [performanceData, setPerformanceData] = useState<any[]>([]);
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
                <div className="bg-slate-800/40 p-6 rounded-3xl border border-slate-700/50">
                    <h3 className="text-white font-bold mb-4 flex items-center gap-2">
                        <TrendingUp size={18} className="text-cyan-400" />
                        Kasa Büyümesi
                    </h3>
                    <div className="h-64">
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={equityData}>
                                <defs>
                                    <linearGradient id="colorBalance" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#8884d8" stopOpacity={0.8} />
                                        <stop offset="95%" stopColor="#8884d8" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                                <XAxis dataKey="date" stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} />
                                <YAxis stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} tickFormatter={(value) => `$${value}`} />
                                <Tooltip
                                    contentStyle={{ backgroundColor: '#1e293b', borderColor: '#334155', color: '#f8fafc' }}
                                    itemStyle={{ color: '#8884d8' }}
                                    formatter={(value: any) => [`$${value.toFixed(2)}`, "Bakiye değişim"]}
                                />
                                <Area type="monotone" dataKey="balance" stroke="#8884d8" fillOpacity={1} fill="url(#colorBalance)" />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* Strategy Performance */}
                <div className="bg-slate-800/40 p-6 rounded-3xl border border-slate-700/50">
                    <h3 className="text-white font-bold mb-4 flex items-center gap-2">
                        <BarChart2 size={18} className="text-purple-400" />
                        Strateji Performansı
                    </h3>
                    <div className="h-64">
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={performanceData}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                                <XAxis dataKey="strategyName" stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} />
                                <YAxis stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} />
                                <Tooltip
                                    cursor={{ fill: '#334155', opacity: 0.2 }}
                                    contentStyle={{ backgroundColor: '#1e293b', borderColor: '#334155', color: '#f8fafc' }}
                                />
                                <Legend />
                                <Bar dataKey="totalPnl" name="Kar/Zarar ($)" fill="#82ca9d" radius={[4, 4, 0, 0]} />
                                <Bar dataKey="winRate" name="Başarı (%)" fill="#8884d8" radius={[4, 4, 0, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </div>
            </div>
        </div>
    );
}

function StatCard({ title, value, isCurrency = false, isPercent = false }: any) {
    let displayValue = value;
    let colorClass = "text-white";

    if (value === undefined || value === null) {
        displayValue = "-";
        colorClass = "text-slate-500";
    } else {
        if (isCurrency) {
            displayValue = (value >= 0 ? '+' : '') + `$${Number(value).toFixed(2)}`;
            colorClass = value >= 0 ? "text-green-400" : "text-red-400";
        } else if (isPercent) {
            displayValue = `%${Number(value).toFixed(1)}`;
            colorClass = value >= 50 ? "text-green-400" : "text-orange-400";
        }
    }

    return (
        <div className="bg-slate-800/40 p-5 rounded-2xl border border-slate-700/50 flex flex-col justify-center">
            <span className="text-slate-500 text-xs font-bold uppercase tracking-wider mb-2">{title}</span>
            <span className={`text-2xl font-bold font-mono ${colorClass}`}>{displayValue}</span>
        </div>
    );
}
