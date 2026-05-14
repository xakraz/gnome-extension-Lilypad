import { defineConfig } from 'eslint/config';

export default defineConfig([{
    languageOptions: {
        globals: {},
    },

    rules: {
        indent: ['error', 4],
        quotes: ['error', 'single'],
    },
}]);