import { create } from 'zustand';

interface ThemeState {
  darkMode: boolean;
  toggleDarkMode: () => void;
}

export const useThemeStore = create<ThemeState>((set) => ({
  darkMode: localStorage.getItem('cobalt_dark_mode') !== 'false',
  toggleDarkMode: () =>
    set((state) => {
      const newMode = !state.darkMode;
      localStorage.setItem('cobalt_dark_mode', String(newMode));
      document.documentElement.classList.toggle('bp5-dark', newMode);
      return { darkMode: newMode };
    }),
}));
