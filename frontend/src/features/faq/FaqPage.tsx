import { useMemo, useState } from "react";
import { ChevronDown, ChevronUp, Pencil, Plus, Trash2 } from "lucide-react";
import { PageHeader } from "../../components/ui/PageHeader";
import { Button } from "../../components/ui/Button";
import { Badge } from "../../components/ui/Badge";
import { Spinner } from "../../components/ui/Spinner";
import { EmptyState } from "../../components/ui/EmptyState";
import { ConfirmDialog } from "../../components/ui/ConfirmDialog";
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { useDeleteFaqItem, useFaqItems, useReorderFaqItems } from "./api";
import { FaqFormDialog } from "./FaqFormDialog";
import type { FaqItemDto } from "../../types";

export function FaqPage() {
  const { data, isLoading } = useFaqItems();
  const deleteMutation = useDeleteFaqItem();
  const reorderMutation = useReorderFaqItems();
  const { push } = useToast();
  const [formState, setFormState] = useState<{ open: boolean; faqItem: FaqItemDto | null }>({
    open: false,
    faqItem: null,
  });
  const [pendingDelete, setPendingDelete] = useState<FaqItemDto | null>(null);

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
      push("FAQ entry deleted");
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Failed to delete FAQ entry", "error");
    } finally {
      setPendingDelete(null);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="FAQ"
        description="Frequently asked questions shown in the mobile app. Use the arrows to reorder."
        action={
          <Button onClick={() => setFormState({ open: true, faqItem: null })}>
            <Plus className="h-4 w-4" />
            Add FAQ entry
          </Button>
        }
      />

      {isLoading ? (
        <Spinner />
      ) : !sorted.length ? (
        <EmptyState message="No FAQ entries yet." />
      ) : (
        <div className="space-y-3">
          {sorted.map((faqItem, index) => (
            <div key={faqItem.id} className="rounded-lg border border-slate-200 bg-white p-4">
              <div className="flex items-start gap-3">
                <div className="flex flex-col gap-1 pt-1">
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
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <p className="font-medium text-slate-900">{faqItem.question}</p>
                    <Badge variant={faqItem.isActive ? "success" : "neutral"}>
                      {faqItem.isActive ? "Active" : "Inactive"}
                    </Badge>
                  </div>
                  <p className="mt-1 whitespace-pre-line text-sm text-slate-600">{faqItem.answer}</p>
                </div>
                <div className="flex gap-2">
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => setFormState({ open: true, faqItem })}
                  >
                    <Pencil className="h-4 w-4" />
                  </Button>
                  <Button type="button" variant="ghost" size="sm" onClick={() => setPendingDelete(faqItem)}>
                    <Trash2 className="h-4 w-4 text-red-600" />
                  </Button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <FaqFormDialog
        open={formState.open}
        onClose={() => setFormState({ open: false, faqItem: null })}
        faqItem={formState.faqItem}
        nextSortOrder={sorted.length}
      />
      <ConfirmDialog
        open={pendingDelete !== null}
        title="Delete FAQ entry"
        message="Delete this FAQ entry? This cannot be undone."
        confirmLabel="Delete"
        isLoading={deleteMutation.isPending}
        onCancel={() => setPendingDelete(null)}
        onConfirm={handleDelete}
      />
    </div>
  );
}
