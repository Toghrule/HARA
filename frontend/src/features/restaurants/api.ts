import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { CreateRestaurantBody, RestaurantDto, UpdateRestaurantBody } from "../../types";

const KEY = ["admin-restaurants"];

export function useRestaurants() {
  return useQuery({
    queryKey: KEY,
    queryFn: () => api.get<RestaurantDto[]>("/api/admin/restaurants"),
  });
}

export function useCreateRestaurant() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (body: CreateRestaurantBody) => api.post<RestaurantDto>("/api/admin/restaurants", body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}

export function useUpdateRestaurant() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: UpdateRestaurantBody }) =>
      api.put<RestaurantDto>(`/api/admin/restaurants/${id}`, body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}

export function useDeleteRestaurant() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/api/admin/restaurants/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: KEY }),
  });
}
