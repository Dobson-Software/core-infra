import { useMutation, useQueryClient } from '@tanstack/react-query';
import { authApi } from '@cobalt/api-client';
import type { LoginRequest } from '@cobalt/api-client';

export function useLogin() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: LoginRequest) => authApi.login(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['auth', 'me'] });
    },
  });
}
