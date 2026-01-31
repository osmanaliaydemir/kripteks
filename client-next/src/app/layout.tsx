import type { Metadata } from "next";
import "./globals.css";
import { Activity } from "lucide-react";
import { Toaster } from "sonner";

export const metadata: Metadata = {
  title: "Kripteks | Otonom Ticaret",
  description: "Next.js & .NET Powered Trading Platform",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="tr">
      <body className="antialiased min-h-screen bg-slate-900 selection:bg-cyan-500 selection:text-white">

        {children}
        <Toaster richColors position="top-right" theme="dark" closeButton />
      </body>
    </html>
  );
}
