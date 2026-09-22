import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { AdvertisementDto, CreateAdvertisementBody, UpdateAdvertisementBody } from "../../types";

const KEY = ["admin-advertisements"];

export function useAdvertisements() {
  return useQuery({
    queryKey: KEY,
    queryFn: () => api.get<AdvertisementDto[]>("/api/admin/advertisements"),
  });
}

export function useCreateAdvertisement() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (body: CreateAdvertisementBody) => api.post<AdvertisementDto>("/api/admin/advertisements", body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}

export function useUpdateAdvertisement() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: UpdateAdvertisementBody }) =>
      api.put<AdvertisementDto>(`/api/admin/advertisements/${id}`, body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}

export function useDeleteAdvertisement() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/api/admin/advertisements/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}

export function useReorderAdvertisements() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (orderedIds: string[]) => api.patch<void>("/api/admin/advertisements/reorder", { orderedIds }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}
