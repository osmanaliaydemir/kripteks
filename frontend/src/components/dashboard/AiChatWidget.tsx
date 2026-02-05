"use client";

import { useState, useRef, useEffect } from "react";
import { createPortal } from "react-dom";
import { MessageCircle, X, Send, Brain, Sparkles, Loader2 } from "lucide-react";

interface Message {
    role: "user" | "assistant";
    content: string;
    timestamp: Date;
}

export default function AiChatWidget() {
    const [isOpen, setIsOpen] = useState(false);
    const [mounted, setMounted] = useState(false);
    const [messages, setMessages] = useState<Message[]>([
        {
            role: "assistant",
            content: "Merhaba! 👋 Ben Kripteks AI asistanınızım. Kripto piyasası hakkında sorularınızı yanıtlayabilirim. Ne sormak istersiniz?",
            timestamp: new Date()
        }
    ]);
    const [input, setInput] = useState("");
    const [isLoading, setIsLoading] = useState(false);
    const messagesEndRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        setMounted(true);
    }, []);

    useEffect(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    }, [messages]);

    const sendMessage = async () => {
        if (!input.trim() || isLoading) return;

        const userMessage: Message = {
            role: "user",
            content: input,
            timestamp: new Date()
        };

        setMessages(prev => [...prev, userMessage]);
        setInput("");
        setIsLoading(true);

        try {
            const token = localStorage.getItem("token");
            const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:5001"}/api/aichat/ask`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${token}`
                },
                body: JSON.stringify({ message: input })
            });

            if (res.ok) {
                const data = await res.json();
                const assistantMessage: Message = {
                    role: "assistant",
                    content: data.reply,
                    timestamp: new Date()
                };
                setMessages(prev => [...prev, assistantMessage]);
            } else {
                setMessages(prev => [...prev, {
                    role: "assistant",
                    content: "Üzgünüm, şu an yanıt veremiyorum. Lütfen tekrar deneyin.",
                    timestamp: new Date()
                }]);
            }
        } catch (error) {
            setMessages(prev => [...prev, {
                role: "assistant",
                content: "Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.",
                timestamp: new Date()
            }]);
        } finally {
            setIsLoading(false);
        }
    };

    const handleKeyPress = (e: React.KeyboardEvent) => {
        if (e.key === "Enter" && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    };

    if (!mounted) return null;

    const chatButton = (
        <button
            onClick={() => setIsOpen(true)}
            className="fixed bottom-6 right-6 z-50 w-14 h-14 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-full shadow-lg shadow-indigo-500/30 flex items-center justify-center hover:scale-110 transition-transform group"
        >
            <MessageCircle size={24} className="text-white" />
            <span className="absolute -top-1 -right-1 w-4 h-4 bg-emerald-500 rounded-full border-2 border-slate-950 animate-pulse" />
        </button>
    );

    const chatModal = isOpen ? (
        <div
            className="fixed bottom-24 right-6 w-96 max-h-[600px] bg-slate-950 border border-white/10 rounded-2xl shadow-2xl flex flex-col overflow-hidden"
            style={{ zIndex: 99998 }}
        >
            {/* Header */}
            <div className="bg-gradient-to-r from-indigo-500/20 to-purple-500/20 border-b border-white/5 p-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <div className="p-2 bg-indigo-500/10 rounded-xl border border-indigo-500/20">
                        <Brain size={20} className="text-indigo-400" />
                    </div>
                    <div>
                        <h3 className="font-bold text-white">Kripteks AI</h3>
                        <p className="text-[10px] text-slate-400">Multi-AI Asistan</p>
                    </div>
                </div>
                <button
                    onClick={() => setIsOpen(false)}
                    className="p-2 hover:bg-white/5 rounded-lg transition-colors"
                >
                    <X size={18} className="text-slate-400" />
                </button>
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4 max-h-[400px]">
                {messages.map((msg, idx) => (
                    <div
                        key={idx}
                        className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}
                    >
                        <div
                            className={`max-w-[80%] px-4 py-3 rounded-2xl ${msg.role === "user"
                                    ? "bg-indigo-500/20 text-white rounded-br-sm"
                                    : "bg-slate-800/50 text-slate-200 rounded-bl-sm"
                                }`}
                        >
                            {msg.role === "assistant" && (
                                <div className="flex items-center gap-1.5 mb-1.5">
                                    <Sparkles size={10} className="text-indigo-400" />
                                    <span className="text-[9px] text-indigo-400 font-bold uppercase">AI</span>
                                </div>
                            )}
                            <p className="text-sm leading-relaxed">{msg.content}</p>
                            <p className="text-[9px] text-slate-500 mt-1.5">
                                {msg.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                            </p>
                        </div>
                    </div>
                ))}
                {isLoading && (
                    <div className="flex justify-start">
                        <div className="bg-slate-800/50 px-4 py-3 rounded-2xl rounded-bl-sm">
                            <Loader2 size={16} className="text-indigo-400 animate-spin" />
                        </div>
                    </div>
                )}
                <div ref={messagesEndRef} />
            </div>

            {/* Input */}
            <div className="border-t border-white/5 p-4">
                <div className="flex gap-2">
                    <input
                        type="text"
                        value={input}
                        onChange={(e) => setInput(e.target.value)}
                        onKeyDown={handleKeyPress}
                        placeholder="Bir soru sorun..."
                        className="flex-1 bg-slate-800/50 border border-white/5 rounded-xl px-4 py-3 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500/50"
                        disabled={isLoading}
                    />
                    <button
                        onClick={sendMessage}
                        disabled={isLoading || !input.trim()}
                        className="px-4 py-3 bg-indigo-500 hover:bg-indigo-600 disabled:opacity-50 disabled:cursor-not-allowed rounded-xl transition-colors"
                    >
                        <Send size={16} className="text-white" />
                    </button>
                </div>
                <p className="text-[9px] text-slate-600 mt-2 text-center">
                    3 AI modeli ile desteklenmektedir
                </p>
            </div>
        </div>
    ) : null;

    return createPortal(
        <>
            {chatButton}
            {chatModal}
        </>,
        document.body
    );
}
