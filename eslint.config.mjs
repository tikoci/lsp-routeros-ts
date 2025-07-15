/**
 * ESLint configuration for the project.
 *
 * See https://eslint.style and https://typescript-eslint.io for additional linting options.
 */
/*
 * @ts-check
 * import js from '@eslint/js';
 */
import tseslint from 'typescript-eslint'
import stylistic from '@stylistic/eslint-plugin'
import js from '@eslint/js'

export default tseslint.config(
  {
    ignores: [
      '**/dist',
      '**/out',
      '**/*webpack.config.js',
      '.scratch',
      '.vscode-test-web',
      '*.*s*',
      './**/test*',
      '*/repl/*',
    ],
    files: [
      'server/src/*.ts',
      'client/src/*.ts',
    ],
  },
  stylistic.configs.recommended,
  ...tseslint.configs.recommended,
  ...tseslint.configs.stylistic,
  {
    plugins: {
      '@stylistic': stylistic,
      js,
    },
    rules: {
      // 'curly': 'warn',
      'curly': [
        'error',
        'multi-line',
      ],

      /*
             * 'semi': ['error', 'never'],
             * '@stylistic/semi': ['error', 'never'],
             * 'semi': ['warn', 'always', { omitLastInOneLineClassBody: true, omitLastInOneLineBlock: true }],
             * '@stylistic/max-statements-per-line': ['error', { max: 2 }],
             * '@stylistic/nonblock-statement-body-position': ['warn', 'beside'],
             */
      '@typescript-eslint/no-empty-function': 'off',
      '@typescript-eslint/naming-convention': [
        'warn',
        {
          selector: 'import',
          format: [
            'camelCase',
            'PascalCase',
          ],
        },
      ],
      '@typescript-eslint/no-unused-vars': [
        'error',
        {
          argsIgnorePattern: '^_',
        },
      ],
    },
  },
)
