import { useState } from "react";
import { Star, Trash2 } from "lucide-react";
import { PageHeader } from "../../components/ui/PageHeader";
import { Button } from "../../components/ui/Button";
import { Spinner } from "../../components/ui/Spinner";
import { EmptyState } from "../../components/ui/EmptyState";
import { ConfirmDialog } from "../../components/ui/ConfirmDialog";
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { useDeleteReview, useReviews, type AdminReview } from "./api";

function Stars({ count }: { count: number }) {
  return (
    <span className="inline-flex" aria-label={`${count} of 5 stars`}>
      {[1, 2, 3, 4, 5].map((n) => (
        <Star key={n} className={n <= count ? "h-4 w-4 fill-amber-400 text-amber-400" : "h-4 w-4 text-slate-300"} />
      ))}
    </span>
  );
}

export function ReviewsPage() {
  const [page, setPage] = useState(1);
  const { data, isLoading } = useReviews(page);
  const deleteMutation = useDeleteReview();
  const { push } = useToast();
  const [pending, setPending] = useState<AdminReview | null>(null);

  const rows = data ?? [];

  const remove = async () => {
    if (!pending) return;
    try {
      await deleteMutation.mutateAsync(pending.id);
      push("Review removed");
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Failed to remove the review", "error");
    } finally {
      setPending(null);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Reviews"
        description="What customers who signed in with Google wrote about the restaurants, newest first. Anyone signed in can write one, so remove what does not belong (abuse, spam, an unfair attack): the restaurant's average is worked out again at once. The email is for you only; the app shows just the first name and the initial of the last."
      />

      {isLoading ? (
        <Spinner />
      ) : !rows.length ? (
        <EmptyState message={page > 1 ? "No more reviews." : "No reviews yet."} />
      ) : (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase text-slate-500">
              <tr>
                <th className="px-4 py-3">When</th>
                <th className="px-4 py-3">Restaurant</th>
                <th className="px-4 py-3">Stars</th>
                <th className="px-4 py-3">Review</th>
                <th className="px-4 py-3">Customer</th>
                <th className="px-4 py-3 text-right">Remove</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {rows.map((review) => (
                <tr key={review.id}>
                  <td className="whitespace-nowrap px-4 py-3 text-slate-500">{new Date(review.createdAt).toLocaleString()}</td>
                  <td className="px-4 py-3 font-medium text-slate-900">{review.restaurantName}</td>
                  <td className="px-4 py-3">
                    <Stars count={review.stars} />
                  </td>
                  <td className="max-w-md px-4 py-3 text-slate-700">{review.text ?? <span className="text-slate-400">(no words)</span>}</td>
                  <td className="px-4 py-3 text-slate-600">
                    {review.authorName ?? "—"}
                    {review.authorEmail && <div className="text-xs text-slate-400">{review.authorEmail}</div>}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <Button type="button" variant="ghost" size="sm" title="Remove this review" onClick={() => setPending(review)}>
                      <Trash2 className="h-4 w-4 text-red-600" />
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="flex justify-end gap-2">
        <Button type="button" variant="secondary" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
          Newer
        </Button>
        <Button type="button" variant="secondary" disabled={rows.length < 50} onClick={() => setPage((p) => p + 1)}>
          Older
        </Button>
      </div>

      <ConfirmDialog
        open={pending !== null}
        title="Remove review"
        message={`Remove the review by ${pending?.authorName ?? "this customer"} of "${pending?.restaurantName}"? It cannot be undone.`}
        confirmLabel="Remove"
        isLoading={deleteMutation.isPending}
        onCancel={() => setPending(null)}
        onConfirm={remove}
      />
    </div>
  );
}
