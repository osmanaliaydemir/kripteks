import type { Metadata } from "next";
import "./globals.css";
import { Activity } from "lucide-react";
import { Toaster } from "sonner";
import { UIProvider } from "@/context/UIContext";
import { SignalRProvider } from "@/context/SignalRContext";

export const metadata: Metadata = {
  title: "Kripteks | Bot",
  description: "OAA kripteks, kripto alım satım botu",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="tr" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet" />
        <meta httpEquiv="Content-Security-Policy" content="script-src 'self' 'unsafe-eval' 'unsafe-inline' https://s3.tradingview.com https://*.tradingview.com blob:; object-src 'none';" />
      </head>
      <body suppressHydrationWarning className="antialiased min-h-screen bg-slate-950 text-slate-50 selection:bg-amber-500 selection:text-black font-['Inter']">
        <UIProvider>
          <SignalRProvider>
            {children}
            <Toaster richColors position="top-right" theme="dark" closeButton />
          </SignalRProvider>
        </UIProvider>
      </body>
    </html>
  );
}
