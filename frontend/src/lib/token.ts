const STORAGE_KEY = "hara_admin_session";

interface StoredSession {
  token: string;
  expiresAtUtc: string;
}

export function getSession(): StoredSession | null {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return null;

  try {
    const session = JSON.parse(raw) as StoredSession;
    if (new Date(session.expiresAtUtc).getTime() <= Date.now()) {
      localStorage.removeItem(STORAGE_KEY);
      return null;
    }
    return session;
  } catch {
    localStorage.removeItem(STORAGE_KEY);
    return null;
  }
}

export function setSession(token: string, expiresAtUtc: string): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify({ token, expiresAtUtc }));
}

export function clearSession(): void {
  localStorage.removeItem(STORAGE_KEY);
}

export function getToken(): string | null {
  return getSession()?.token ?? null;
}
