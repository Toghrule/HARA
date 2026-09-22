import { useState } from "react";
import { Check, Trash2, X } from "lucide-react";
import { PageHeader } from "../../components/ui/PageHeader";
import { Button } from "../../components/ui/Button";
import { Badge } from "../../components/ui/Badge";
import { Spinner } from "../../components/ui/Spinner";
import { EmptyState } from "../../components/ui/EmptyState";
import { ConfirmDialog } from "../../components/ui/ConfirmDialog";
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { cn, formatDate } from "../../lib/utils";
import { submissionStatusBadgeVariant, submissionStatusLabels } from "../../lib/enumLabels";
import { useDeleteSubmission, useSubmissions } from "./api";
import { SubmissionReviewDialog } from "./SubmissionReviewDialog";
import { SubmissionStatus } from "../../types";
import type { RestaurantSubmissionDto } from "../../types";

const tabs: { label: string; value: SubmissionStatus | "all" }[] = [
  { label: "All", value: "all" },
  { label: "Pending", value: SubmissionStatus.Pending },
  { label: "Approved", value: SubmissionStatus.Approved },
  { label: "Rejected", value: SubmissionStatus.Rejected },
];

export function SubmissionsPage() {
  const [activeTab, setActiveTab] = useState<SubmissionStatus | "all">(SubmissionStatus.Pending);
  const { data, isLoading } = useSubmissions(activeTab);
  const deleteMutation = useDeleteSubmission();
  const { push } = useToast();

  const [reviewTarget, setReviewTarget] = useState<{
    submission: RestaurantSubmissionDto;
    decision: SubmissionStatus.Approved | SubmissionStatus.Rejected;
  } | null>(null);
  const [pendingDelete, setPendingDelete] = useState<RestaurantSubmissionDto | null>(null);

  const handleDelete = async () => {
    if (!pendingDelete) return;
    try {
      await deleteMutation.mutateAsync(pendingDelete.id);
      push("Submission deleted");
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Failed to delete submission", "error");
    } finally {
      setPendingDelete(null);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader title="Submissions" description="Restaurants suggested by mobile app users." />

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
        <EmptyState message="No submissions here." />
      ) : (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase text-slate-500">
              <tr>
                <th className="px-4 py-3">Restaurant</th>
                <th className="px-4 py-3">Submitter</th>
                <th className="px-4 py-3">Submitted</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {data.map((submission) => (
                <tr key={submission.id}>
                  <td className="px-4 py-3">
                    <p className="font-medium text-slate-900">{submission.restaurantName}</p>
                    <p className="text-xs text-slate-500">{submission.address ?? "No address given"}</p>
                    {submission.adminNote && (
                      <p className="mt-1 text-xs italic text-slate-400">Note: {submission.adminNote}</p>
                    )}
                  </td>
                  <td className="px-4 py-3 text-slate-600">
                    <p>{submission.submitterName}</p>
                    <p className="text-xs text-slate-400">
                      {submission.submitterEmail ?? submission.submitterPhoneNumber ?? "—"}
                    </p>
                  </td>
                  <td className="px-4 py-3 text-slate-600">{formatDate(submission.createdAt)}</td>
                  <td className="px-4 py-3">
                    <Badge variant={submissionStatusBadgeVariant[submission.status]}>
                      {submissionStatusLabels[submission.status]}
                    </Badge>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex justify-end gap-2">
                      {submission.status === SubmissionStatus.Pending && (
                        <>
                          <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={() => setReviewTarget({ submission, decision: SubmissionStatus.Approved })}
                          >
                            <Check className="h-4 w-4 text-emerald-600" />
                          </Button>
                          <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={() => setReviewTarget({ submission, decision: SubmissionStatus.Rejected })}
                          >
                            <X className="h-4 w-4 text-red-600" />
                          </Button>
                        </>
                      )}
                      <Button type="button" variant="ghost" size="sm" onClick={() => setPendingDelete(submission)}>
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

      <SubmissionReviewDialog
        submission={reviewTarget?.submission ?? null}
        decision={reviewTarget?.decision ?? null}
        onClose={() => setReviewTarget(null)}
      />
      <ConfirmDialog
        open={pendingDelete !== null}
        title="Delete submission"
        message={`Delete the submission for "${pendingDelete?.restaurantName}"? This cannot be undone.`}
        confirmLabel="Delete"
        isLoading={deleteMutation.isPending}
        onCancel={() => setPendingDelete(null)}
        onConfirm={handleDelete}
      />
    </div>
  );
}
