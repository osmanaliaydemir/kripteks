"use client";

import React from "react";
import { motion } from "framer-motion";

const SkeletonBase = ({ className }: { className: string }) => (
    <div className={`bg-slate-800/50 animate-pulse rounded-lg ${className}`} />
);

export function StatCardSkeleton() {
    return (
        <div className="glass-card p-6 border border-white/5 relative overflow-hidden">
            <div className="flex justify-between items-start mb-4">
                <SkeletonBase className="w-10 h-10 rounded-xl" />
                <SkeletonBase className="w-16 h-5 rounded" />
            </div>
            <SkeletonBase className="w-24 h-8 mb-2" />
            <SkeletonBase className="w-32 h-4" />
        </div>
    );
}

export function BotCardSkeleton() {
    return (
        <div className="glass-card p-4 sm:p-5 border border-white/5 bg-slate-900/40">
            <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-3">
                    <SkeletonBase className="w-10 h-10 rounded-xl" />
                    <div>
                        <SkeletonBase className="w-20 h-5 mb-1" />
                        <SkeletonBase className="w-12 h-3" />
                    </div>
                </div>
                <SkeletonBase className="w-16 h-6 rounded-full" />
            </div>
            <div className="grid grid-cols-2 gap-4 mb-4">
                <div>
                    <SkeletonBase className="w-12 h-3 mb-1" />
                    <SkeletonBase className="w-16 h-5" />
                </div>
                <div>
                    <SkeletonBase className="w-12 h-3 mb-1 text-right" />
                    <SkeletonBase className="w-16 h-5 ml-auto" />
                </div>
            </div>
            <SkeletonBase className="w-full h-10 rounded-xl" />
        </div>
    );
}

export function TableSkeleton({ rows = 5 }: { rows?: number }) {
    return (
        <div className="space-y-4">
            {[...Array(rows)].map((_, i) => (
                <div key={i} className="flex items-center justify-between p-4 bg-white/5 rounded-xl">
                    <div className="flex items-center gap-3">
                        <SkeletonBase className="w-8 h-8 rounded-lg" />
                        <SkeletonBase className="w-32 h-4" />
                    </div>
                    <SkeletonBase className="w-24 h-4" />
                    <SkeletonBase className="w-16 h-4" />
                </div>
            ))}
        </div>
    );
}

export function WalletCardSkeleton() {
    return (
        <div className="glass-card p-6 border border-white/5 relative overflow-hidden">
            <div className="flex justify-between items-start mb-4">
                <SkeletonBase className="w-12 h-12 rounded-xl" />
                <SkeletonBase className="w-20 h-5 rounded" />
            </div>
            <SkeletonBase className="w-32 h-10 mb-2" />
            <SkeletonBase className="w-24 h-4" />
        </div>
    );
}
