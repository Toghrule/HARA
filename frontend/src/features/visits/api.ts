import { useQuery } from "@tanstack/react-query";
import { api } from "../../lib/api";

export interface VisitCounts {
  codesObtained: number;
  codesRedeemed: number;
  views: number;
  directions: number;
}

export interface RestaurantVisits {
  restaurantId: string;
  name: string;
  discountPercent: number;
  today: VisitCounts;
  thisWeek: VisitCounts;
  thisMonth: VisitCounts;
  total: VisitCounts;
}

export interface MonthlyVisits {
  restaurantId: string;
  name: string;
  discountPercent: number;
  counts: VisitCounts;
  uniqueViewers: number;
}

export function useVisits() {
  return useQuery({
    queryKey: ["admin-visits"],
    queryFn: () => api.get<RestaurantVisits[]>("/api/admin/visits"),
    // Customers tap all day, so keep the numbers fresh while the page is open.
    refetchInterval: 60_000,
  });
}

export function useMonthlyVisits(year: number, month: number) {
  return useQuery({
    queryKey: ["admin-visits-monthly", year, month],
    queryFn: () => api.get<MonthlyVisits[]>(`/api/admin/visits/monthly?year=${year}&month=${month}`),
  });
}
