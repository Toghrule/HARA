import { useState } from "react";
import { Dialog } from "../../components/ui/Dialog";
import { Button } from "../../components/ui/Button";
import { Textarea } from "../../components/ui/Textarea";
import { FormField } from "../../components/ui/FormField";
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { useReviewSubmission } from "./api";
import { SubmissionStatus } from "../../types";
import type { RestaurantSubmissionDto } from "../../types";

interface SubmissionReviewDialogProps {
  submission: RestaurantSubmissionDto | null;
  decision: SubmissionStatus.Approved | SubmissionStatus.Rejected | null;
  onClose: () => void;
}

export function SubmissionReviewDialog({ submission, decision, onClose }: SubmissionReviewDialogProps) {
  const [adminNote, setAdminNote] = useState("");
  const { push } = useToast();
  const reviewMutation = useReviewSubmission();

  const open = submission !== null && decision !== null;
  const isApprove = decision === SubmissionStatus.Approved;

  const handleClose = () => {
    setAdminNote("");
    onClose();
  };

  const handleConfirm = async () => {
    if (!submission || decision === null) return;
    try {
      await reviewMutation.mutateAsync({ id: submission.id, body: { decision, adminNote: adminNote || null } });
      push(isApprove ? "Submission approved" : "Submission rejected");
      handleClose();
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Failed to review submission", "error");
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} title={isApprove ? "Approve submission" : "Reject submission"}>
      <div className="space-y-4">
        <p className="text-sm text-slate-600">
          {isApprove
            ? `Mark "${submission?.restaurantName}" as approved. You'll still need to create the restaurant separately.`
            : `Mark "${submission?.restaurantName}" as rejected.`}
        </p>
        <FormField label="Admin note (optional)">
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
