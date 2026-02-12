"use client";

import { useEffect, useState } from "react";
import { User } from "@/types";
import { motion, AnimatePresence } from "framer-motion";
import { Activity, LayoutDashboard, FlaskConical, BarChart2, LogOut, Settings, Key, User as UserIcon, Database, Lock, Bell, HelpCircle, Wallet, Target, Menu, X, ChevronDown } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useUI } from "@/context/UIContext";
import { useSignalR } from "@/context/SignalRContext";
import { toast } from "sonner";
import { NotificationCenter } from "./NotificationCenter";

interface NavbarProps {
    user: User | null;
}

export default function Navbar({ user }: NavbarProps) {
    const pathname = usePathname();
    const { openLogs } = useUI();
    const { connection, isConnected: isSignalRConnected } = useSignalR();
    const [isProfileOpen, setIsProfileOpen] = useState(false);
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
    const [isStatusVisible, setIsStatusVisible] = useState(false);
    const [statusTimeout, setStatusTimeout] = useState<NodeJS.Timeout | null>(null);
    const [localUser, setLocalUser] = useState<User | null>(user);

    useEffect(() => {
        if (!user) {
            const storedUser = localStorage.getItem("user");
            if (storedUser) {
                try {
                    setLocalUser(JSON.parse(storedUser));
                } catch (e) {
                    console.error("User parse error", e);
                }
            }
        } else {
            setLocalUser(user);
        }
    }, [user]);

    // Close mobile menu when route changes
    useEffect(() => {
        setIsMobileMenuOpen(false);
    }, [pathname]);

    const handleLogout = () => {
        localStorage.removeItem("token");
        localStorage.removeItem("user");
        window.location.href = '/login';
    };

    const navItems = [
        { id: 'dashboard', label: 'Dashboard', href: '/', icon: <LayoutDashboard size={16} /> },
        { id: 'wallet', label: 'Cüzdanım', href: '/wallet', icon: <Wallet size={16} /> },
        { id: 'scanner', label: 'Tarayıcı', href: '/scanner', icon: <Target size={16} /> },
        { id: 'backtest', label: 'Simülasyon', href: '/backtest', icon: <FlaskConical size={16} /> },
        { id: 'reports', label: 'Raporlar', href: '/reports', icon: <BarChart2 size={16} /> },
        { id: 'alerts', label: 'Alarmlar', href: '/alerts', icon: <Bell size={16} /> },
        { id: 'settings', label: 'Ayarlar', href: '/settings', icon: <Settings size={16} /> },
    ];

    const isActive = (href: string) => {
        if (href === '/' && pathname === '/') return true;
        if (href !== '/' && pathname.startsWith(href)) return true;
        return false;
    };

    return (
        <>
            <header className="flex items-center justify-between mb-6 md:mb-10 sticky top-0 z-40 bg-slate-950/80 backdrop-blur-md py-4 transition-all">
                {/* Logo Section */}
                <div className="flex items-center gap-4">
                    <button
                        onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                        className="md:hidden p-2 text-slate-400 hover:text-white bg-slate-900/50 rounded-xl"
                    >
                        {isMobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
                    </button>

                    <Link href="/" className="flex items-center gap-4 group">
                        <div className="relative hidden sm:block">
                            <div className="absolute inset-0 bg-primary/40 rounded-xl blur-lg group-hover:blur-xl transition-all"></div>
                            <div className="bg-slate-900 border border-white/10 p-2.5 rounded-xl shadow-lg relative">
                                <Activity className="text-secondary w-6 h-6" />
                            </div>
                        </div>
                        <div>
                            <div className="flex items-center gap-2">
                                <h1 className="text-xl md:text-2xl font-display font-bold text-white tracking-wide">
                                    KRIP<span className="text-primary">TEKS</span>
                                </h1>
                            </div>
                            <p className="text-[10px] text-slate-400 font-mono tracking-widest uppercase opacity-80 hidden sm:block">Otonom Motor v2.1</p>
                        </div>
                    </Link>

                    {/* Desktop Navigation Menu */}
                    <nav className="hidden md:flex items-center gap-1 bg-slate-900/40 p-1 rounded-xl border border-white/5 backdrop-blur-sm ml-4">
                        <Link
                            href="/"
                            className={`flex items-center gap-2 px-4 py-2.5 rounded-lg text-xs font-bold transition-all ${isActive('/')
                                ? 'bg-slate-800 text-white shadow-lg ring-1 ring-white/10'
                                : 'text-slate-400 hover:text-white hover:bg-slate-800/50'
                                }`}
                        >
                            <LayoutDashboard size={16} />
                            Dashboard
                        </Link>

                        <Link
                            href="/wallet"
                            className={`flex items-center gap-2 px-4 py-2.5 rounded-lg text-xs font-bold transition-all ${isActive('/wallet')
                                ? 'bg-slate-800 text-white shadow-lg ring-1 ring-white/10'
                                : 'text-slate-400 hover:text-white hover:bg-slate-800/50'
                                }`}
                        >
                            <Wallet size={16} />
                            Cüzdanım
                        </Link>

                        {/* Tools Dropdown */}
                        <div className="relative group/menu">
                            <button className={`flex items-center gap-2 px-4 py-2.5 rounded-lg text-xs font-bold transition-all text-slate-400 hover:text-white hover:bg-slate-800/50`}>
                                <FlaskConical size={16} />
                                Araçlar
                                <ChevronDown size={14} className="text-slate-500 group-hover/menu:rotate-180 transition-transform duration-300" />
                            </button>

                            <div className="absolute top-full left-0 mt-2 w-48 bg-slate-900 border border-white/10 rounded-xl shadow-xl overflow-hidden opacity-0 invisible group-hover/menu:opacity-100 group-hover/menu:visible transition-all duration-200 transform origin-top-left z-50">
                                <Link
                                    href="/scanner"
                                    className="flex items-center gap-3 px-4 py-3 text-xs font-bold text-slate-400 hover:text-white hover:bg-white/5 transition-colors border-b border-white/5"
                                >
                                    <Target size={16} className="text-secondary" />
                                    Tarayıcı
                                </Link>
                                <Link
                                    href="/backtest"
                                    className="flex items-center gap-3 px-4 py-3 text-xs font-bold text-slate-400 hover:text-white hover:bg-white/5 transition-colors border-b border-white/5"
                                >
                                    <FlaskConical size={16} className="text-amber-500" />
                                    Simülasyon
                                </Link>
                                <Link
                                    href="/alerts"
                                    className="flex items-center gap-3 px-4 py-3 text-xs font-bold text-slate-400 hover:text-white hover:bg-white/5 transition-colors"
                                >
                                    <Bell size={16} className="text-primary" />
                                    Alarmlar
                                </Link>
                            </div>
                        </div>

                        <Link
                            href="/reports"
                            className={`flex items-center gap-2 px-4 py-2.5 rounded-lg text-xs font-bold transition-all ${isActive('/reports')
                                ? 'bg-slate-800 text-white shadow-lg ring-1 ring-white/10'
                                : 'text-slate-400 hover:text-white hover:bg-slate-800/50'
                                }`}
                        >
                            <BarChart2 size={16} />
                            Raporlar
                        </Link>

                        <Link
                            href="/settings"
                            className={`flex items-center gap-2 px-4 py-2.5 rounded-lg text-xs font-bold transition-all ${isActive('/settings')
                                ? 'bg-slate-800 text-white shadow-lg ring-1 ring-white/10'
                                : 'text-slate-400 hover:text-white hover:bg-slate-800/50'
                                }`}
                        >
                            <Settings size={16} />
                            Ayarlar
                        </Link>
                    </nav>
                </div>

                {/* Right Side: Status & Profile */}
                <div className="flex items-center gap-3 md:gap-6">
                    {/* System Status - Desktop Only */}
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

                    <NotificationCenter user={user} />

                    {/* Profile */}
                    <div className="relative z-50">
                        <button
                            onClick={() => setIsProfileOpen(!isProfileOpen)}
                            className="flex items-center gap-3 glass-card px-2 py-1.5 pl-2 md:pl-4 pr-1.5 transition-all group hover:bg-slate-800"
                        >
                            <div className="text-right hidden sm:block">
                                <p className="text-xs font-bold text-white leading-tight group-hover:text-primary transition-colors">
                                    {user?.firstName || "Misafir"}
                                </p>
                                <p className="text-[10px] text-slate-400 font-mono leading-tight">
                                    {(user?.role || user?.Role) === 'Admin' ? 'YÖNETİCİ' : ((user?.role || user?.Role)?.toUpperCase() || 'MİSAFİR')}
                                </p>
                            </div>
                            <div className="w-8 h-8 md:w-9 md:h-9 bg-linear-to-br from-primary to-primary-light rounded-lg flex items-center justify-center text-slate-900 font-bold text-sm shadow-lg">
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

            {/* Mobile Menu Overlay */}
            <AnimatePresence>
                {isMobileMenuOpen && (
                    <>
                        <motion.div
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            exit={{ opacity: 0 }}
                            className="fixed inset-0 bg-slate-950/90 z-30 md:hidden backdrop-blur-sm"
                            onClick={() => setIsMobileMenuOpen(false)}
                        />
                        <motion.div
                            initial={{ x: "-100%" }}
                            animate={{ x: 0 }}
                            exit={{ x: "-100%" }}
                            transition={{ type: "spring", stiffness: 300, damping: 30 }}
                            className="fixed inset-y-0 left-0 w-3/4 max-w-xs bg-slate-900 border-r border-white/10 z-30 md:hidden shadow-2xl p-6 overflow-y-auto"
                        >
                            <div className="flex items-center gap-3 mb-10">
                                <div className="bg-slate-800 p-2 rounded-xl">
                                    <Activity className="text-secondary w-6 h-6" />
                                </div>
                                <h2 className="text-2xl font-display font-bold text-white">
                                    KRIP<span className="text-primary">TEKS</span>
                                </h2>
                            </div>

                            <nav className="flex flex-col gap-2">
                                <Link
                                    href="/"
                                    onClick={() => setIsMobileMenuOpen(false)}
                                    className={`flex items-center gap-4 px-4 py-4 rounded-xl text-sm font-bold transition-all ${isActive('/') ? 'bg-slate-800 text-white shadow-lg border border-white/5' : 'text-slate-400 hover:text-white hover:bg-slate-800/50'}`}
                                >
                                    <div className={`p-2 rounded-lg ${isActive('/') ? 'bg-primary/20 text-primary' : 'bg-slate-950 text-slate-500'}`}>
                                        <LayoutDashboard size={16} />
                                    </div>
                                    Dashboard
                                </Link>

                                <Link
                                    href="/wallet"
                                    onClick={() => setIsMobileMenuOpen(false)}
                                    className={`flex items-center gap-4 px-4 py-4 rounded-xl text-sm font-bold transition-all ${isActive('/wallet') ? 'bg-slate-800 text-white shadow-lg border border-white/5' : 'text-slate-400 hover:text-white hover:bg-slate-800/50'}`}
                                >
                                    <div className={`p-2 rounded-lg ${isActive('/wallet') ? 'bg-primary/20 text-primary' : 'bg-slate-950 text-slate-500'}`}>
                                        <Wallet size={16} />
                                    </div>
                                    Cüzdanım
                                </Link>

                                <div className="px-4 py-2 mt-2 mb-1 text-xs font-bold text-slate-500 uppercase tracking-wider">Araçlar</div>

                                <Link
                                    href="/scanner"
                                    onClick={() => setIsMobileMenuOpen(false)}
                                    className={`flex items-center gap-4 px-4 py-3 rounded-xl text-sm font-bold transition-all ${isActive('/scanner') ? 'bg-slate-800 text-white shadow-lg border border-white/5' : 'text-slate-400 hover:text-white hover:bg-slate-800/50'}`}
                                >
                                    <div className={`p-2 rounded-lg ${isActive('/scanner') ? 'bg-secondary/20 text-secondary' : 'bg-slate-950 text-slate-500'}`}>
                                        <Target size={16} />
                                    </div>
                                    Tarayıcı
                                </Link>

                                <Link
                                    href="/backtest"
                                    onClick={() => setIsMobileMenuOpen(false)}
                                    className={`flex items-center gap-4 px-4 py-3 rounded-xl text-sm font-bold transition-all ${isActive('/backtest') ? 'bg-slate-800 text-white shadow-lg border border-white/5' : 'text-slate-400 hover:text-white hover:bg-slate-800/50'}`}
                                >
                                    <div className={`p-2 rounded-lg ${isActive('/backtest') ? 'bg-amber-500/20 text-amber-500' : 'bg-slate-950 text-slate-500'}`}>
                                        <FlaskConical size={16} />
                                    </div>
                                    Simülasyon
                                </Link>

                                <Link
                                    href="/alerts"
                                    onClick={() => setIsMobileMenuOpen(false)}
                                    className={`flex items-center gap-4 px-4 py-3 rounded-xl text-sm font-bold transition-all ${isActive('/alerts') ? 'bg-slate-800 text-white shadow-lg border border-white/5' : 'text-slate-400 hover:text-white hover:bg-slate-800/50'}`}
                                >
                                    <div className={`p-2 rounded-lg ${isActive('/alerts') ? 'bg-primary/20 text-primary' : 'bg-slate-950 text-slate-500'}`}>
                                        <Bell size={16} />
                                    </div>
                                    Alarmlar
                                </Link>

                                <div className="h-px bg-white/5 my-2"></div>

                                <Link
                                    href="/reports"
                                    onClick={() => setIsMobileMenuOpen(false)}
                                    className={`flex items-center gap-4 px-4 py-4 rounded-xl text-sm font-bold transition-all ${isActive('/reports') ? 'bg-slate-800 text-white shadow-lg border border-white/5' : 'text-slate-400 hover:text-white hover:bg-slate-800/50'}`}
                                >
                                    <div className={`p-2 rounded-lg ${isActive('/reports') ? 'bg-primary/20 text-primary' : 'bg-slate-950 text-slate-500'}`}>
                                        <BarChart2 size={16} />
                                    </div>
                                    Raporlar
                                </Link>

                                <Link
                                    href="/settings"
                                    onClick={() => setIsMobileMenuOpen(false)}
                                    className={`flex items-center gap-4 px-4 py-4 rounded-xl text-sm font-bold transition-all ${isActive('/settings') ? 'bg-slate-800 text-white shadow-lg border border-white/5' : 'text-slate-400 hover:text-white hover:bg-slate-800/50'}`}
                                >
                                    <div className={`p-2 rounded-lg ${isActive('/settings') ? 'bg-primary/20 text-primary' : 'bg-slate-950 text-slate-500'}`}>
                                        <Settings size={16} />
                                    </div>
                                    Ayarlar
                                </Link>
                            </nav>

                            <div className="mt-10 pt-10 border-t border-white/5">
                                <div className="flex items-center gap-3 px-4 py-3 bg-slate-950/50 rounded-xl mb-4">
                                    <div className={`w-2 h-2 rounded-full ${isSignalRConnected ? 'bg-emerald-500 animate-pulse' : 'bg-rose-500'}`} />
                                    <span className="text-xs font-medium text-slate-400">
                                        {isSignalRConnected ? 'Sistem Çevrimiçi' : 'Bağlantı Yok'}
                                    </span>
                                </div>
                                <p className="text-xs text-slate-500 text-center">Version 2.1 Mobile</p>
                            </div>
                        </motion.div>
                    </>
                )}
            </AnimatePresence>
        </>
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
