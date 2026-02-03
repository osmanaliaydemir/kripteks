"use client";

import { motion } from "framer-motion";

export default function LoadingSkeleton() {
    return (
        <div className="w-full h-full min-h-[400px] flex flex-col gap-6 p-4 animate-pulse">
            {/* Header Skeleton */}
            <div className="flex justify-between items-center">
                <div className="h-8 w-48 bg-slate-800/50 rounded-lg"></div>
                <div className="h-8 w-24 bg-slate-800/50 rounded-lg"></div>
            </div>

            {/* KPIs Skeleton */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                {[1, 2, 3, 4].map((i) => (
                    <div key={i} className="h-32 bg-slate-800/50 rounded-2xl border border-white/5"></div>
                ))}
            </div>

            {/* Content Skeleton */}
            <div className="flex-1 bg-slate-800/50 rounded-2xl border border-white/5 p-6 space-y-4">
                <div className="h-6 w-32 bg-slate-700/50 rounded"></div>
                <div className="space-y-3">
                    {[1, 2, 3].map((i) => (
                        <div key={i} className="h-16 w-full bg-slate-700/30 rounded-xl"></div>
                    ))}
                </div>
            </div>
        </div>
    );
}
