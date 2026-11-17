import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";

export interface AdminReview {
  id: string;
  restaurantId: string;
  restaurantName: string;
  stars: number;
  text: string | null;
  createdAt: string;
  authorName: string | null;
  authorEmail: string | null;
}

const KEY = ["admin-reviews"];

export function useReviews(page: number) {
  return useQuery({
    queryKey: [...KEY, page],
    queryFn: () => api.get<AdminReview[]>(`/api/admin/reviews?page=${page}&pageSize=50`),
    refetchInterval: 60_000,
  });
}

export function useDeleteReview() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/api/admin/reviews/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: KEY });
      // The restaurant's average changes with it.
      queryClient.invalidateQueries({ queryKey: ["admin-restaurants"] });
    },
  });
}
