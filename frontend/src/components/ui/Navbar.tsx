"use client";

import { useEffect, useState } from "react";
import { User } from "@/types";
import { motion, AnimatePresence } from "framer-motion";
import { Activity, LayoutDashboard, FlaskConical, BarChart2, LogOut, Settings, Key, User as UserIcon, Database, Lock, Bell, HelpCircle, Wallet } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useUI } from "@/context/UIContext";
import { useSignalR } from "@/context/SignalRContext";
import { toast } from "sonner";
import { NotificationService } from "@/lib/api";

interface NavbarProps {
    user: User | null;
}

export default function Navbar({ user }: NavbarProps) {
    const pathname = usePathname();
    const { openLogs } = useUI();
    const { connection, isConnected: isSignalRConnected } = useSignalR();
    const [isProfileOpen, setIsProfileOpen] = useState(false);
    const [isNotificationsOpen, setIsNotificationsOpen] = useState(false);
    const [isStatusVisible, setIsStatusVisible] = useState(false);
    const [statusTimeout, setStatusTimeout] = useState<NodeJS.Timeout | null>(null);
    const [notifications, setNotifications] = useState<any[]>([]);
    const unreadCount = notifications.filter(n => !n.isRead).length;

    useEffect(() => {
        const fetchNotifications = async () => {
            if (user) {
                try {
                    const data = await NotificationService.getUnread();
                    setNotifications(data);
                } catch (error) {
                    console.error("Failed to fetch notifications", error);
                }
            }
        };

        fetchNotifications();

        if (connection) {
            connection.on("ReceiveNotification", (notification) => {
                setNotifications(prev => [notification, ...prev]);
                // Show toast
                toast(notification.title, {
                    description: notification.message,
                    duration: 5000,
                    icon: <Bell size={16} className="text-secondary" />
                });
            });
        }

        return () => {
            if (connection) {
                connection.off("ReceiveNotification");
            }
        };
    }, [connection, user]);

    const markAllAsRead = async () => {
        try {
            await NotificationService.markAllAsRead();
            setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
        } catch (error) {
            console.error("Failed to mark all as read", error);
            toast.error("Bildirimler işaretlenemedi");
        }
    };

    const handleLogout = () => {
        localStorage.removeItem("token");
        localStorage.removeItem("user");
        window.location.href = '/login';
    };

    const navItems = [
        { id: 'dashboard', label: 'Dashboard', href: '/', icon: <LayoutDashboard size={16} /> },
        { id: 'wallet', label: 'Cüzdanım', href: '/wallet', icon: <Wallet size={16} /> },
        { id: 'backtest', label: 'Simülasyon', href: '/backtest', icon: <FlaskConical size={16} /> },
        { id: 'reports', label: 'Raporlar', href: '/reports', icon: <BarChart2 size={16} /> },
        { id: 'settings', label: 'Ayarlar', href: '/settings', icon: <Settings size={16} /> },
    ];

    const isActive = (href: string) => {
        if (href === '/' && pathname === '/') return true;
        if (href !== '/' && pathname.startsWith(href)) return true;
        return false;
    };

    return (
        <header className="flex items-center justify-between mb-10">
            {/* Logo Section */}
            <div className="flex items-center gap-8">
                <Link href="/" className="flex items-center gap-4 group">
                    <div className="relative">
                        <div className="absolute inset-0 bg-primary/40 rounded-xl blur-lg group-hover:blur-xl transition-all"></div>
                        <div className="bg-slate-900 border border-white/10 p-2.5 rounded-xl shadow-lg relative">
                            <Activity className="text-secondary w-6 h-6" />
                        </div>
                    </div>
                    <div>
                        <div className="flex items-center gap-2">
                            <h1 className="text-2xl font-display font-bold text-white tracking-wide">
                                KRIP<span className="text-primary">TEKS</span>
                            </h1>
                        </div>
                        <p className="text-[10px] text-slate-400 font-mono tracking-widest uppercase opacity-80">Otonom Motor v2.1</p>
                    </div>
                </Link>

                {/* Navigation Menu */}
                <nav className="hidden md:flex items-center gap-1 bg-slate-900/40 p-1 rounded-xl border border-white/5 backdrop-blur-sm">
                    {navItems.map((item) => (
                        <Link
                            key={item.id}
                            href={item.href}
                            className={`flex items-center gap-2 px-4 py-2.5 rounded-lg text-xs font-bold transition-all ${isActive(item.href)
                                ? 'bg-slate-800 text-white shadow-lg ring-1 ring-white/10'
                                : 'text-slate-400 hover:text-white hover:bg-slate-800/50'
                                }`}
                        >
                            {item.icon}
                            {item.label}
                        </Link>
                    ))}
                </nav>
            </div>

            {/* Right Side: Status & Profile */}
            <div className="flex items-center gap-6">
                {/* System Status */}
                <div
                    className="hidden md:flex items-center gap-0 px-3 py-2 bg-slate-900/40 rounded-full border border-white/5 backdrop-blur-sm transition-all hover:bg-slate-800/50"
                    onMouseEnter={() => {
                        setIsStatusVisible(true);
                        if (statusTimeout) clearTimeout(statusTimeout);
                    }}
                    onMouseLeave={() => {
                        const timeout = setTimeout(() => setIsStatusVisible(false), 3000);
                        setStatusTimeout(timeout);
                    }}
                >
                    <div className="relative flex h-2.5 w-2.5 shrink-0 my-1 mx-0.5">
                        <span className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${isSignalRConnected ? 'bg-emerald-400' : 'bg-rose-500'}`}></span>
                        <span className={`relative inline-flex rounded-full h-2.5 w-2.5 ${isSignalRConnected ? 'bg-emerald-500' : 'bg-rose-500'}`}></span>
                    </div>
                    <div className={`overflow-hidden transition-all duration-500 ease-in-out flex items-center ${isStatusVisible ? 'max-w-[200px] opacity-100' : 'max-w-0 opacity-0'}`}>
                        <span className="text-xs text-slate-300 font-medium tracking-wide whitespace-nowrap pl-2">
                            {isSignalRConnected ? 'SİSTEM ÇEVRİMİÇİ' : 'BAĞLANTI YOK'}
                        </span>
                    </div>
                </div>



                {/* Notifications */}
                <div className="relative z-50">
                    <button
                        onClick={() => setIsNotificationsOpen(!isNotificationsOpen)}
                        className="relative p-2.5 rounded-full bg-slate-800/50 hover:bg-slate-700/80 text-slate-400 hover:text-white transition-all ring-1 ring-white/5"
                    >
                        <Bell size={18} />
                        {unreadCount > 0 && <span className="absolute top-2 right-2.5 w-2 h-2 bg-rose-500 rounded-full border border-slate-900 animate-pulse"></span>}
                    </button>

                    <AnimatePresence>
                        {isNotificationsOpen && (
                            <>
                                <div className="fixed inset-0 z-10" onClick={() => setIsNotificationsOpen(false)}></div>
                                <motion.div
                                    initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                    animate={{ opacity: 1, y: 0, scale: 1 }}
                                    exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                    className="absolute right-0 mt-3 w-80 glass-card p-2 z-20 flex flex-col"
                                >
                                    <div className="flex items-center justify-between px-4 py-3 border-b border-white/5">
                                        <h3 className="text-sm font-bold text-white">Bildirimler {unreadCount > 0 && `(${unreadCount})`}</h3>
                                        <span onClick={markAllAsRead} className="text-[10px] font-bold text-slate-500 bg-slate-800 px-2 py-0.5 rounded cursor-pointer hover:text-white transition-colors">Tümünü Okundu İşaretle</span>
                                    </div>

                                    <div className="max-h-64 overflow-y-auto">
                                        {notifications.length === 0 ? (
                                            <div className="flex flex-col items-center justify-center py-8 text-center">
                                                <div className="w-12 h-12 bg-slate-800/50 rounded-full flex items-center justify-center mb-3 text-slate-600">
                                                    <Bell size={20} />
                                                </div>
                                                <p className="text-slate-500 text-xs font-medium">Yeni bildiriminiz yok.</p>
                                            </div>
                                        ) : (
                                            <div className="flex flex-col">
                                                {notifications.map((notification, index) => (
                                                    <div key={index} className={`p-3 border-b border-white/5 hover:bg-white/5 transition-colors ${!notification.isRead ? 'bg-slate-800/30' : ''}`}>
                                                        <div className="flex items-start gap-3">
                                                            <div className={`w-2 h-2 mt-1.5 rounded-full shrink-0 ${notification.type === 1 ? 'bg-emerald-500' : notification.type === 3 ? 'bg-rose-500' : 'bg-primary'}`}></div>
                                                            <div>
                                                                <h4 className="text-xs font-bold text-white mb-0.5">{notification.title}</h4>
                                                                <p className="text-[10px] text-slate-400 leading-relaxed">{notification.message}</p>
                                                                <p className="text-[8px] text-slate-600 mt-1 font-mono">{new Date(notification.createdAt).toLocaleTimeString()}</p>
                                                            </div>
                                                        </div>
                                                    </div>
                                                ))}
                                            </div>
                                        )}
                                    </div>
                                </motion.div>
                            </>
                        )}
                    </AnimatePresence>
                </div>

                {/* Profile */}
                <div className="relative z-50">
                    <button
                        onClick={() => setIsProfileOpen(!isProfileOpen)}
                        className="flex items-center gap-3 glass-card px-2 py-1.5 pl-4 pr-1.5 transition-all group hover:bg-slate-800"
                    >
                        <div className="text-right hidden sm:block">
                            <p className="text-xs font-bold text-white leading-tight group-hover:text-primary transition-colors">
                                {user?.firstName || "Misafir"}
                            </p>
                            <p className="text-[10px] text-slate-400 font-mono leading-tight">
                                {(user?.role || user?.Role) === 'Admin' ? 'YÖNETİCİ' : ((user?.role || user?.Role)?.toUpperCase() || 'MİSAFİR')}
                            </p>
                        </div>
                        <div className="w-9 h-9 bg-linear-to-br from-primary to-primary-light rounded-lg flex items-center justify-center text-slate-900 font-bold text-sm shadow-lg">
                            {user?.firstName?.charAt(0) || "Y"}
                        </div>
                    </button>

                    <AnimatePresence>
                        {isProfileOpen && (
                            <>
                                <div className="fixed inset-0 z-10" onClick={() => setIsProfileOpen(false)}></div>
                                <motion.div
                                    initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                    animate={{ opacity: 1, y: 0, scale: 1 }}
                                    exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                    className="absolute right-0 mt-3 w-64 glass-card p-2 z-20 flex flex-col gap-1"
                                >
                                    <div className="px-4 py-3 mb-2 bg-white/5 rounded-xl border border-white/5">
                                        <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-0.5">Giriş Yapılan Hesap</p>
                                        <p className="text-sm font-bold text-white truncate">{user?.email || "admin@kripteks.com"}</p>
                                    </div>

                                    <MenuButton icon={<Lock size={14} />} label="Şifre İşlemleri" onClick={() => { window.location.href = '/settings?tab=security'; setIsProfileOpen(false); }} />
                                    <MenuButton icon={<Database size={14} />} label="İşlem Kayıtları" onClick={() => { openLogs(); setIsProfileOpen(false); }} />

                                    <div className="h-px bg-white/10 my-1"></div>

                                    <button onClick={handleLogout} className="w-full text-left px-3 py-2.5 text-xs font-bold text-rose-400 hover:bg-rose-500/10 hover:text-rose-300 rounded-lg flex items-center gap-3 transition-colors">
                                        <LogOut size={14} />
                                        Çıkış Yap
                                    </button>
                                </motion.div>
                            </>
                        )}
                    </AnimatePresence>
                </div>
            </div>
        </header >
    );
}

function MenuButton({ icon, label, onClick }: { icon: React.ReactNode; label: string; onClick: () => void }) {
    return (
        <button onClick={onClick} className="w-full text-left px-3 py-2.5 text-xs font-bold text-slate-400 hover:bg-white/5 hover:text-white rounded-lg flex items-center gap-3 transition-colors">
            {icon}
            {label}
        </button>
    );
}
