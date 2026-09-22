import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { AboutUsDto, UpdateAboutUsBody } from "../../types";

const KEY = ["admin-about-us"];

export function useAboutUs() {
  return useQuery({
    queryKey: KEY,
    queryFn: () => api.get<AboutUsDto>("/api/admin/company-info/about"),
  });
}

export function useUpdateAboutUs() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (body: UpdateAboutUsBody) => api.put<AboutUsDto>("/api/admin/company-info/about", body),
    onSuccess: (data) => queryClient.setQueryData(KEY, data),
  });
}
