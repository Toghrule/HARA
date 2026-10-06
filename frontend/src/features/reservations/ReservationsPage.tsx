import { useEffect, useState } from "react";
import { Check, Search } from "lucide-react";
import { PageHeader } from "../../components/ui/PageHeader";
import { Button } from "../../components/ui/Button";
import { Badge } from "../../components/ui/Badge";
import { Dialog } from "../../components/ui/Dialog";
import { Input } from "../../components/ui/Input";
import { Spinner } from "../../components/ui/Spinner";
import { EmptyState } from "../../components/ui/EmptyState";
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { cn, formatDate } from "../../lib/utils";
import { reservationStatusBadgeVariant, reservationStatusLabels } from "../../lib/enumLabels";
import { useRedeemReservation, useReservations } from "./api";
import { ReservationStatus } from "../../types";
import type { ReservationDto } from "../../types";

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
  const redeemMutation = useRedeemReservation();
  const { push } = useToast();
  const [pendingRedeem, setPendingRedeem] = useState<ReservationDto | null>(null);

  useEffect(() => {
    const handle = setTimeout(() => setDebouncedSearch(search.trim()), 300);
    return () => clearTimeout(handle);
  }, [search]);

  const handleRedeem = async () => {
    if (!pendingRedeem) return;
    try {
      await redeemMutation.mutateAsync(pendingRedeem.id);
      push(`Code ${pendingRedeem.code} redeemed`);
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Failed to redeem reservation", "error");
    } finally {
      setPendingRedeem(null);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Reservations"
        description="Table reservations made in the mobile app. Look up the code a customer shows and redeem it."
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
                <th className="px-4 py-3 text-right">Actions</th>
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
                  <td className="px-4 py-3">
                    <div className="flex justify-end">
                      {reservation.status === ReservationStatus.Active && (
                        <Button type="button" size="sm" onClick={() => setPendingRedeem(reservation)}>
                          <Check className="h-4 w-4" />
                          Redeem
                        </Button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <Dialog open={pendingRedeem !== null} onClose={() => setPendingRedeem(null)} title="Redeem reservation">
        <p className="text-sm text-slate-600">
          Confirm that the customer with code{" "}
          <span className="font-mono font-semibold text-slate-900">{pendingRedeem?.code}</span> has arrived at{" "}
          <span className="font-medium text-slate-900">{pendingRedeem?.restaurantName}</span>.
          {pendingRedeem && pendingRedeem.discountPercent > 0 && (
            <>
              {" "}
              Apply a <span className="font-semibold text-slate-900">{pendingRedeem.discountPercent}%</span> discount to
              their bill.
            </>
          )}{" "}
          A redeemed code cannot be used again.
        </p>
        <div className="mt-6 flex justify-end gap-2">
          <Button type="button" variant="secondary" onClick={() => setPendingRedeem(null)}>
            Cancel
          </Button>
          <Button type="button" onClick={handleRedeem} disabled={redeemMutation.isPending}>
            Redeem
          </Button>
        </div>
      </Dialog>
    </div>
  );
}
