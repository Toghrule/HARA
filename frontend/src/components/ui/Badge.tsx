import type { ReactNode } from "react";
import { cn } from "../../lib/utils";

type BadgeVariant = "success" | "neutral" | "warning" | "danger";

const variantClasses: Record<BadgeVariant, string> = {
  success: "bg-emerald-100 text-emerald-700",
  neutral: "bg-slate-100 text-slate-600",
  warning: "bg-amber-100 text-amber-700",
  danger: "bg-red-100 text-red-700",
};

export function Badge({ variant = "neutral", children }: { variant?: BadgeVariant; children: ReactNode }) {
  return (
    <span className={cn("inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium", variantClasses[variant])}>
      {children}
    </span>
  );
}
