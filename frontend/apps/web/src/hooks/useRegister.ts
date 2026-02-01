import { useMutation, useQueryClient } from '@tanstack/react-query';
import { authApi } from '@cobalt/api-client';
import type { RegisterRequest } from '@cobalt/api-client';

export function useRegister() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: RegisterRequest) => authApi.register(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['auth', 'me'] });
    },
  });
}
