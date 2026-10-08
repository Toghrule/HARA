import { useEffect, useState } from "react";
import { Search } from "lucide-react";
import { PageHeader } from "../../components/ui/PageHeader";
import { Badge } from "../../components/ui/Badge";
import { Input } from "../../components/ui/Input";
import { Spinner } from "../../components/ui/Spinner";
import { EmptyState } from "../../components/ui/EmptyState";
import { cn, formatDate } from "../../lib/utils";
import { reservationStatusBadgeVariant, reservationStatusLabels } from "../../lib/enumLabels";
import { useReservations } from "./api";
import { ReservationStatus } from "../../types";

const tabs: { label: string; value: ReservationStatus | "all" }[] = [
  { label: "All", value: "all" },
  { label: "Active", value: ReservationStatus.Active },
  { label: "Redeemed", value: ReservationStatus.Redeemed },
  { label: "Expired", value: ReservationStatus.Expired },
  { label: "Cancelled", value: ReservationStatus.Cancelled },
];

export function ReservationsPage() {
  const [activeTab, setActiveTab] = useState<ReservationStatus | "all">(ReservationStatus.Active);
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const { data, isLoading } = useReservations(debouncedSearch, activeTab);

  useEffect(() => {
    const handle = setTimeout(() => setDebouncedSearch(search.trim()), 300);
    return () => clearTimeout(handle);
  }, [search]);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Reservations"
        description="Table reservations made in the mobile app. Read-only: each restaurant's owner or waiters confirm the codes themselves in the app."
      />

      <div className="relative max-w-sm">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
        <Input
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          placeholder="Search by code"
          className="pl-9 font-mono uppercase placeholder:font-sans placeholder:normal-case"
          autoComplete="off"
        />
      </div>

      <div className="flex gap-1 border-b border-slate-200">
        {tabs.map((tab) => (
          <button
            key={tab.label}
            type="button"
            onClick={() => setActiveTab(tab.value)}
            className={cn(
              "border-b-2 px-3 py-2 text-sm font-medium transition-colors",
              activeTab === tab.value
                ? "border-slate-900 text-slate-900"
                : "border-transparent text-slate-500 hover:text-slate-800"
            )}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {isLoading ? (
        <Spinner />
      ) : !data?.length ? (
        <EmptyState message="No reservations here." />
      ) : (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase text-slate-500">
              <tr>
                <th className="px-4 py-3">Code</th>
                <th className="px-4 py-3">Restaurant</th>
                <th className="px-4 py-3">Phone</th>
                <th className="px-4 py-3">Reserved</th>
                <th className="px-4 py-3">Valid until</th>
                <th className="px-4 py-3">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {data.map((reservation) => (
                <tr key={reservation.id}>
                  <td className="px-4 py-3 font-mono text-base font-semibold tracking-wider text-slate-900">
                    {reservation.code}
                  </td>
                  <td className="px-4 py-3">
                    <p className="font-medium text-slate-900">{reservation.restaurantName}</p>
                    <p className="text-xs text-slate-500">
                      {reservation.discountPercent > 0 ? `${reservation.discountPercent}% discount` : "No discount"}
                    </p>
                  </td>
                  <td className="px-4 py-3 text-slate-600">{reservation.phoneNumber}</td>
                  <td className="px-4 py-3 text-slate-600">
                    {formatDate(reservation.createdAt)}
                    <p className="text-xs text-slate-400">{reservation.durationMinutes} min</p>
                  </td>
                  <td className="px-4 py-3 text-slate-600">{formatDate(reservation.expiresAt)}</td>
                  <td className="px-4 py-3">
                    <Badge variant={reservationStatusBadgeVariant[reservation.status]}>
                      {reservationStatusLabels[reservation.status]}
                    </Badge>
                    {reservation.redeemedAt && (
                      <p className="mt-1 text-xs text-slate-400">{formatDate(reservation.redeemedAt)}</p>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
