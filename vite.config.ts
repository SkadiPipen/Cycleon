import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import react from '@vitejs/plugin-react';
// @ts-ignore
import path from 'path';

export default defineConfig({
    plugins: [
        laravel({
            input: [
                'resources/js/app.tsx',   // main React entry
            ],
            refresh: true,
        }),

        react(),
    ],

    resolve: {
        alias: {
            '@': path.resolve(__dirname, 'resources/js'),
        },
    },

    server: {
        host: true,
        port: 5173,

        proxy: {
            // Stock data proxy
            '/proxy/stock/grow-a-garden': {
                target: 'https://gagapi.onrender.com',
                changeOrigin: true,
                rewrite: () => '/stock/grow-a-garden'
            },

            // Weather/events proxy
            '/proxy/events/grow-a-garden': {
                target: 'https://gagapi.onrender.com',
                changeOrigin: true,
                rewrite: () => '/events/grow-a-garden'
            },

            // Optional: If you have other proxied endpoints
            '/proxy/': {
                target: 'https://gagapi.onrender.com',
                changeOrigin: true,
                rewrite: (path) => path.replace(/^\/proxy/, '')
            }
        },
    },

    // Recommended for TypeScript + JSX performance
    esbuild: {
        jsxInject: `import React from 'react'`,
    },

    // Optional: speed up HMR in large projects
    optimizeDeps: {
        include: ['react', 'react-dom'],
    },
});
