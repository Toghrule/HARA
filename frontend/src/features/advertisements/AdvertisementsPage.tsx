import { useMemo, useState } from "react";
import { ChevronDown, ChevronUp, Pencil, Plus, Trash2 } from "lucide-react";
import { PageHeader } from "../../components/ui/PageHeader";
import { Button } from "../../components/ui/Button";
import { Badge } from "../../components/ui/Badge";
import { Spinner } from "../../components/ui/Spinner";
import { EmptyState } from "../../components/ui/EmptyState";
import { ConfirmDialog } from "../../components/ui/ConfirmDialog";
import { useToast } from "../../components/ui/Toast";
import { ApiError, resolveAssetUrl } from "../../lib/api";
import { useAdvertisements, useDeleteAdvertisement, useReorderAdvertisements } from "./api";
import { AdvertisementFormDialog } from "./AdvertisementFormDialog";
import type { AdvertisementDto } from "../../types";

export function AdvertisementsPage() {
  const { data, isLoading } = useAdvertisements();
  const deleteMutation = useDeleteAdvertisement();
  const reorderMutation = useReorderAdvertisements();
  const { push } = useToast();
  const [formState, setFormState] = useState<{ open: boolean; advertisement: AdvertisementDto | null }>({
    open: false,
    advertisement: null,
  });
  const [pendingDelete, setPendingDelete] = useState<AdvertisementDto | null>(null);

  const sorted = useMemo(() => [...(data ?? [])].sort((a, b) => a.sortOrder - b.sortOrder), [data]);

  const move = (index: number, direction: -1 | 1) => {
    const targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= sorted.length) return;
    const reordered = [...sorted];
    [reordered[index], reordered[targetIndex]] = [reordered[targetIndex], reordered[index]];
    reorderMutation.mutate(reordered.map((item) => item.id));
  };

  const handleDelete = async () => {
    if (!pendingDelete) return;
    try {
      await deleteMutation.mutateAsync(pendingDelete.id);
      push("Advertisement deleted");
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Failed to delete advertisement", "error");
    } finally {
      setPendingDelete(null);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Advertisements"
        description="Carousel ads shown in the mobile app. Use the arrows to reorder."
        action={
          <Button onClick={() => setFormState({ open: true, advertisement: null })}>
            <Plus className="h-4 w-4" />
            Add advertisement
          </Button>
        }
      />

      {isLoading ? (
        <Spinner />
      ) : !sorted.length ? (
        <EmptyState message="No advertisements yet." />
      ) : (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase text-slate-500">
              <tr>
                <th className="px-4 py-3">Order</th>
                <th className="px-4 py-3">Image</th>
                <th className="px-4 py-3">Title</th>
                <th className="px-4 py-3">Link</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {sorted.map((advertisement, index) => (
                <tr key={advertisement.id}>
                  <td className="px-4 py-3">
                    <div className="flex flex-col gap-1">
                      <button
                        type="button"
                        onClick={() => move(index, -1)}
                        disabled={index === 0}
                        className="text-slate-400 hover:text-slate-900 disabled:opacity-30"
                        aria-label="Move up"
                      >
                        <ChevronUp className="h-4 w-4" />
                      </button>
                      <button
                        type="button"
                        onClick={() => move(index, 1)}
                        disabled={index === sorted.length - 1}
                        className="text-slate-400 hover:text-slate-900 disabled:opacity-30"
                        aria-label="Move down"
                      >
                        <ChevronDown className="h-4 w-4" />
                      </button>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <img
                      src={resolveAssetUrl(advertisement.imageUrl)}
                      alt=""
                      className="h-12 w-20 rounded object-cover"
                    />
                  </td>
                  <td className="px-4 py-3 font-medium text-slate-900">{advertisement.title ?? "—"}</td>
                  <td className="max-w-[200px] truncate px-4 py-3 text-slate-600">{advertisement.linkUrl ?? "—"}</td>
                  <td className="px-4 py-3">
                    <Badge variant={advertisement.isActive ? "success" : "neutral"}>
                      {advertisement.isActive ? "Active" : "Inactive"}
                    </Badge>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex justify-end gap-2">
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        onClick={() => setFormState({ open: true, advertisement })}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button type="button" variant="ghost" size="sm" onClick={() => setPendingDelete(advertisement)}>
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

      <AdvertisementFormDialog
        open={formState.open}
        onClose={() => setFormState({ open: false, advertisement: null })}
        advertisement={formState.advertisement}
        nextSortOrder={sorted.length}
      />
      <ConfirmDialog
        open={pendingDelete !== null}
        title="Delete advertisement"
        message={`Delete "${pendingDelete?.title ?? "this advertisement"}"? This cannot be undone.`}
        confirmLabel="Delete"
        isLoading={deleteMutation.isPending}
        onCancel={() => setPendingDelete(null)}
        onConfirm={handleDelete}
      />
    </div>
  );
}
