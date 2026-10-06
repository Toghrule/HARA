import { clearSession, getToken } from "./token";

export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:5080";

export class ApiError extends Error {
  status: number;
  errors?: Record<string, string[]>;

  constructor(status: number, message: string, errors?: Record<string, string[]>) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.errors = errors;
  }
}

interface RequestConfig {
  /**
   * For calls made before signing in (the login itself): don't send the stored token, and don't
   * read a 401 as "your session expired" — there is no session yet, it just means wrong credentials.
   */
  anonymous?: boolean;
}

async function request<T>(path: string, options: RequestInit = {}, config: RequestConfig = {}): Promise<T> {
  const anonymous = config.anonymous ?? false;
  const headers = new Headers(options.headers);
  const isFormData = options.body instanceof FormData;
  if (options.body && !isFormData) {
    headers.set("Content-Type", "application/json");
  }

  const token = anonymous ? null : getToken();
  if (token) {
    headers.set("Authorization", `Bearer ${token}`);
  }

  let response: Response;
  try {
    response = await fetch(`${API_BASE_URL}${path}`, { ...options, headers });
  } catch {
    throw new ApiError(0, "Can't reach the server. Make sure the backend is running, then try again.");
  }

  if (response.status === 401 && !anonymous) {
    clearSession();
    if (window.location.pathname !== "/login") {
      window.location.assign("/login");
    }
    throw new ApiError(401, "Your session has expired. Please sign in again.");
  }

  if (!response.ok) {
    let title = `Request failed (${response.status})`;
    let errors: Record<string, string[]> | undefined;
    try {
      const problem = await response.json();
      title = problem.title ?? problem.detail ?? title;
      errors = problem.errors ?? undefined;
    } catch {
      // no JSON body to read
    }
    throw new ApiError(response.status, title, errors);
  }

  if (response.status === 204) {
    return undefined as T;
  }

  const text = await response.text();
  return (text ? JSON.parse(text) : undefined) as T;
}

export const api = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body?: unknown, config?: RequestConfig) =>
    request<T>(path, { method: "POST", body: body === undefined ? undefined : JSON.stringify(body) }, config),
  put: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: "PUT", body: body === undefined ? undefined : JSON.stringify(body) }),
  patch: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: "PATCH", body: body === undefined ? undefined : JSON.stringify(body) }),
  delete: <T = void>(path: string) => request<T>(path, { method: "DELETE" }),
  upload: <T>(path: string, formData: FormData) => request<T>(path, { method: "POST", body: formData }),
};

export function resolveAssetUrl(url: string | null | undefined): string | undefined {
  if (!url) return undefined;
  if (/^https?:\/\//i.test(url)) return url;
  return `${API_BASE_URL}${url.startsWith("/") ? "" : "/"}${url}`;
}
