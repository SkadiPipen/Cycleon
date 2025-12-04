// server.js
const { exec } = require('child_process');
const fs = require('fs');

const PORT = process.env.PORT || 3000;

console.log('Starting Laravel application...');

// Check if .env exists, if not create from .env.example
if (!fs.existsSync('.env') && fs.existsSync('.env.example')) {
    console.log('Copying .env.example to .env');
    fs.copyFileSync('.env.example', '.env');
}

// Start PHP server
console.log(`Starting PHP server on port ${PORT}`);
const php = exec(`php artisan serve --host=0.0.0.0 --port=${PORT}`);

php.stdout.on('data', (data) => {
    console.log(data.toString().trim());
});

php.stderr.on('data', (data) => {
    console.error('PHP Error:', data.toString().trim());
});

php.on('close', (code) => {
    console.log(`PHP server exited with code ${code}`);
    process.exit(code);
});

// Handle process termination
process.on('SIGTERM', () => {
    console.log('Received SIGTERM, shutting down...');
    php.kill('SIGTERM');
});
