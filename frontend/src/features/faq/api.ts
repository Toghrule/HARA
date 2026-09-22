import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { CreateFaqItemBody, FaqItemDto, UpdateFaqItemBody } from "../../types";

const KEY = ["admin-faq"];

export function useFaqItems() {
  return useQuery({
    queryKey: KEY,
    queryFn: () => api.get<FaqItemDto[]>("/api/admin/faq"),
  });
}

export function useCreateFaqItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (body: CreateFaqItemBody) => api.post<FaqItemDto>("/api/admin/faq", body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}

export function useUpdateFaqItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: UpdateFaqItemBody }) =>
      api.put<FaqItemDto>(`/api/admin/faq/${id}`, body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}

export function useDeleteFaqItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/api/admin/faq/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}

export function useReorderFaqItems() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (orderedIds: string[]) => api.patch<void>("/api/admin/faq/reorder", { orderedIds }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}
