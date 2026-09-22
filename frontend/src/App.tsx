import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { QueryClientProvider } from "@tanstack/react-query";
import { queryClient } from "./lib/queryClient";
import { AuthProvider } from "./lib/auth-context";
import { ToastProvider } from "./components/ui/Toast";
import { ProtectedRoute } from "./components/layout/ProtectedRoute";
import { AppShell } from "./components/layout/AppShell";
import { LoginPage } from "./features/auth/LoginPage";
import { DashboardPage } from "./features/dashboard/DashboardPage";
import { RestaurantsPage } from "./features/restaurants/RestaurantsPage";
import { SubmissionsPage } from "./features/submissions/SubmissionsPage";
import { AdvertisementsPage } from "./features/advertisements/AdvertisementsPage";
import { FaqPage } from "./features/faq/FaqPage";
import { AboutUsPage } from "./features/company-info/AboutUsPage";
import { ContactsPage } from "./features/company-info/ContactsPage";
import { SocialLinksPage } from "./features/company-info/SocialLinksPage";

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ToastProvider>
        <AuthProvider>
          <BrowserRouter>
            <Routes>
              <Route path="/login" element={<LoginPage />} />
              <Route
                element={
                  <ProtectedRoute>
                    <AppShell />
                  </ProtectedRoute>
                }
              >
                <Route index element={<DashboardPage />} />
                <Route path="restaurants" element={<RestaurantsPage />} />
                <Route path="submissions" element={<SubmissionsPage />} />
                <Route path="advertisements" element={<AdvertisementsPage />} />
                <Route path="faq" element={<FaqPage />} />
                <Route path="company-info/about" element={<AboutUsPage />} />
                <Route path="company-info/contacts" element={<ContactsPage />} />
                <Route path="company-info/social-links" element={<SocialLinksPage />} />
              </Route>
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </BrowserRouter>
        </AuthProvider>
      </ToastProvider>
    </QueryClientProvider>
  );
}
