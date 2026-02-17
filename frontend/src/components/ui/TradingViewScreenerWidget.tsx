"use client";
import React, { useEffect, useRef, memo } from "react";

interface TradingViewScreenerWidgetProps {
    width?: string | number;
    height?: string | number;
    defaultColumn?: string;
    market?: string;
}

const TradingViewScreenerWidget = memo(({ 
    width = "100%", 
    height = 550, 
    defaultColumn = "overview",
    market = "turkey"
}: TradingViewScreenerWidgetProps) => {
    const container = useRef<HTMLDivElement>(null);

    useEffect(() => {
        const currentContainer = container.current;
        if (!currentContainer) return;

        // Clear previous content to avoid duplicates on re-renders
        currentContainer.innerHTML = "";

        const widgetContainer = document.createElement("div");
        widgetContainer.className = "tradingview-widget-container";
        widgetContainer.style.width = "100%";
        widgetContainer.style.height = "100%";
        
        const widgetWrapper = document.createElement("div");
        widgetWrapper.className = "tradingview-widget-container__widget";
        widgetContainer.appendChild(widgetWrapper);

        const script = document.createElement("script");
        script.type = "text/javascript";
        script.src = "https://s3.tradingview.com/external-embedding/embed-widget-screener.js";
        script.async = true;
        
        const config = {
            "width": width,
            "height": height,
            "defaultColumn": defaultColumn,
            "defaultScreen": "general",
            "market": market,
            "showToolbar": true,
            "colorTheme": "dark",
            "locale": "tr",
            "isTransparent": true,
             "footerLocale": "tr",
             "largeChartUrl": "",
             "backgroundColor": "#0f172a" // Slate-900 match
        };

        script.innerHTML = JSON.stringify(config);
        widgetContainer.appendChild(script);
        currentContainer.appendChild(widgetContainer);

        return () => {
            if (currentContainer) currentContainer.innerHTML = "";
        };
    }, [width, height, defaultColumn, market]);

    return (
        <div ref={container} className="w-full h-full rounded-2xl overflow-hidden border border-white/5 bg-slate-900/40 backdrop-blur-sm" />
    );
});

TradingViewScreenerWidget.displayName = "TradingViewScreenerWidget";

export default TradingViewScreenerWidget;
