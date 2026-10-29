import { useState } from "react";
import { Check, X } from "lucide-react";
import { PageHeader } from "../../components/ui/PageHeader";
import { Button } from "../../components/ui/Button";
import { Badge } from "../../components/ui/Badge";
import { Dialog } from "../../components/ui/Dialog";
import { Spinner } from "../../components/ui/Spinner";
import { EmptyState } from "../../components/ui/EmptyState";
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { cn, formatDate } from "../../lib/utils";
import { useDecidePasswordReset, usePasswordResets } from "./api";
import { PasswordResetStatus } from "../../types";
import type { PasswordResetRequestDto } from "../../types";

const tabs: { label: string; value: PasswordResetStatus | "all" }[] = [
  { label: "Waiting", value: PasswordResetStatus.Pending },
  { label: "Approved", value: PasswordResetStatus.Approved },
  { label: "All", value: "all" },
];

const statusLabels: Record<PasswordResetStatus, string> = {
  [PasswordResetStatus.Pending]: "Waiting",
  [PasswordResetStatus.Approved]: "Approved",
  [PasswordResetStatus.Rejected]: "Declined",
  [PasswordResetStatus.Completed]: "Password changed",
  [PasswordResetStatus.Expired]: "Expired",
};

const statusVariants: Record<PasswordResetStatus, "success" | "neutral" | "warning" | "danger"> = {
  [PasswordResetStatus.Pending]: "warning",
  [PasswordResetStatus.Approved]: "success",
  [PasswordResetStatus.Rejected]: "danger",
  [PasswordResetStatus.Completed]: "neutral",
  [PasswordResetStatus.Expired]: "neutral",
};

export function PasswordResetsPage() {
  const [activeTab, setActiveTab] = useState<PasswordResetStatus | "all">(PasswordResetStatus.Pending);
  const { data, isLoading } = usePasswordResets(activeTab);
  const decide = useDecidePasswordReset();
  const { push } = useToast();
  const [target, setTarget] = useState<{ request: PasswordResetRequestDto; approve: boolean } | null>(null);

  const handleDecide = async () => {
    if (!target) return;
    try {
      await decide.mutateAsync({ id: target.request.id, approve: target.approve });
      push(target.approve ? "Approved. The owner can set a new password now." : "Declined");
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Could not save the decision", "error");
    } finally {
      setTarget(null);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Password resets"
        description="Owners who forgot their password. Call the owner on the number shown and make sure it is really them before approving: once approved, their phone opens a form for a new password for one hour."
      />

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
        <EmptyState message="No requests here." />
      ) : (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase text-slate-500">
              <tr>
                <th className="px-4 py-3">Owner</th>
                <th className="px-4 py-3">Restaurant</th>
                <th className="px-4 py-3">Asked</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {data.map((request) => (
                <tr key={request.id}>
                  <td className="px-4 py-3">
                    <p className="font-medium text-slate-900">{request.ownerName ?? "—"}</p>
                    <p className="text-xs text-slate-500">{request.email}</p>
                    <p className="text-xs text-slate-500">{request.phoneNumber ?? "No phone number on file"}</p>
                  </td>
                  <td className="px-4 py-3 text-slate-600">{request.restaurantName ?? "—"}</td>
                  <td className="px-4 py-3 text-slate-600">{formatDate(request.createdAt)}</td>
                  <td className="px-4 py-3">
                    <Badge variant={statusVariants[request.status]}>{statusLabels[request.status]}</Badge>
                    {request.status === PasswordResetStatus.Approved && request.expiresAt && (
                      <p className="mt-1 text-xs text-slate-400">Until {formatDate(request.expiresAt)}</p>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {request.status === PasswordResetStatus.Pending && (
                      <div className="flex justify-end gap-2">
                        <Button type="button" variant="secondary" size="sm" onClick={() => setTarget({ request, approve: true })}>
                          <Check className="h-4 w-4 text-emerald-600" />
                          Approve
                        </Button>
                        <Button type="button" variant="ghost" size="sm" onClick={() => setTarget({ request, approve: false })}>
                          <X className="h-4 w-4 text-red-600" />
                          Decline
                        </Button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <Dialog
        open={target !== null}
        onClose={() => setTarget(null)}
        title={target?.approve ? "Approve the password reset?" : "Decline the password reset?"}
      >
        <p className="text-sm text-slate-600">
          {target?.approve
            ? `Only approve after you have talked to ${target.request.ownerName ?? "the owner"} (${target.request.phoneNumber ?? "no phone on file"}) and are sure it is them. Their app will then ask for a new password for the next hour.`
            : "The owner is told the request was declined and can ask again."}
        </p>
        <div className="mt-6 flex justify-end gap-2">
          <Button type="button" variant="secondary" onClick={() => setTarget(null)}>
            Cancel
          </Button>
          <Button
            type="button"
            variant={target?.approve ? "primary" : "danger"}
            onClick={handleDecide}
            disabled={decide.isPending}
          >
            {target?.approve ? "Approve" : "Decline"}
          </Button>
        </div>
      </Dialog>
    </div>
  );
}
