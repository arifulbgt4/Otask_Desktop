export const AUTH_REDIRECTS: readonly string[];
export function isAllowedRedirect(value: string): boolean;
export function parseOAuthCallback(
  rawUrl: string,
):
  | { kind: "success"; code: string; state: string }
  | { kind: "error"; code: string; description?: string };
