import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './apps/web/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI ? 'github' : 'html',
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    // Auth setup project — runs first
    {
      name: 'setup',
      testMatch: /.*\.setup\.ts/,
    },

    // Default: Chromium
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },

    // CI: Multi-browser
    ...(process.env.CI
      ? [
          {
            name: 'firefox',
            use: {
              ...devices['Desktop Firefox'],
              storageState: 'playwright/.auth/user.json',
            },
            dependencies: ['setup'],
          },
          {
            name: 'webkit',
            use: {
              ...devices['Desktop Safari'],
              storageState: 'playwright/.auth/user.json',
            },
            dependencies: ['setup'],
          },
        ]
      : []),
  ],

  // Dev server
  webServer: process.env.CI
    ? undefined
    : {
        command: 'pnpm --filter @cobalt/web dev',
        url: 'http://localhost:3000',
        reuseExistingServer: !process.env.CI,
        timeout: 120_000,
      },
});
