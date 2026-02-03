import { create } from 'zustand';

interface User {
  id: string;
  email: string;
  name: string;
}

interface AppState {
  user: User | null;
  sidebarCollapsed: boolean;
  activeSessionId: string | null;

  setUser: (user: User | null) => void;
  toggleSidebar: () => void;
  setActiveSessionId: (id: string | null) => void;
}

export const useAppStore = create<AppState>((set) => ({
  user: null,
  sidebarCollapsed: false,
  activeSessionId: null,

  setUser: (user) => set({ user }),
  toggleSidebar: () => set((state) => ({ sidebarCollapsed: !state.sidebarCollapsed })),
  setActiveSessionId: (id) => set({ activeSessionId: id }),
}));
