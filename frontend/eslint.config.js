import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import reactPlugin from 'eslint-plugin-react';
import reactHooksPlugin from 'eslint-plugin-react-hooks';

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ['**/*.{ts,tsx}'],
    plugins: {
      react: reactPlugin,
      'react-hooks': reactHooksPlugin,
    },
    rules: {
      // TypeScript strict rules
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/no-non-null-assertion': 'warn',

      // React rules
      'react/prop-types': 'off',
      'react/react-in-jsx-scope': 'off',
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',

      // General
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'no-debugger': 'error',
      'prefer-const': 'error',
      'no-var': 'error',
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
  },

  // NO-MOCK policy enforcement
  {
    files: ['**/*.test.{ts,tsx}', '**/*.spec.{ts,tsx}', '**/__tests__/**'],
    rules: {
      'no-restricted-imports': [
        'error',
        {
          patterns: [
            {
              group: ['*mock*', '*Mock*'],
              message:
                'NO-MOCK POLICY: Do not import mocking utilities. Use real implementations, TestContainers, or MSW for API boundaries.',
            },
          ],
          paths: [
            {
              name: 'vitest',
              importNames: ['vi'],
              message:
                'NO-MOCK POLICY: Do not use vi.mock() or vi.spyOn(). Use real implementations or MSW.',
            },
          ],
        },
      ],
      'no-restricted-properties': [
        'error',
        {
          object: 'vi',
          property: 'mock',
          message: 'NO-MOCK POLICY: vi.mock() is banned. Use MSW for API mocking.',
        },
        {
          object: 'vi',
          property: 'spyOn',
          message: 'NO-MOCK POLICY: vi.spyOn() is banned. Use real implementations.',
        },
        {
          object: 'jest',
          property: 'mock',
          message: 'NO-MOCK POLICY: jest.mock() is banned. Use MSW for API mocking.',
        },
        {
          object: 'jest',
          property: 'spyOn',
          message: 'NO-MOCK POLICY: jest.spyOn() is banned. Use real implementations.',
        },
      ],
    },
  },

  // Ignore patterns
  {
    ignores: ['**/node_modules/**', '**/dist/**', '**/build/**', '**/coverage/**', '**/.turbo/**'],
  }
);
