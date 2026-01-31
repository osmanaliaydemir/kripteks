"use client";
import { useState, useRef, useEffect } from "react";
import { Search, ChevronDown, Check } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

interface Option {
    id: string;
    symbol: string;
    currentPrice?: number;
}

interface Props {
    options: Option[];
    value: string;
    onChange: (val: string) => void;
    placeholder?: string;
    onOpen?: () => void;
    isLoading?: boolean;
}

export default function SearchableSelect({ options, value, onChange, placeholder = "Seçiniz...", onOpen, isLoading = false }: Props) {
    const [isOpen, setIsOpen] = useState(false);
    const [searchTerm, setSearchTerm] = useState("");
    const wrapperRef = useRef<HTMLDivElement>(null);

    const handleToggle = () => {
        if (!isOpen && onOpen) onOpen(); // Açılırken dışarıdan veri iste
        setIsOpen(!isOpen);
    };

    useEffect(() => {
        function handleClickOutside(event: MouseEvent) {
            if (wrapperRef.current && !wrapperRef.current.contains(event.target as Node)) {
                setIsOpen(false);
            }
        }
        document.addEventListener("mousedown", handleClickOutside);
        return () => document.removeEventListener("mousedown", handleClickOutside);
    }, []);

    const filteredOptions = options.filter(opt =>
        (opt.symbol || "").toLowerCase().includes(searchTerm.toLowerCase())
    );

    const selectedOption = options.find(opt => opt.symbol === value);

    return (
        <div className="relative" ref={wrapperRef}>
            <div
                onClick={handleToggle}
                className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-slate-200 outline-none flex items-center justify-between cursor-pointer hover:border-slate-600 transition-colors"
            >
                <span className={selectedOption ? "text-white font-mono" : "text-slate-500"}>
                    {selectedOption ? selectedOption.symbol : placeholder}
                </span>
                {isLoading ? (
                    <div className="w-4 h-4 border-2 border-cyan-500/30 border-t-cyan-500 rounded-full animate-spin"></div>
                ) : (
                    <ChevronDown size={16} className={`text-slate-500 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
                )}
            </div>

            <AnimatePresence>
                {isOpen && (
                    <motion.div
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: 10 }}
                        className="absolute top-full left-0 right-0 mt-2 bg-slate-800 border border-slate-700 rounded-xl shadow-xl z-50 overflow-hidden max-h-60 flex flex-col"
                    >
                        {/* Search Input */}
                        <div className="p-2 border-b border-slate-700/50 sticky top-0 bg-slate-800">
                            {isLoading && (
                                <div className="absolute inset-0 bg-slate-800/80 z-10 flex items-center justify-center">
                                    <span className="text-xs text-cyan-400 font-mono animate-pulse">Fiyatlar Güncelleniyor...</span>
                                </div>
                            )}
                            <div className="relative">
                                <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
                                <input
                                    type="text"
                                    autoFocus
                                    placeholder="Ara..."
                                    className="w-full bg-slate-900/50 border border-slate-700 rounded-lg pl-9 pr-3 py-2 text-xs text-white placeholder:text-slate-600 outline-none focus:border-cyan-500/50"
                                    value={searchTerm}
                                    onChange={(e) => setSearchTerm(e.target.value)}
                                />
                            </div>
                        </div>

                        {/* Options List */}
                        <div className="overflow-y-auto flex-1 p-1">
                            {filteredOptions.length > 0 ? (
                                filteredOptions.map((opt) => (
                                    <div
                                        key={opt.id}
                                        onClick={() => {
                                            onChange(opt.symbol);
                                            setIsOpen(false);
                                            setSearchTerm("");
                                        }}
                                        className={`flex items-center justify-between px-3 py-2 rounded-lg cursor-pointer text-sm transition-colors ${value === opt.symbol ? 'bg-cyan-500/20 text-cyan-400' : 'text-slate-300 hover:bg-slate-700/50 hover:text-white'}`}
                                    >
                                        <span className="font-mono">{opt.symbol}</span>
                                        <div className="flex items-center gap-3">
                                            {opt.currentPrice && (
                                                <span className="text-xs font-mono text-slate-400">
                                                    ${opt.currentPrice.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 6 })}
                                                </span>
                                            )}
                                            {value === opt.symbol && <Check size={14} />}
                                        </div>
                                    </div>
                                ))
                            ) : (
                                <div className="p-4 text-center text-xs text-slate-500 italic">Sonuç bulunamadı</div>
                            )}
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
}
