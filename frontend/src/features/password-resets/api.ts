import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { PasswordResetRequestDto, PasswordResetStatus } from "../../types";

const KEY = ["admin-password-resets"];

export function usePasswordResets(status: PasswordResetStatus | "all") {
  return useQuery({
    queryKey: [...KEY, status],
    queryFn: () =>
      api.get<PasswordResetRequestDto[]>(`/api/admin/password-resets${status === "all" ? "" : `?status=${status}`}`),
    // An owner may be waiting for the answer, so keep the list fresh while it is open.
    refetchInterval: 15_000,
  });
}

export function useDecidePasswordReset() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, approve }: { id: string; approve: boolean }) =>
      api.post<PasswordResetRequestDto>(`/api/admin/password-resets/${id}/${approve ? "approve" : "reject"}`, {}),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}
