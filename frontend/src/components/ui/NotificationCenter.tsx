"use client";

import React, { useEffect, useState, useRef, useCallback } from "react";
import { Bell, CheckCircle2 } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { NotificationService } from "@/lib/api";
import { toast } from "sonner";
import { NotificationItem } from "./NotificationItem";
import { useSignalR } from "@/context/SignalRContext";
import { PagedResult } from "@/types";

interface NotificationCenterProps {
    user: any;
}

export function NotificationCenter({ user }: NotificationCenterProps) {
    const [isOpen, setIsOpen] = useState(false);
    const [notifications, setNotifications] = useState<any[]>([]);
    const [hasMore, setHasMore] = useState(false);
    const [page, setPage] = useState(1);
    const [isLoadingMore, setIsLoadingMore] = useState(false);
    const scrollRef = useRef<HTMLDivElement>(null);
    const { connection } = useSignalR();
    const unreadCount = notifications.filter(n => !n.isRead).length;

    const fetchNotifications = useCallback(async (p: number = 1, append: boolean = false) => {
        if (!user) return;
        if (append) setIsLoadingMore(true);
        try {
            const result = await NotificationService.getUnread(p, 20);
            const paged = result as PagedResult<any>;
            const items = Array.isArray(paged?.items) ? paged.items : (Array.isArray(result) ? result : []);
            if (append) {
                setNotifications(prev => {
                    const safePrev = Array.isArray(prev) ? prev : [];
                    return [...safePrev, ...items];
                });
            } else {
                setNotifications(items);
            }
            setPage(paged?.page ?? p);
            setHasMore(paged?.hasMore ?? false);
        } catch (error) {
            console.error("Failed to fetch notifications", error);
        } finally {
            setIsLoadingMore(false);
        }
    }, [user]);

    const handleNotificationScroll = useCallback(() => {
        const el = scrollRef.current;
        if (!el || isLoadingMore || !hasMore) return;
        if (el.scrollTop + el.clientHeight >= el.scrollHeight - 50) {
            fetchNotifications(page + 1, true);
        }
    }, [isLoadingMore, hasMore, page, fetchNotifications]);

    useEffect(() => {
        fetchNotifications(1);

        if (connection) {
            connection.on("ReceiveNotification", (notification: any) => {
                setNotifications(prev => {
                    const safePrev = Array.isArray(prev) ? prev : [];
                    return [notification, ...safePrev];
                });
                toast(notification.title, {
                    description: notification.message,
                    duration: 5000,
                    icon: <Bell size={16} className="text-primary" />
                });
            });
        }

        return () => {
            if (connection) {
                connection.off("ReceiveNotification");
            }
        };
    }, [connection, user]);

    const handleMarkAsRead = async (id: string) => {
        try {
            await NotificationService.markAsRead(id);
            setNotifications(prev => prev.map(n => n.id === id ? { ...n, isRead: true } : n));
        } catch (error) {
            console.error("Failed to mark notification as read", error);
        }
    };

    const handleMarkAllAsRead = async () => {
        try {
            await NotificationService.markAllAsRead();
            setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
            toast.success("Başarılı", { description: "Tüm bildirimler okundu olarak işaretlendi." });
        } catch (error) {
            console.error("Failed to mark all as read", error);
            toast.error("İşlem başarısız.");
        }
    };

    return (
        <div className="relative z-50">
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="relative p-2.5 rounded-full bg-slate-800/50 hover:bg-slate-700/80 text-slate-400 hover:text-white transition-all ring-1 ring-white/5 group"
            >
                <Bell size={18} className="transition-transform group-hover:rotate-12" />
                {unreadCount > 0 && (
                    <span className="absolute top-2 right-2.5 w-2.5 h-2.5 bg-rose-500 rounded-full border-2 border-slate-900 animate-pulse"></span>
                )}
            </button>

            <AnimatePresence>
                {isOpen && (
                    <>
                        <div className="fixed inset-0 z-10" onClick={() => setIsOpen(false)}></div>
                        <motion.div
                            initial={{ opacity: 0, y: 10, scale: 0.95 }}
                            animate={{ opacity: 1, y: 0, scale: 1 }}
                            exit={{ opacity: 0, y: 10, scale: 0.95 }}
                            className="absolute right-0 mt-3 w-80 glass-card p-2 z-20 flex flex-col bg-slate-900/95 border border-white/10 shadow-2xl overflow-hidden rounded-2xl"
                        >
                            <div className="flex items-center justify-between px-4 py-3 border-b border-white/5 bg-white/5">
                                <h3 className="text-sm font-bold text-white font-display">Bildirimler {unreadCount > 0 && `(${unreadCount})`}</h3>
                                {unreadCount > 0 && (
                                    <button
                                        onClick={handleMarkAllAsRead}
                                        className="text-[9px] font-bold text-slate-400 hover:text-white flex items-center gap-1.5 transition-colors bg-slate-800/50 px-2 py-1 rounded-lg border border-white/5"
                                    >
                                        <CheckCircle2 size={10} />
                                        Tümünü Oku
                                    </button>
                                )}
                            </div>

                            <div ref={scrollRef} onScroll={handleNotificationScroll} className="max-h-80 overflow-y-auto scrollbar-hide">
                                {notifications.length === 0 ? (
                                    <div className="flex flex-col items-center justify-center py-12 text-center opacity-60">
                                        <div className="w-12 h-12 bg-slate-800/50 rounded-2xl flex items-center justify-center mb-3 text-slate-600 border border-white/5">
                                            <Bell size={20} />
                                        </div>
                                        <p className="text-slate-500 text-xs font-medium">Yeni bildiriminiz yok.</p>
                                    </div>
                                ) : (
                                    <div className="flex flex-col divide-y divide-white/5">
                                        {notifications.map((notification) => (
                                            <NotificationItem
                                                key={notification.id}
                                                notification={notification}
                                                onMarkAsRead={handleMarkAsRead}
                                            />
                                        ))}
                                        {isLoadingMore && (
                                            <div className="flex justify-center py-3">
                                                <div className="w-4 h-4 border-2 border-primary/30 border-t-primary rounded-full animate-spin"></div>
                                            </div>
                                        )}
                                    </div>
                                )}
                            </div>
                        </motion.div>
                    </>
                )}
            </AnimatePresence>
        </div>
    );
}
