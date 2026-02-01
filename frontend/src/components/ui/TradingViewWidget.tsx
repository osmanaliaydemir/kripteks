"use client";
import React, { useEffect, useRef, memo } from "react";

interface TradingViewWidgetProps {
    symbol: string;
    strategy?: string; // Opsiyonel: Stratejiye göre indikatör eklemek için
}

const TradingViewWidget = memo(({ symbol, strategy }: TradingViewWidgetProps) => {
    const container = useRef<HTMLDivElement>(null);

    useEffect(() => {
        const script = document.createElement("script");
        script.src = "https://s3.tradingview.com/tv.js";
        script.async = true;
        const currentContainer = container.current;

        script.onload = () => {
            // @ts-expect-error External library
            if (window.TradingView && currentContainer) {
                // Stratejiye göre indikatörleri belirle
                const studies: string[] = [];

                // Golden Rose Stratejisi için indikatörler
                if (strategy === "strategy-golden-rose" || !strategy) {
                    studies.push("STD;Bollinger_Bands"); // Bollinger Bands
                    studies.push("STD;RSI"); // RSI
                }

                // SMA Crossover için
                if (strategy === "strategy-sma-crossover") {
                    studies.push("STD;SMA@tv-basicstudies"); // Simple Moving Average
                }

                // @ts-expect-error External library
                new window.TradingView.widget({
                    "autosize": true,
                    "symbol": "BINANCE:" + symbol.replace('/', ''),
                    "interval": "60", // 1 saat (Golden Rose için ideal)
                    "timezone": "Europe/Istanbul",
                    "theme": "dark",
                    "style": "1", // Candlestick
                    "locale": "tr",
                    "toolbar_bg": "#0f172a", // Slate-900
                    "enable_publishing": false,
                    "hide_top_toolbar": false,
                    "hide_legend": false,
                    "save_image": false,
                    "container_id": currentContainer.id,

                    // Kripteks Teması - Koyu Mod Entegrasyonu
                    "backgroundColor": "#0f172a", // Slate-900 (Ana arka plan)
                    "gridColor": "rgba(51, 65, 85, 0.2)", // Slate-700 alpha
                    "overrides": {
                        // Chart Renkleri
                        "paneProperties.background": "#0f172a",
                        "paneProperties.backgroundType": "solid",

                        // Grid Çizgileri
                        "paneProperties.vertGridProperties.color": "rgba(51, 65, 85, 0.2)",
                        "paneProperties.horzGridProperties.color": "rgba(51, 65, 85, 0.2)",

                        // Mum Renkleri (Kripteks cyan/blue teması)
                        "mainSeriesProperties.candleStyle.upColor": "#06b6d4", // Cyan-500
                        "mainSeriesProperties.candleStyle.downColor": "#ef4444", // Red-500
                        "mainSeriesProperties.candleStyle.borderUpColor": "#06b6d4",
                        "mainSeriesProperties.candleStyle.borderDownColor": "#ef4444",
                        "mainSeriesProperties.candleStyle.wickUpColor": "#06b6d4",
                        "mainSeriesProperties.candleStyle.wickDownColor": "#ef4444",

                        // Hacim Renkleri
                        "volumePaneSize": "medium",
                        "scalesProperties.backgroundColor": "#0f172a",
                        "scalesProperties.textColor": "#94a3b8", // Slate-400
                    },

                    // Varsayılan Çalışma Alanı İndikatörleri
                    "studies": studies,

                    // Kullanıcı Deneyimi
                    "allow_symbol_change": false, // Coin değiştirmeyi engelle (bot-specific chart)
                    "details": true, // Coin detaylarını göster
                    "hotlist": false, // Trend listesini gizle
                    "calendar": false, // Ekonomik takvimi gizle
                    "show_popup_button": false, // Popup butonunu gizle
                    "popup_width": "1000",
                    "popup_height": "650",

                    // Çizim Araçları
                    "hideideas": true, // Topluluk fikirlerini gizle
                    "studies_access": {
                        "type": "black",
                        "tools": [
                            { "name": "Volume", "grayed": false }
                        ]
                    },

                    // Dil ve Format
                    "numeric_formatting": {
                        "decimal_sign": ","
                    }
                });
            }
        };

        currentContainer?.appendChild(script);

        return () => {
            if (currentContainer) currentContainer.innerHTML = "";
        }
    }, [symbol, strategy]);

    return (
        <div className="w-full h-[500px] glass-card rounded-2xl overflow-hidden relative mt-4 mb-4">
            <div id={`tv_chart_${symbol.replace('/', '')}`} ref={container} className="h-full w-full" />
        </div>
    );
});

TradingViewWidget.displayName = "TradingViewWidget";
export default TradingViewWidget;
