import React, { createContext, useContext, useCallback } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { authApi, clearTokens, getAccessToken } from '@cobalt/api-client';
import type { User } from '@cobalt/api-client';

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  isAuthenticated: false,
  isLoading: true,
  logout: () => {},
});

export function useAuth() {
  return useContext(AuthContext);
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const queryClient = useQueryClient();

  const { data: user, isLoading } = useQuery({
    queryKey: ['auth', 'me'],
    queryFn: authApi.me,
    enabled: !!getAccessToken(),
    retry: false,
  });

  const logout = useCallback(() => {
    authApi.logout().finally(() => {
      queryClient.clear();
      clearTokens();
      window.location.href = '/login';
    });
  }, [queryClient]);

  return (
    <AuthContext.Provider
      value={{
        user: user ?? null,
        isAuthenticated: !!user,
        isLoading: isLoading && !!getAccessToken(),
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}
