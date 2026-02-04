import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'standalone', // Sunucu için gereken herşeyi bir araya toplar
  trailingSlash: true,
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
