import { useMemo, useState } from "react";
import { ArrowDownAZ, ArrowUpZA, Pencil, Plus, Trash2 } from "lucide-react";
import { PageHeader } from "../../components/ui/PageHeader";
import { Button } from "../../components/ui/Button";
import { Badge } from "../../components/ui/Badge";
import { Spinner } from "../../components/ui/Spinner";
import { EmptyState } from "../../components/ui/EmptyState";
import { ConfirmDialog } from "../../components/ui/ConfirmDialog";
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { useDeleteRestaurant, useRestaurants } from "./api";
import { RestaurantFormDialog } from "./RestaurantFormDialog";
import type { RestaurantDto } from "../../types";

export function RestaurantsPage() {
  const { data, isLoading } = useRestaurants();
  const deleteMutation = useDeleteRestaurant();
  const { push } = useToast();
  const [formState, setFormState] = useState<{ open: boolean; restaurant: RestaurantDto | null }>({
    open: false,
    restaurant: null,
  });
  const [pendingDelete, setPendingDelete] = useState<RestaurantDto | null>(null);
  const [sortDirection, setSortDirection] = useState<"asc" | "desc">("asc");

  const sorted = useMemo(() => {
    if (!data) return data;
    const copy = [...data].sort((a, b) => a.name.localeCompare(b.name));
    return sortDirection === "asc" ? copy : copy.reverse();
  }, [data, sortDirection]);

  const handleDelete = async () => {
    if (!pendingDelete) return;
    try {
      await deleteMutation.mutateAsync(pendingDelete.id);
      push("Restaurant deleted");
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Failed to delete restaurant", "error");
    } finally {
      setPendingDelete(null);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Restaurants"
        description="Venues shown to mobile app users."
        action={
          <div className="flex items-center gap-2">
            <Button
              type="button"
              variant="secondary"
              onClick={() => setSortDirection((d) => (d === "asc" ? "desc" : "asc"))}
              title={sortDirection === "asc" ? "Sorted A to Z" : "Sorted Z to A"}
            >
              {sortDirection === "asc" ? <ArrowDownAZ className="h-4 w-4" /> : <ArrowUpZA className="h-4 w-4" />}
              Name
            </Button>
            <Button onClick={() => setFormState({ open: true, restaurant: null })}>
              <Plus className="h-4 w-4" />
              Add restaurant
            </Button>
          </div>
        }
      />

      {isLoading ? (
        <Spinner />
      ) : !sorted?.length ? (
        <EmptyState message="No restaurants yet." />
      ) : (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase text-slate-500">
              <tr>
                <th className="px-4 py-3">Name</th>
                <th className="px-4 py-3">Address</th>
                <th className="px-4 py-3">Phone</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {sorted.map((restaurant) => (
                <tr key={restaurant.id}>
                  <td className="px-4 py-3 font-medium text-slate-900">{restaurant.name}</td>
                  <td className="px-4 py-3 text-slate-600">{restaurant.address}</td>
                  <td className="px-4 py-3 text-slate-600">{restaurant.phoneNumber ?? "—"}</td>
                  <td className="px-4 py-3">
                    <Badge variant={restaurant.isActive ? "success" : "neutral"}>
                      {restaurant.isActive ? "Active" : "Inactive"}
                    </Badge>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex justify-end gap-2">
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        onClick={() => setFormState({ open: true, restaurant })}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button type="button" variant="ghost" size="sm" onClick={() => setPendingDelete(restaurant)}>
                        <Trash2 className="h-4 w-4 text-red-600" />
                      </Button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <RestaurantFormDialog
        open={formState.open}
        onClose={() => setFormState({ open: false, restaurant: null })}
        restaurant={formState.restaurant}
      />
      <ConfirmDialog
        open={pendingDelete !== null}
        title="Delete restaurant"
        message={`Delete "${pendingDelete?.name}"? This cannot be undone.`}
        confirmLabel="Delete"
        isLoading={deleteMutation.isPending}
        onCancel={() => setPendingDelete(null)}
        onConfirm={handleDelete}
      />
    </div>
  );
}
