import { NavLink, Outlet, useNavigate } from "react-router-dom";
import {
  Building2,
  HelpCircle,
  Image,
  Inbox,
  LayoutDashboard,
  LogOut,
  Phone,
  Share2,
  UtensilsCrossed,
} from "lucide-react";
import { useAuth } from "../../lib/auth-context";
import { cn } from "../../lib/utils";

const navItems = [
  { to: "/", label: "Dashboard", icon: LayoutDashboard, end: true },
  { to: "/restaurants", label: "Restaurants", icon: UtensilsCrossed, end: false },
  { to: "/submissions", label: "Submissions", icon: Inbox, end: false },
  { to: "/advertisements", label: "Advertisements", icon: Image, end: false },
  { to: "/faq", label: "FAQ", icon: HelpCircle, end: false },
  { to: "/company-info/about", label: "About Us", icon: Building2, end: false },
  { to: "/company-info/contacts", label: "Contacts", icon: Phone, end: false },
  { to: "/company-info/social-links", label: "Social Links", icon: Share2, end: false },
];

export function AppShell() {
  const { logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login", { replace: true });
  };

  return (
    <div className="flex min-h-screen bg-slate-50">
      <aside className="w-64 shrink-0 border-r border-slate-200 bg-white">
        <div className="border-b border-slate-200 px-6 py-5">
          <p className="text-lg font-semibold text-slate-900">HARA Admin</p>
        </div>
        <nav className="space-y-1 px-3 py-4">
          {navItems.map(({ to, label, icon: Icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                cn(
                  "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors",
                  isActive ? "bg-slate-900 text-white" : "text-slate-600 hover:bg-slate-100"
                )
              }
            >
              <Icon className="h-4 w-4" />
              {label}
            </NavLink>
          ))}
        </nav>
      </aside>
      <div className="flex min-h-screen flex-1 flex-col">
        <header className="flex items-center justify-end border-b border-slate-200 bg-white px-6 py-4">
          <button
            type="button"
            onClick={handleLogout}
            className="flex items-center gap-2 text-sm font-medium text-slate-600 hover:text-slate-900"
          >
            <LogOut className="h-4 w-4" />
            Sign out
          </button>
        </header>
        <main className="flex-1 p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
