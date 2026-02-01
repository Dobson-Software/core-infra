import { test, expect } from '@playwright/test';

test.describe('Login Page', () => {
  test('renders login form', async ({ page }) => {
    await page.goto('/login');
    await expect(page.getByRole('heading', { name: 'Sign In' })).toBeVisible();
    await expect(page.locator('#email')).toBeVisible();
    await expect(page.locator('#password')).toBeVisible();
  });

  test('shows error on bad credentials', async ({ page }) => {
    await page.goto('/login');
    await page.fill('#email', 'bad@test.com');
    await page.fill('#password', 'wrongpassword');
    await page.click('button[type="submit"]');
    await expect(page.getByText('Invalid email or password')).toBeVisible();
  });

  test('has link to register', async ({ page }) => {
    await page.goto('/login');
    await expect(page.getByRole('link', { name: 'Register' })).toBeVisible();
  });
});
