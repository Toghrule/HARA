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
import { contactTypeLabels } from "../../lib/enumLabels";
import { useContacts, useDeleteContact } from "./contactsApi";
import { ContactFormDialog } from "./ContactFormDialog";
import type { ContactInfoDto } from "../../types";

export function ContactsPage() {
  const { data, isLoading } = useContacts();
  const deleteMutation = useDeleteContact();
  const { push } = useToast();
  const [formState, setFormState] = useState<{ open: boolean; contact: ContactInfoDto | null }>({
    open: false,
    contact: null,
  });
  const [pendingDelete, setPendingDelete] = useState<ContactInfoDto | null>(null);

  const sorted = useMemo(() => [...(data ?? [])].sort((a, b) => a.sortOrder - b.sortOrder), [data]);

  const handleDelete = async () => {
    if (!pendingDelete) return;
    try {
      await deleteMutation.mutateAsync(pendingDelete.id);
      push("Contact deleted");
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Failed to delete contact", "error");
    } finally {
      setPendingDelete(null);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Contacts"
        description="Phone numbers and email addresses shown on the Contact Us screen."
        action={
          <Button onClick={() => setFormState({ open: true, contact: null })}>
            <Plus className="h-4 w-4" />
            Add contact
          </Button>
        }
      />

      {isLoading ? (
        <Spinner />
      ) : !sorted.length ? (
        <EmptyState message="No contacts yet." />
      ) : (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase text-slate-500">
              <tr>
                <th className="px-4 py-3">Type</th>
                <th className="px-4 py-3">Value</th>
                <th className="px-4 py-3">Label</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {sorted.map((contact) => (
                <tr key={contact.id}>
                  <td className="px-4 py-3 text-slate-600">{contactTypeLabels[contact.type]}</td>
                  <td className="px-4 py-3 font-medium text-slate-900">{contact.value}</td>
                  <td className="px-4 py-3 text-slate-600">{contact.label ?? "—"}</td>
                  <td className="px-4 py-3">
                    <Badge variant={contact.isActive ? "success" : "neutral"}>
                      {contact.isActive ? "Active" : "Inactive"}
                    </Badge>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex justify-end gap-2">
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        onClick={() => setFormState({ open: true, contact })}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button type="button" variant="ghost" size="sm" onClick={() => setPendingDelete(contact)}>
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

      <ContactFormDialog
        open={formState.open}
        onClose={() => setFormState({ open: false, contact: null })}
        contact={formState.contact}
        nextSortOrder={sorted.length}
      />
      <ConfirmDialog
        open={pendingDelete !== null}
        title="Delete contact"
        message={`Delete "${pendingDelete?.value}"? This cannot be undone.`}
        confirmLabel="Delete"
        isLoading={deleteMutation.isPending}
        onCancel={() => setPendingDelete(null)}
        onConfirm={handleDelete}
      />
    </div>
  );
}
