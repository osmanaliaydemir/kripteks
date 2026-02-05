"use client";

import React, { useState, useMemo } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X, Search, CheckCircle2, Save, Loader2, ListPlus } from "lucide-react";
import { Coin, ScannerFavoriteList } from "@/types";
import { ScannerService } from "@/lib/api";
import { toast } from "sonner";

interface FavoriteListModalProps {
    isOpen: boolean;
    onClose: () => void;
    coins: Coin[];
    onSaved: () => void;
    editList?: ScannerFavoriteList | null;
}

export default function FavoriteListModal({ isOpen, onClose, coins, onSaved, editList }: FavoriteListModalProps) {
    const [name, setName] = useState(editList?.name || "");
    const [selectedSymbols, setSelectedSymbols] = useState<string[]>(editList?.symbols || []);
    const [searchTerm, setSearchTerm] = useState("");
    const [isSaving, setIsSaving] = useState(false);

    React.useEffect(() => {
        if (editList) {
            setName(editList.name);
            setSelectedSymbols(editList.symbols);
        } else {
            setName("");
            setSelectedSymbols([]);
        }
    }, [editList, isOpen]);

    const filteredCoins = useMemo(() => {
        return coins.filter(c => c.symbol.toLowerCase().includes(searchTerm.toLowerCase()));
    }, [coins, searchTerm]);

    const handleToggleSymbol = (symbol: string) => {
        setSelectedSymbols(prev =>
            prev.includes(symbol) ? prev.filter(s => s !== symbol) : [...prev, symbol]
        );
    };

    const handleSave = async () => {
        if (!name.trim()) {
            toast.error("Liste adı boş olamaz.");
            return;
        }
        if (selectedSymbols.length === 0) {
            toast.error("En az bir parite seçmelisiniz.");
            return;
        }

        setIsSaving(true);
        try {
            await ScannerService.saveFavorite({
                id: editList?.id,
                name: name.trim(),
                symbols: selectedSymbols
            });
            toast.success("Liste Kaydedildi", { description: `${name} listesi başarıyla güncellendi.` });
            onSaved();
            onClose();
        } catch (error: any) {
            toast.error("Hata", { description: error.message || "Liste kaydedilemedi." });
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <AnimatePresence>
            {isOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95, y: 20 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.95, y: 20 }}
                        className="bg-slate-900 border border-white/10 rounded-3xl w-full max-w-2xl overflow-hidden flex flex-col max-h-[90vh] shadow-2xl"
                    >
                        {/* Header */}
                        <div className="p-6 border-b border-white/5 flex items-center justify-between bg-white/2">
                            <div className="flex items-center gap-4">
                                <div className="p-3 bg-primary/10 rounded-2xl text-primary border border-primary/20">
                                    <ListPlus size={24} />
                                </div>
                                <div>
                                    <h3 className="text-xl font-black text-white">{editList ? "Listeyi Düzenle" : "Yeni Liste Oluştur"}</h3>
                                    <p className="text-xs text-slate-500 font-medium">Favori paritelerinizi seçerek hızlı tarama listesi oluşturun.</p>
                                </div>
                            </div>
                            <button onClick={onClose} className="p-2 hover:bg-white/5 rounded-xl text-slate-400 transition-all">
                                <X size={20} />
                            </button>
                        </div>

                        {/* Body */}
                        <div className="p-6 overflow-y-auto custom-scrollbar space-y-6 flex-1">
                            {/* Liste Adı */}
                            <div className="space-y-2">
                                <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest pl-1">Liste Adı</label>
                                <input
                                    type="text"
                                    placeholder="Örn: DeFi Projeleri, Top ALT"
                                    value={name}
                                    onChange={(e) => setName(e.target.value)}
                                    className="w-full bg-slate-950/40 border border-white/5 rounded-2xl px-5 py-4 text-sm text-white focus:outline-none focus:border-primary/40 transition-all placeholder:text-slate-700"
                                />
                            </div>

                            {/* Parite Seçimi */}
                            <div className="space-y-3">
                                <div className="flex items-center justify-between">
                                    <label className="text-[10px] uppercase font-bold text-slate-500 tracking-widest pl-1">
                                        Pariteleri Seç ({selectedSymbols.length})
                                    </label>
                                    <div className="relative w-48">
                                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 w-3.5 h-3.5" />
                                        <input
                                            type="text"
                                            placeholder="Ara..."
                                            value={searchTerm}
                                            onChange={(e) => setSearchTerm(e.target.value)}
                                            className="w-full bg-slate-950/40 border border-white/5 rounded-xl pl-9 pr-3 py-1.5 text-[10px] text-white focus:outline-none focus:border-primary/40 transition-all"
                                        />
                                    </div>
                                </div>

                                <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-2 p-1">
                                    {filteredCoins.map(coin => {
                                        const isSelected = selectedSymbols.includes(coin.symbol);
                                        return (
                                            <button
                                                key={coin.symbol}
                                                onClick={() => handleToggleSymbol(coin.symbol)}
                                                className={`px-3 py-2.5 rounded-xl text-[10px] font-bold text-center transition-all border flex flex-col items-center justify-center gap-1.5 relative overflow-hidden group ${isSelected
                                                    ? "bg-primary/20 text-primary border-primary/30 shadow-lg shadow-primary/5"
                                                    : "bg-white/5 border-white/5 text-slate-500 hover:bg-white/10 hover:border-white/10"
                                                    }`}
                                            >
                                                {isSelected && (
                                                    <div className="absolute top-1 right-1 text-primary">
                                                        <CheckCircle2 size={10} />
                                                    </div>
                                                )}
                                                <span className="relative z-10">{coin.symbol.replace("USDT", "")}</span>
                                                <span className="text-[8px] opacity-40 group-hover:opacity-100 transition-opacity">USDT</span>
                                            </button>
                                        );
                                    })}
                                </div>
                            </div>
                        </div>

                        {/* Footer */}
                        <div className="p-6 border-t border-white/5 bg-white/1 flex items-center justify-between">
                            <button
                                onClick={onClose}
                                className="px-6 py-3 rounded-2xl bg-white/5 text-slate-400 font-bold text-sm hover:bg-white/10 transition-all"
                            >
                                Vazgeç
                            </button>
                            <button
                                onClick={handleSave}
                                disabled={isSaving || !name.trim() || selectedSymbols.length === 0}
                                className="flex items-center gap-3 px-8 py-3 bg-linear-to-r from-primary to-indigo-600 rounded-2xl font-bold text-sm text-white shadow-xl shadow-primary/20 hover:shadow-primary/40 transition-all active:scale-[0.98] disabled:opacity-50"
                            >
                                {isSaving ? (
                                    <>
                                        <Loader2 size={18} className="animate-spin" />
                                        <span>Kaydediliyor...</span>
                                    </>
                                ) : (
                                    <>
                                        <Save size={18} />
                                        <span>Listeyi Kaydet</span>
                                    </>
                                )}
                            </button>
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>
    );
}
