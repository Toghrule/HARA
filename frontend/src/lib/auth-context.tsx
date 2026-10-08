import { createContext, useContext, useMemo, useState, type ReactNode } from "react";
import { api, ApiError } from "./api";
import { clearSession, getSession, setSession } from "./token";
import type { LoginResult } from "../types";

interface AuthContextValue {
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState(() => getSession() !== null);

  const value = useMemo<AuthContextValue>(
    () => ({
      isAuthenticated,
      login: async (email: string, password: string) => {
        const result = await api.post<LoginResult>("/api/auth/login", { email, password }, { anonymous: true });
        // Restaurant owners and waiters sign in with the same endpoint (they use the mobile app); none of the
        // admin screens would work for them, so say so instead of letting them in to a wall of errors.
        if (!result.roles?.includes("Admin")) {
          throw new ApiError(403, "This account is not an administrator.");
        }
        setSession(result.token, result.expiresAtUtc);
        setIsAuthenticated(true);
      },
      logout: () => {
        clearSession();
        setIsAuthenticated(false);
      },
    }),
    [isAuthenticated]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
