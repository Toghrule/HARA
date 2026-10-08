import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { ChangeRequestDto, ChangeRequestStatus, ReviewChangeRequestBody } from "../../types";

const KEY = ["admin-change-requests"];

export function useChangeRequests(status: ChangeRequestStatus | "all") {
  return useQuery({
    queryKey: [...KEY, status],
    queryFn: () =>
      api.get<ChangeRequestDto[]>(`/api/admin/change-requests${status === "all" ? "" : `?status=${status}`}`),
    // Owners send requests while the page is open.
    refetchInterval: 30_000,
  });
}

export function useReviewChangeRequest() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: ReviewChangeRequestBody }) =>
      api.patch<ChangeRequestDto>(`/api/admin/change-requests/${id}/status`, body),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: KEY });
      // An approved request changes the restaurant itself.
      queryClient.invalidateQueries({ queryKey: ["admin-restaurants"] });
    },
  });
}
