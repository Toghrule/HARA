import { Link } from "react-router-dom";
import { PageHeader } from "../../components/ui/PageHeader";
import { useRestaurants } from "../restaurants/api";
import { useSubmissions } from "../submissions/api";
import { useAdvertisements } from "../advertisements/api";
import { useFaqItems } from "../faq/api";
import { SubmissionStatus } from "../../types";

export function DashboardPage() {
  const { data: restaurants } = useRestaurants();
  const { data: pendingSubmissions } = useSubmissions(SubmissionStatus.Pending);
  const { data: advertisements } = useAdvertisements();
  const { data: faqItems } = useFaqItems();

  const cards = [
    { label: "Restaurants", count: restaurants?.length, to: "/restaurants" },
    { label: "Pending submissions", count: pendingSubmissions?.length, to: "/submissions" },
    { label: "Advertisements", count: advertisements?.length, to: "/advertisements" },
    { label: "FAQ entries", count: faqItems?.length, to: "/faq" },
  ];

  return (
    <div className="space-y-6">
      <PageHeader title="Dashboard" description="Overview of the HARA admin content." />
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {cards.map((card) => (
          <Link
            key={card.to}
            to={card.to}
            className="rounded-lg border border-slate-200 bg-white p-5 transition-shadow hover:shadow-md"
          >
            <p className="text-sm text-slate-500">{card.label}</p>
            <p className="mt-2 text-2xl font-semibold text-slate-900">{card.count ?? "—"}</p>
          </Link>
        ))}
      </div>
    </div>
  );
}
