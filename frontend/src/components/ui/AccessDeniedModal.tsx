"use client";

import { motion, AnimatePresence } from "framer-motion";
import { ShieldAlert, X, Lock } from "lucide-react";

interface AccessDeniedModalProps {
    isOpen: boolean;
    onClose: () => void;
}

export default function AccessDeniedModal({
    isOpen,
    onClose
}: AccessDeniedModalProps) {
    return (
        <AnimatePresence>
            {isOpen && (
                <div className="fixed inset-0 z-100 flex items-center justify-center p-4">
                    {/* Backdrop */}
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        onClick={onClose}
                        className="absolute inset-0 bg-black/80 backdrop-blur-sm"
                    />

                    {/* Modal Content */}
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95, y: 20 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.95, y: 20 }}
                        className="relative w-full max-w-sm bg-slate-900 border border-white/10 rounded-3xl shadow-2xl overflow-hidden"
                    >
                        <div className="p-8 text-center">
                            <div className="w-20 h-20 rounded-full bg-rose-500/10 text-rose-500 mx-auto mb-6 flex items-center justify-center relative">
                                <motion.div
                                    animate={{ scale: [1, 1.1, 1] }}
                                    transition={{ repeat: Infinity, duration: 2 }}
                                    className="absolute inset-0 rounded-full bg-rose-500/5"
                                />
                                <ShieldAlert size={40} />
                                <div className="absolute -right-2 -top-2 bg-slate-900 p-1.5 rounded-full border border-white/5">
                                    <Lock size={16} className="text-slate-500" />
                                </div>
                            </div>

                            <h3 className="text-xl font-display font-bold text-white mb-3 tracking-widest uppercase">YETKİSİZ İŞLEM</h3>
                            <p className="text-slate-400 text-sm leading-relaxed mb-8 px-2">
                                Bu işlemi gerçekleştirmek için gerekli yetkiye sahip değilsiniz. Lütfen yöneticinizle iletişime geçin.
                            </p>

                            <button
                                onClick={onClose}
                                className="w-full py-4 rounded-xl bg-white text-slate-950 font-bold hover:bg-slate-200 transition-all active:scale-95 shadow-lg shadow-white/5"
                            >
                                Anladım
                            </button>
                        </div>

                        {/* Decoration */}
                        <div className="absolute top-0 left-0 w-full h-1 bg-linear-to-r from-rose-500/0 via-rose-500/40 to-rose-500/0" />
                    </motion.div>
                </div>
            )}
        </AnimatePresence>
    );
}
