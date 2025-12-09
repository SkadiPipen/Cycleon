import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import react from '@vitejs/plugin-react';
// @ts-ignore
import tailwindcss from '@tailwindcss/vite';
import { wayfinder } from '@laravel/vite-plugin-wayfinder';

export default defineConfig({
    // IMPORTANT → Fixes HTTPS mixed content on Render
    base: '',

    plugins: [
        laravel({
            input: [
                'resources/css/app.css',
                'resources/js/app.tsx',
            ],
            ssr: 'resources/js/ssr.tsx',
            refresh: true,
        }),

        react(),
        tailwindcss(),

        wayfinder({
            formVariants: true,
        }),
    ],

    esbuild: {
        jsx: 'automatic',
    },
});
