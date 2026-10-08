import { useState } from "react";
import { Dialog } from "../../components/ui/Dialog";
import { Button } from "../../components/ui/Button";
import { Textarea } from "../../components/ui/Textarea";
import { FormField } from "../../components/ui/FormField";
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { useReviewChangeRequest } from "./api";
import { ChangeRequestStatus } from "../../types";
import type { ChangeRequestDto } from "../../types";

interface ChangeRequestReviewDialogProps {
  request: ChangeRequestDto | null;
  decision: ChangeRequestStatus.Approved | ChangeRequestStatus.Rejected | null;
  onClose: () => void;
}

export function ChangeRequestReviewDialog({ request, decision, onClose }: ChangeRequestReviewDialogProps) {
  const [adminNote, setAdminNote] = useState("");
  const { push } = useToast();
  const reviewMutation = useReviewChangeRequest();

  const open = request !== null && decision !== null;
  const isApprove = decision === ChangeRequestStatus.Approved;

  const handleClose = () => {
    setAdminNote("");
    onClose();
  };

  const handleConfirm = async () => {
    if (!request || decision === null) return;
    try {
      await reviewMutation.mutateAsync({ id: request.id, body: { decision, adminNote: adminNote || null } });
      push(isApprove ? "Changes applied to the restaurant" : "Request rejected");
      handleClose();
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Failed to review the request", "error");
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} title={isApprove ? "Approve changes" : "Reject changes"}>
      <div className="space-y-4">
        <p className="text-sm text-slate-600">
          {isApprove
            ? `The requested changes will be applied to "${request?.restaurantName}" right away and shown in the app.`
            : `"${request?.restaurantName}" stays as it is. The owner sees your note, so say why.`}
        </p>
        <FormField label={isApprove ? "Note for the owner (optional)" : "Reason (optional)"}>
          <Textarea rows={3} value={adminNote} onChange={(event) => setAdminNote(event.target.value)} />
        </FormField>
        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={handleClose}>
            Cancel
          </Button>
          <Button
            type="button"
            variant={isApprove ? "primary" : "danger"}
            onClick={handleConfirm}
            disabled={reviewMutation.isPending}
          >
            {isApprove ? "Approve" : "Reject"}
          </Button>
        </div>
      </div>
    </Dialog>
  );
}
