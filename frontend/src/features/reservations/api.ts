import { useQuery } from "@tanstack/react-query";
import { api } from "../../lib/api";
import type { ReservationDto, ReservationStatus } from "../../types";

const KEY = ["admin-reservations"];

export function useReservations(code: string, status: ReservationStatus | "all") {
  const params = new URLSearchParams();
  if (code) params.set("code", code);
  if (status !== "all") params.set("status", String(status));
  const query = params.toString();

  return useQuery({
    queryKey: [...KEY, code, status],
    queryFn: () => api.get<ReservationDto[]>(`/api/admin/reservations${query ? `?${query}` : ""}`),
    // Active reservations expire on their own and restaurants confirm them, so keep the list fresh while it's open.
    refetchInterval: 30_000,
  });
}
