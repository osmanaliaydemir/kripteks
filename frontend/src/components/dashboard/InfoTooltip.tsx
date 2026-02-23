"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Info } from "lucide-react";

interface InfoTooltipProps {
    text: string;
    position?: 'top' | 'bottom';
}

export function InfoTooltip({ text, position = 'top' }: InfoTooltipProps) {
    const [isVisible, setIsVisible] = useState(false);

    const isTop = position === 'top';

    return (
        <div className="relative inline-block z-50" onMouseEnter={() => setIsVisible(true)} onMouseLeave={() => setIsVisible(false)}>
            <div className="p-0.5 rounded-full hover:bg-white/10 transition-colors cursor-help text-slate-500 hover:text-slate-300 relative">
                <Info size={12} />
            </div>
            <AnimatePresence>
                {isVisible && (
                    <motion.div
                        initial={{ opacity: 0, scale: 0.9, y: isTop ? 5 : -5 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.9, y: isTop ? 5 : -5 }}
                        style={{ zIndex: 999999 }}
                        className={`absolute ${isTop ? 'bottom-full mb-2' : 'top-full mt-2'} left-1/2 -translate-x-1/2 w-64 p-3 bg-slate-900 border border-white/20 rounded-xl shadow-[0_0_30px_rgba(0,0,0,0.8)] pointer-events-none text-left`}
                    >
                        <p className="text-[11px] leading-relaxed text-slate-200 font-medium whitespace-pre-line">{text}</p>
                        <div className={`absolute left-1/2 -translate-x-1/2 border-[6px] border-transparent ${isTop ? 'top-full border-t-slate-900/98' : 'bottom-full border-b-slate-900/98'}`}></div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
}
