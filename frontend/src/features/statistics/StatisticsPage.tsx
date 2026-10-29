import { useState } from "react";
import { PageHeader } from "../../components/ui/PageHeader";
import { Spinner } from "../../components/ui/Spinner";
import { EmptyState } from "../../components/ui/EmptyState";
import { cn } from "../../lib/utils";
import { useRestaurantStats } from "./api";
import type { RestaurantStatsDto } from "../../types";

type Period = "thisMonth" | "lastMonth" | "allTime";

const tabs: { label: string; value: Period }[] = [
  { label: "This month", value: "thisMonth" },
  { label: "Last month", value: "lastMonth" },
  { label: "All time", value: "allTime" },
];

const columns = [
  { key: "requests", label: "Requests" },
  { key: "accepted", label: "Accepted" },
  { key: "redeemed", label: "Came (redeemed)" },
  { key: "noShows", label: "No-shows" },
  { key: "declined", label: "Declined" },
  { key: "unanswered", label: "No answer" },
] as const;

export function StatisticsPage() {
  const [period, setPeriod] = useState<Period>("thisMonth");
  const { data, isLoading } = useRestaurantStats();

  const rows: RestaurantStatsDto[] = data ?? [];
  const totals = columns.map((column) => rows.reduce((sum, row) => sum + row[period][column.key], 0));

  return (
    <div className="space-y-6">
      <PageHeader
        title="Statistics"
        description="How many table requests each restaurant got, by the day the customer sent them. Months are counted in Azerbaijan time. “Came” are codes the restaurant confirmed; a no-show is an accepted reservation whose time ran out without the code being confirmed."
      />

      <div className="flex gap-1 border-b border-slate-200">
        {tabs.map((tab) => (
          <button
            key={tab.value}
            type="button"
            onClick={() => setPeriod(tab.value)}
            className={cn(
              "border-b-2 px-3 py-2 text-sm font-medium transition-colors",
              period === tab.value
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
      ) : !rows.length ? (
        <EmptyState message="No restaurants yet." />
      ) : (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase text-slate-500">
              <tr>
                <th className="px-4 py-3">Restaurant</th>
                {columns.map((column) => (
                  <th key={column.key} className="px-4 py-3 text-right">
                    {column.label}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {rows.map((row) => (
                <tr key={row.restaurantId}>
                  <td className="px-4 py-3 font-medium text-slate-900">{row.restaurantName}</td>
                  {columns.map((column) => (
                    <td key={column.key} className="px-4 py-3 text-right tabular-nums text-slate-700">
                      {row[period][column.key]}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
            <tfoot className="bg-slate-50 font-semibold text-slate-900">
              <tr>
                <td className="px-4 py-3">Total</td>
                {totals.map((total, index) => (
                  <td key={columns[index].key} className="px-4 py-3 text-right tabular-nums">
                    {total}
                  </td>
                ))}
              </tr>
            </tfoot>
          </table>
        </div>
      )}
    </div>
  );
}
