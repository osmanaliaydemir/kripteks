import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export',
  trailingSlash: true, // /backtest -> /backtest/index.html olarak üretir (IIS için ideal)
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          {
            key: "Content-Security-Policy",
            value: "default-src * 'unsafe-inline' 'unsafe-eval' data: blob:; script-src * 'unsafe-inline' 'unsafe-eval' data: blob:; connect-src * ws: wss:; img-src * data: blob:; style-src * 'unsafe-inline'; font-src * data:; frame-src *; object-src 'none';"
          }
        ]
      }
    ];
  }
};

export default nextConfig;
