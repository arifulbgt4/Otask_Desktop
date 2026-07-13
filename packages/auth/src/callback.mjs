export const AUTH_REDIRECTS = Object.freeze([
  "http://localhost:3000/auth/callback",
  "http://127.0.0.1:3000/auth/callback",
  "otask://auth/callback",
]);

export function isAllowedRedirect(value) {
  return AUTH_REDIRECTS.includes(value);
}

export function parseOAuthCallback(rawUrl) {
  const url = new URL(rawUrl);
  if (url.hash) {
    return { kind: "error", code: "implicit_flow_not_allowed" };
  }

  const error = url.searchParams.get("error");
  if (error) {
    return {
      kind: "error",
      code: error,
      description: url.searchParams.get("error_description") ?? "",
    };
  }

  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  if (!code || !state) {
    return { kind: "error", code: "missing_code_or_state" };
  }

  return { kind: "success", code, state };
}
