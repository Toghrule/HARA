import { createContext, useContext, useMemo, useState, type ReactNode } from "react";
import { api } from "./api";
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
        const result = await api.post<LoginResult>("/api/auth/login", { email, password });
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
