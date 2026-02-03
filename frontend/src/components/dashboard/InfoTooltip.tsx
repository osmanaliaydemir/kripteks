"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Info } from "lucide-react";

interface InfoTooltipProps {
    text: string;
}

export function InfoTooltip({ text }: InfoTooltipProps) {
    const [isVisible, setIsVisible] = useState(false);
    return (
        <div className="relative inline-block ml-1" onMouseEnter={() => setIsVisible(true)} onMouseLeave={() => setIsVisible(false)}>
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
                        <p className="text-[10px] leading-relaxed text-slate-300 font-semibold">{text}</p>
                        <div className="absolute top-full left-1/2 -translate-x-1/2 border-[6px] border-transparent border-t-slate-900/95"></div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
}
