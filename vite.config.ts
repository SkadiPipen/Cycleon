import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import react from '@vitejs/plugin-react';
// @ts-ignore
import path from 'path';

export default defineConfig({
    // Fix mixed content by forcing relative URLs
    base: '',

    plugins: [
        laravel({
            input: ['resources/js/app.tsx'],
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
            '/proxy': {
                target: 'https://gagapi.onrender.com',
                changeOrigin: true,
                rewrite: (path) => path.replace(/^\/proxy/, ''),
            },
        },
    },

    esbuild: {
        jsx: 'automatic',
    },
});
