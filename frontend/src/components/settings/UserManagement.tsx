"use client";

import React from "react";
import { UserPlus, Eye, EyeOff, Trash, Loader2 } from "lucide-react";
import { motion } from "framer-motion";

interface UserManagementProps {
    users: any[];
    isAddingUser: boolean;
    setIsAddingUser: (val: boolean) => void;
    newUser: any;
    setNewUser: (val: any) => void;
    handleAddUser: () => void;
    handleDeleteUser: (id: string, role: string) => void;
}

export function UserManagement({ users, isAddingUser, setIsAddingUser, newUser, setNewUser, handleAddUser, handleDeleteUser }: UserManagementProps) {
    const [showPass, setShowPass] = React.useState(false);

    return (
        <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            className="space-y-6"
        >
            <div className="flex items-center justify-between bg-white/5 p-4 rounded-xl border border-white/5">
                <div>
                    <h4 className="text-sm font-bold text-white">Aktif Kullanıcılar</h4>
                    <p className="text-[10px] text-slate-500 uppercase tracking-widest">Sistem yetkili listesi</p>
                </div>
                <button
                    onClick={() => setIsAddingUser(!isAddingUser)}
                    className="px-4 py-2 bg-primary hover:bg-primary-light text-black rounded-lg text-xs font-bold flex items-center gap-2 transition-all"
                >
                    <UserPlus size={16} />
                    Yeni Kullanıcı
                </button>
            </div>

            {isAddingUser && (
                <div className="bg-slate-950/50 border border-white/10 rounded-xl p-6 space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <label className="text-xs font-bold text-slate-400 uppercase">Ad</label>
                            <input type="text" value={newUser.firstName} onChange={(e) => setNewUser({ ...newUser, firstName: e.target.value })} className="w-full bg-slate-900 border border-white/5 rounded-lg px-4 py-2.5 text-sm text-white focus:border-primary/50 outline-none" />
                        </div>
                        <div className="space-y-2">
                            <label className="text-xs font-bold text-slate-400 uppercase">Soyad</label>
                            <input type="text" value={newUser.lastName} onChange={(e) => setNewUser({ ...newUser, lastName: e.target.value })} className="w-full bg-slate-900 border border-white/5 rounded-lg px-4 py-2.5 text-sm text-white focus:border-primary/50 outline-none" />
                        </div>
                        <div className="col-span-full space-y-2">
                            <label className="text-xs font-bold text-slate-400 uppercase">E-Posta</label>
                            <input type="email" value={newUser.email} onChange={(e) => setNewUser({ ...newUser, email: e.target.value })} className="w-full bg-slate-900 border border-white/5 rounded-lg px-4 py-2.5 text-sm text-white focus:border-primary/50 outline-none" />
                        </div>
                        <div className="col-span-full space-y-2">
                            <label className="text-xs font-bold text-slate-400 uppercase">Geçici Şifre</label>
                            <div className="relative">
                                <input
                                    type={showPass ? "text" : "password"}
                                    value={newUser.password}
                                    onChange={(e) => setNewUser({ ...newUser, password: e.target.value })}
                                    className="w-full bg-slate-900 border border-white/5 rounded-lg px-4 py-2.5 pr-10 text-sm text-white focus:border-primary/50 outline-none"
                                />
                                <button
                                    onClick={() => setShowPass(!showPass)}
                                    className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 p-1"
                                >
                                    {showPass ? <EyeOff size={16} /> : <Eye size={16} />}
                                </button>
                            </div>
                        </div>
                        <div className="col-span-full space-y-2">
                            <label className="text-xs font-bold text-slate-400 uppercase">Yetki / Rol</label>
                            <div className="flex gap-4">
                                <button
                                    onClick={() => setNewUser({ ...newUser, role: 'User' })}
                                    className={`flex-1 py-2.5 rounded-lg text-xs font-bold border transition-all ${newUser.role === 'User' ? 'bg-primary/20 border-primary text-primary' : 'bg-slate-900 border-white/5 text-slate-400'}`}
                                >
                                    Standart Kullanıcı (User)
                                </button>
                                <button
                                    onClick={() => setNewUser({ ...newUser, role: 'Admin' })}
                                    className={`flex-1 py-2.5 rounded-lg text-xs font-bold border transition-all ${newUser.role === 'Admin' ? 'bg-amber-500/20 border-amber-500 text-amber-500' : 'bg-slate-900 border-white/5 text-slate-400'}`}
                                >
                                    Yönetici (Admin)
                                </button>
                            </div>
                        </div>
                    </div>
                    <div className="flex justify-end gap-3 pt-4 border-t border-white/5">
                        <button onClick={() => setIsAddingUser(false)} className="text-xs font-bold text-slate-400 px-4 py-2 hover:text-white transition-colors">İptal</button>
                        <button onClick={handleAddUser} className="text-xs font-bold bg-primary text-black px-6 py-2 rounded-lg hover:bg-primary-light transition-all">Kullanıcıyı Kaydet</button>
                    </div>
                </div>
            )}

            <div className="grid gap-3">
                {users.map((u, i) => (
                    <div key={i} className="bg-slate-900/40 border border-white/5 p-4 rounded-xl flex items-center justify-between group hover:border-white/10 transition-all">
                        <div className="flex items-center gap-4">
                            <div className="w-10 h-10 rounded-xl bg-linear-to-br from-slate-800 to-slate-900 flex items-center justify-center text-primary font-bold">
                                {u.firstName?.[0]}
                            </div>
                            <div>
                                <p className="text-sm font-bold text-white leading-none mb-1">{u.firstName} {u.lastName}</p>
                                <div className="flex items-center gap-2">
                                    <p className="text-[10px] text-slate-500 font-mono">{u.email}</p>
                                    <span className="w-1 h-1 rounded-full bg-slate-700"></span>
                                    <span className="text-[9px] font-bold text-primary/80 uppercase tracking-tighter">{u.role || u.Role}</span>
                                </div>
                            </div>
                        </div>
                        <button onClick={() => handleDeleteUser(u.id, u.role)} className="p-2 text-slate-600 hover:text-rose-400 hover:bg-rose-500/10 rounded-lg transition-all opacity-0 group-hover:opacity-100">
                            <Trash size={16} />
                        </button>
                    </div>
                ))}
            </div>
        </motion.div>
    );
}
