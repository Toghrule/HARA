import { useMemo, useState } from "react";
import { Pencil, Plus, Trash2 } from "lucide-react";
import { PageHeader } from "../../components/ui/PageHeader";
import { Button } from "../../components/ui/Button";
import { Badge } from "../../components/ui/Badge";
import { Spinner } from "../../components/ui/Spinner";
import { EmptyState } from "../../components/ui/EmptyState";
import { ConfirmDialog } from "../../components/ui/ConfirmDialog";
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { socialPlatformLabels } from "../../lib/enumLabels";
import { useDeleteSocialLink, useSocialLinks } from "./socialLinksApi";
import { SocialLinkFormDialog } from "./SocialLinkFormDialog";
import type { SocialMediaLinkDto } from "../../types";

export function SocialLinksPage() {
  const { data, isLoading } = useSocialLinks();
  const deleteMutation = useDeleteSocialLink();
  const { push } = useToast();
  const [formState, setFormState] = useState<{ open: boolean; link: SocialMediaLinkDto | null }>({
    open: false,
    link: null,
  });
  const [pendingDelete, setPendingDelete] = useState<SocialMediaLinkDto | null>(null);

  const sorted = useMemo(() => [...(data ?? [])].sort((a, b) => a.sortOrder - b.sortOrder), [data]);

  const handleDelete = async () => {
    if (!pendingDelete) return;
    try {
      await deleteMutation.mutateAsync(pendingDelete.id);
      push("Social link deleted");
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Failed to delete social link", "error");
    } finally {
      setPendingDelete(null);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Social Links"
        description="Social media links shown on the About Us screen."
        action={
          <Button onClick={() => setFormState({ open: true, link: null })}>
            <Plus className="h-4 w-4" />
            Add social link
          </Button>
        }
      />

      {isLoading ? (
        <Spinner />
      ) : !sorted.length ? (
        <EmptyState message="No social links yet." />
      ) : (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase text-slate-500">
              <tr>
                <th className="px-4 py-3">Platform</th>
                <th className="px-4 py-3">URL</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {sorted.map((link) => (
                <tr key={link.id}>
                  <td className="px-4 py-3 font-medium text-slate-900">{socialPlatformLabels[link.platform]}</td>
                  <td className="max-w-[320px] truncate px-4 py-3 text-slate-600">{link.url}</td>
                  <td className="px-4 py-3">
                    <Badge variant={link.isActive ? "success" : "neutral"}>
                      {link.isActive ? "Active" : "Inactive"}
                    </Badge>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex justify-end gap-2">
                      <Button type="button" variant="ghost" size="sm" onClick={() => setFormState({ open: true, link })}>
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button type="button" variant="ghost" size="sm" onClick={() => setPendingDelete(link)}>
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

      <SocialLinkFormDialog
        open={formState.open}
        onClose={() => setFormState({ open: false, link: null })}
        link={formState.link}
        nextSortOrder={sorted.length}
      />
      <ConfirmDialog
        open={pendingDelete !== null}
        title="Delete social link"
        message={`Delete this ${socialPlatformLabels[pendingDelete?.platform ?? 0]} link? This cannot be undone.`}
        confirmLabel="Delete"
        isLoading={deleteMutation.isPending}
        onCancel={() => setPendingDelete(null)}
        onConfirm={handleDelete}
      />
    </div>
  );
}
