import { describe, it, expect, beforeEach } from 'vitest';
import { useThemeStore } from '../useThemeStore';

describe('useThemeStore', () => {
  beforeEach(() => {
    localStorage.clear();
    // Reset the store to initial state
    useThemeStore.setState({ darkMode: true });
  });

  it('defaults to dark mode when localStorage has no value', () => {
    const state = useThemeStore.getState();
    expect(state.darkMode).toBe(true);
  });

  it('toggles dark mode off', () => {
    useThemeStore.getState().toggleDarkMode();
    expect(useThemeStore.getState().darkMode).toBe(false);
    expect(localStorage.getItem('cobalt_dark_mode')).toBe('false');
  });

  it('toggles dark mode back on', () => {
    useThemeStore.getState().toggleDarkMode(); // off
    useThemeStore.getState().toggleDarkMode(); // on
    expect(useThemeStore.getState().darkMode).toBe(true);
    expect(localStorage.getItem('cobalt_dark_mode')).toBe('true');
  });

  it('updates document classList on toggle', () => {
    useThemeStore.getState().toggleDarkMode();
    expect(document.documentElement.classList.contains('bp5-dark')).toBe(false);

    useThemeStore.getState().toggleDarkMode();
    expect(document.documentElement.classList.contains('bp5-dark')).toBe(true);
  });
});
