import { useQuery } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { RestaurantStatsDto } from "../../types";

export function useRestaurantStats() {
  return useQuery({
    queryKey: ["admin-restaurant-stats"],
    queryFn: () => api.get<RestaurantStatsDto[]>("/api/admin/stats/restaurants"),
    // Numbers move while requests are answered and codes confirmed, so keep them fresh while the page is open.
    refetchInterval: 60_000,
  });
}
