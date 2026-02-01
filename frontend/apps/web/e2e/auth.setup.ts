import { test as setup, expect } from '@playwright/test';

setup('authenticate as demo admin', async ({ page }) => {
  await page.goto('/login');
  await page.fill('#email', 'admin@demo.com');
  await page.fill('#password', 'password123');
  await page.click('button[type="submit"]');
  await expect(page).toHaveURL(/dashboard/);
  await page.context().storageState({ path: 'playwright/.auth/user.json' });
});
