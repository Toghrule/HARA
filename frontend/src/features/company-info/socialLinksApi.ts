import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { CreateSocialMediaLinkBody, SocialMediaLinkDto, UpdateSocialMediaLinkBody } from "../../types";

const KEY = ["admin-social-links"];

export function useSocialLinks() {
  return useQuery({
    queryKey: KEY,
    queryFn: () => api.get<SocialMediaLinkDto[]>("/api/admin/company-info/social-links"),
  });
}

export function useCreateSocialLink() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (body: CreateSocialMediaLinkBody) =>
      api.post<SocialMediaLinkDto>("/api/admin/company-info/social-links", body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}

export function useUpdateSocialLink() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: UpdateSocialMediaLinkBody }) =>
      api.put<SocialMediaLinkDto>(`/api/admin/company-info/social-links/${id}`, body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}

export function useDeleteSocialLink() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/api/admin/company-info/social-links/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}
