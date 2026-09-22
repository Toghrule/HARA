import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { RestaurantSubmissionDto, ReviewSubmissionBody, SubmissionStatus } from "../../types";

const KEY = ["admin-submissions"];

export function useSubmissions(status: SubmissionStatus | "all") {
  return useQuery({
    queryKey: [...KEY, status],
    queryFn: () =>
      api.get<RestaurantSubmissionDto[]>(
        `/api/admin/submissions${status === "all" ? "" : `?status=${status}`}`
      ),
  });
}

export function useReviewSubmission() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: ReviewSubmissionBody }) =>
      api.patch<RestaurantSubmissionDto>(`/api/admin/submissions/${id}/status`, body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}

export function useDeleteSubmission() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/api/admin/submissions/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}
