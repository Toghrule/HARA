import { useState } from "react";
import { Copy } from "lucide-react";
import { PageHeader } from "../../components/ui/PageHeader";
import { Spinner } from "../../components/ui/Spinner";
import { EmptyState } from "../../components/ui/EmptyState";
import { Button } from "../../components/ui/Button";
import { useToast } from "../../components/ui/Toast";
import { cn } from "../../lib/utils";
import { useMonthlyVisits, useVisits, type MonthlyVisits, type RestaurantVisits, type VisitCounts } from "./api";

type Period = "today" | "thisWeek" | "thisMonth" | "total";

const tabs: { label: string; value: Period }[] = [
  { label: "Today", value: "today" },
  { label: "This week", value: "thisWeek" },
  { label: "This month", value: "thisMonth" },
  { label: "All time", value: "total" },
];

const columns: { key: keyof VisitCounts; label: string; hint: string }[] = [
  { key: "codesObtained", label: "Codes obtained", hint: "Customers who tapped “get the discount”" },
  { key: "codesRedeemed", label: "Came (confirmed)", hint: "Codes the restaurant confirmed: customers HARA brought" },
  { key: "views", label: "Page opened", hint: "Times the restaurant's page was opened" },
  { key: "directions", label: "Directions", hint: "Times the way to the restaurant was opened in maps" },
];

const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

/** The report for one restaurant, written so it can be pasted into a message to the owner. */
function reportText(row: MonthlyVisits, year: number, month: number) {
  const lines = [
    `HARA: result for ${monthNames[month - 1]} ${year}`,
    `Restaurant: ${row.name}${row.discountPercent > 0 ? ` (discount ${row.discountPercent}%)` : ""}`,
    `Customers HARA brought (codes you confirmed): ${row.counts.codesRedeemed}`,
    `Discount codes taken by customers: ${row.counts.codesObtained}`,
    `Times your page was opened: ${row.counts.views} (${row.uniqueViewers} different phones)`,
    `Times the way to you was opened in maps: ${row.counts.directions}`,
  ];
  return lines.join("\n");
}

export function VisitsPage() {
  const [period, setPeriod] = useState<Period>("today");
  const { data, isLoading } = useVisits();
  const rows: RestaurantVisits[] = data ?? [];

  const now = new Date();
  const [monthValue, setMonthValue] = useState(`${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`);
  const [year, month] = monthValue.split("-").map(Number);
  const monthly = useMonthlyVisits(year, month);
  const { push } = useToast();

  const copy = (text: string) => navigator.clipboard.writeText(text).then(() => push("Copied"));
  const monthlyRows: MonthlyVisits[] = monthly.data ?? [];

  return (
    <div className="space-y-8">
      <PageHeader
        title="Visits"
        description="How many customers HARA brings and how often restaurants are looked at. A code is taken when a customer taps “get the discount” (one per phone per restaurant per day, valid 6 hours); it counts as “came” when the restaurant confirms it. Days and months are counted in Azerbaijan time."
      />

      <section className="space-y-4">
        <div className="flex gap-1 border-b border-slate-200">
          {tabs.map((tab) => (
            <button
              key={tab.value}
              type="button"
              onClick={() => setPeriod(tab.value)}
              className={cn(
                "border-b-2 px-3 py-2 text-sm font-medium transition-colors",
                period === tab.value ? "border-slate-900 text-slate-900" : "border-transparent text-slate-500 hover:text-slate-800"
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
                  <th className="px-4 py-3 text-right">Discount</th>
                  {columns.map((column) => (
                    <th key={column.key} className="px-4 py-3 text-right" title={column.hint}>
                      {column.label}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {rows.map((row) => (
                  <tr key={row.restaurantId}>
                    <td className="px-4 py-3 font-medium text-slate-900">{row.name}</td>
                    <td className="px-4 py-3 text-right text-slate-600">{row.discountPercent > 0 ? `${row.discountPercent}%` : "—"}</td>
                    {columns.map((column) => (
                      <td key={column.key} className="px-4 py-3 text-right tabular-nums">
                        {row[period][column.key]}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
              <tfoot className="bg-slate-50 font-semibold">
                <tr>
                  <td className="px-4 py-3">All restaurants</td>
                  <td />
                  {columns.map((column) => (
                    <td key={column.key} className="px-4 py-3 text-right tabular-nums">
                      {rows.reduce((sum, row) => sum + row[period][column.key], 0)}
                    </td>
                  ))}
                </tr>
              </tfoot>
            </table>
          </div>
        )}
      </section>

      <section className="space-y-4">
        <div className="flex flex-wrap items-end justify-between gap-3">
          <div>
            <h2 className="text-lg font-semibold text-slate-900">Monthly result for the restaurants</h2>
            <p className="text-sm text-slate-500">Pick a month, then copy a restaurant's text and send it to the owner.</p>
          </div>
          <input
            type="month"
            value={monthValue}
            onChange={(event) => event.target.value && setMonthValue(event.target.value)}
            className="rounded-md border border-slate-300 px-3 py-2 text-sm"
            aria-label="Month"
          />
        </div>

        {monthly.isLoading ? (
          <Spinner />
        ) : !monthlyRows.length ? (
          <EmptyState message="No restaurants yet." />
        ) : (
          <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
            <table className="w-full text-left text-sm">
              <thead className="bg-slate-50 text-xs uppercase text-slate-500">
                <tr>
                  <th className="px-4 py-3">Restaurant</th>
                  <th className="px-4 py-3 text-right">Came (confirmed)</th>
                  <th className="px-4 py-3 text-right">Codes obtained</th>
                  <th className="px-4 py-3 text-right">Page opened</th>
                  <th className="px-4 py-3 text-right">Different phones</th>
                  <th className="px-4 py-3 text-right">Directions</th>
                  <th className="px-4 py-3 text-right">Report</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {monthlyRows.map((row) => (
                  <tr key={row.restaurantId}>
                    <td className="px-4 py-3 font-medium text-slate-900">{row.name}</td>
                    <td className="px-4 py-3 text-right tabular-nums">{row.counts.codesRedeemed}</td>
                    <td className="px-4 py-3 text-right tabular-nums">{row.counts.codesObtained}</td>
                    <td className="px-4 py-3 text-right tabular-nums">{row.counts.views}</td>
                    <td className="px-4 py-3 text-right tabular-nums">{row.uniqueViewers}</td>
                    <td className="px-4 py-3 text-right tabular-nums">{row.counts.directions}</td>
                    <td className="px-4 py-3 text-right">
                      <Button type="button" variant="ghost" size="sm" title="Copy the text for this restaurant" onClick={() => copy(reportText(row, year, month))}>
                        <Copy className="h-4 w-4" />
                        Copy
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  );
}
