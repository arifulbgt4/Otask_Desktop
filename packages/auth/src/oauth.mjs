import {
  AUTH_REDIRECTS,
  isAllowedRedirect,
  parseOAuthCallback,
} from "./callback.mjs";

const encoder = new TextEncoder();

function base64Url(bytes) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function randomToken(bytes = 32) {
  const values = new Uint8Array(bytes);
  crypto.getRandomValues(values);
  return base64Url(values);
}

export async function sha256Base64Url(value) {
  const digest = await crypto.subtle.digest("SHA-256", encoder.encode(value));
  return base64Url(new Uint8Array(digest));
}

export async function createPkceTransaction({
  redirectUri = AUTH_REDIRECTS[2],
  now = Date.now(),
  ttlMs = 10 * 60 * 1000,
} = {}) {
  if (!isAllowedRedirect(redirectUri))
    throw new Error("redirect URI is not allowlisted");
  if (!Number.isSafeInteger(ttlMs) || ttlMs < 60_000 || ttlMs > 15 * 60_000)
    throw new Error("PKCE transaction TTL is outside the allowed range");
  const verifier = randomToken(32);
  return {
    state: randomToken(32),
    verifier,
    challenge: await sha256Base64Url(verifier),
    redirectUri,
    createdAt: now,
    expiresAt: now + ttlMs,
  };
}

export function buildGoogleAuthorizeUrl({
  supabaseUrl,
  transaction,
  prompt = "select_account",
}) {
  if (!supabaseUrl || !transaction?.state || !transaction.challenge)
    throw new Error("Supabase URL and PKCE transaction are required");
  const url = new URL("/auth/v1/authorize", supabaseUrl);
  url.searchParams.set("provider", "google");
  url.searchParams.set("redirect_to", transaction.redirectUri);
  url.searchParams.set("code_challenge", transaction.challenge);
  url.searchParams.set("code_challenge_method", "S256");
  url.searchParams.set("state", transaction.state);
  url.searchParams.set("prompt", prompt);
  return url.toString();
}

export function validateOAuthCallback(rawUrl, transaction, now = Date.now()) {
  const parsed = parseOAuthCallback(rawUrl);
  if (parsed.kind === "error") return parsed;
  if (!transaction || transaction.expiresAt <= now)
    return { kind: "error", code: "transaction_expired" };
  if (parsed.state !== transaction.state)
    return { kind: "error", code: "state_mismatch" };
  const url = new URL(rawUrl);
  const redirect = `${url.protocol}//${url.host}${url.pathname}`;
  if (redirect !== transaction.redirectUri || !isAllowedRedirect(redirect))
    return { kind: "error", code: "redirect_not_allowed" };
  return parsed;
}
