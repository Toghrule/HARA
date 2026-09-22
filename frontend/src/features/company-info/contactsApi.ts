import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { ContactInfoDto, CreateContactInfoBody, UpdateContactInfoBody } from "../../types";

const KEY = ["admin-contacts"];

export function useContacts() {
  return useQuery({
    queryKey: KEY,
    queryFn: () => api.get<ContactInfoDto[]>("/api/admin/company-info/contacts"),
  });
}

export function useCreateContact() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (body: CreateContactInfoBody) => api.post<ContactInfoDto>("/api/admin/company-info/contacts", body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}

export function useUpdateContact() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: UpdateContactInfoBody }) =>
      api.put<ContactInfoDto>(`/api/admin/company-info/contacts/${id}`, body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}

export function useDeleteContact() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/api/admin/company-info/contacts/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}
