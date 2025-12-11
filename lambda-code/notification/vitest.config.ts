import { defineConfig } from 'vitest/config';
import { resolve } from 'path';

// Needed to map the "@lib" alias used in the source code
export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      reporter: ['text', 'json', 'html'],
      exclude: ['build/**', 'tests/**', '**/*.test.ts'],
    },
  },
  resolve: {
    alias: {
      '@lib': resolve(__dirname, './src/lib'),
    },
  },
});
