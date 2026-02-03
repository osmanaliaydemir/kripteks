"use client";

import { useEffect, useState } from "react";
import { User } from "@/types";

interface PermissionWrapperProps {
    children: React.ReactNode;
    roles?: string[];
    fallback?: React.ReactNode;
}

export default function PermissionWrapper({
    children,
    roles = ["Admin"],
    fallback = null
}: PermissionWrapperProps) {
    const [user, setUser] = useState<User | null>(null);
    const [isMounted, setIsMounted] = useState(false);

    useEffect(() => {
        setIsMounted(true);
        const userData = localStorage.getItem("user");
        if (userData) {
            try {
                setUser(JSON.parse(userData));
            } catch (e) {
                console.error("User data parse error:", e);
            }
        }
    }, []);

    if (!isMounted) return null;

    const userRole = user?.role || user?.Role || "User";
    const hasPermission = roles.includes(userRole as string);

    if (!hasPermission) {
        return <>{fallback}</>;
    }

    return <>{children}</>;
}
