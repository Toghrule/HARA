import { useState } from "react";
import { Check, X } from "lucide-react";
import { PageHeader } from "../../components/ui/PageHeader";
import { Button } from "../../components/ui/Button";
import { Badge } from "../../components/ui/Badge";
import { Spinner } from "../../components/ui/Spinner";
import { EmptyState } from "../../components/ui/EmptyState";
import { cn, formatDate } from "../../lib/utils";
import { changeRequestStatusBadgeVariant, changeRequestStatusLabels } from "../../lib/enumLabels";
import { useChangeRequests } from "./api";
import { ChangeRequestReviewDialog } from "./ChangeRequestReviewDialog";
import { ChangeRequestStatus } from "../../types";
import type { ChangeRequestDto } from "../../types";

const tabs: { label: string; value: ChangeRequestStatus | "all" }[] = [
  { label: "Pending", value: ChangeRequestStatus.Pending },
  { label: "Approved", value: ChangeRequestStatus.Approved },
  { label: "Rejected", value: ChangeRequestStatus.Rejected },
  { label: "All", value: "all" },
];

interface Change {
  label: string;
  current: string;
  requested: string;
}

/** One line per field the owner wants changed. An empty requested text means "remove it". */
function changesOf(request: ChangeRequestDto): Change[] {
  const text = (value: string | null) => (value && value.length > 0 ? value : "—");
  const changes: Change[] = [];

  if (request.name !== null) changes.push({ label: "Name", current: request.current.name, requested: request.name });
  if (request.address !== null) {
    changes.push({ label: "Address", current: request.current.address, requested: request.address });
  }
  if (request.phoneNumber !== null) {
    changes.push({ label: "Phone", current: text(request.current.phoneNumber), requested: text(request.phoneNumber) });
  }
  if (request.discountPercent !== null) {
    changes.push({
      label: "Discount",
      current: `${request.current.discountPercent}%`,
      requested: `${request.discountPercent}%`,
    });
  }
  if (request.description !== null) {
    changes.push({ label: "Description (AZ)", current: text(request.current.description), requested: text(request.description) });
  }
  if (request.descriptionRu !== null) {
    changes.push({ label: "Description (RU)", current: text(request.current.descriptionRu), requested: text(request.descriptionRu) });
  }
  if (request.descriptionEn !== null) {
    changes.push({ label: "Description (EN)", current: text(request.current.descriptionEn), requested: text(request.descriptionEn) });
  }

  return changes;
}

export function ChangeRequestsPage() {
  const [activeTab, setActiveTab] = useState<ChangeRequestStatus | "all">(ChangeRequestStatus.Pending);
  const { data, isLoading } = useChangeRequests(activeTab);
  const [reviewTarget, setReviewTarget] = useState<{
    request: ChangeRequestDto;
    decision: ChangeRequestStatus.Approved | ChangeRequestStatus.Rejected;
  } | null>(null);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Change requests"
        description="Restaurant owners can't edit their restaurant themselves. They ask here, and approving applies the changes."
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
        <EmptyState message="No change requests here." />
      ) : (
        <div className="space-y-4">
          {data.map((request) => (
            <div key={request.id} className="rounded-lg border border-slate-200 bg-white p-5">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="font-medium text-slate-900">{request.restaurantName}</p>
                  <p className="text-xs text-slate-500">Sent {formatDate(request.createdAt)}</p>
                </div>
                <div className="flex items-center gap-2">
                  <Badge variant={changeRequestStatusBadgeVariant[request.status]}>
                    {changeRequestStatusLabels[request.status]}
                  </Badge>
                  {request.status === ChangeRequestStatus.Pending && (
                    <>
                      <Button
                        type="button"
                        variant="secondary"
                        size="sm"
                        onClick={() => setReviewTarget({ request, decision: ChangeRequestStatus.Approved })}
                      >
                        <Check className="h-4 w-4 text-emerald-600" />
                        Approve
                      </Button>
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        onClick={() => setReviewTarget({ request, decision: ChangeRequestStatus.Rejected })}
                      >
                        <X className="h-4 w-4 text-red-600" />
                        Reject
                      </Button>
                    </>
                  )}
                </div>
              </div>

              {request.ownerNote && (
                <p className="mt-3 rounded-md bg-slate-50 px-3 py-2 text-sm text-slate-700">
                  <span className="font-medium">Owner says:</span> {request.ownerNote}
                </p>
              )}

              <table className="mt-4 w-full text-left text-sm">
                <thead className="text-xs uppercase text-slate-500">
                  <tr>
                    <th className="w-40 py-2 pr-4">Field</th>
                    <th className="py-2 pr-4">
                      {request.status === ChangeRequestStatus.Approved ? "Before approval (now applied)" : "Now"}
                    </th>
                    <th className="py-2">Requested</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {changesOf(request).map((change) => (
                    <tr key={change.label}>
                      <td className="py-2 pr-4 text-slate-500">{change.label}</td>
                      <td className="whitespace-pre-wrap py-2 pr-4 text-slate-500">
                        {request.status === ChangeRequestStatus.Approved ? "—" : change.current}
                      </td>
                      <td className="whitespace-pre-wrap py-2 font-medium text-slate-900">{change.requested}</td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {request.adminNote && (
                <p className="mt-3 text-xs italic text-slate-400">Your note: {request.adminNote}</p>
              )}
            </div>
          ))}
        </div>
      )}

      <ChangeRequestReviewDialog
        request={reviewTarget?.request ?? null}
        decision={reviewTarget?.decision ?? null}
        onClose={() => setReviewTarget(null)}
      />
    </div>
  );
}
