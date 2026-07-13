import assert from "node:assert/strict";
import {
  AUTH_REDIRECTS,
  isAllowedRedirect,
  parseOAuthCallback,
} from "../src/callback.mjs";
import {
  buildGoogleAuthorizeUrl,
  createPkceTransaction,
  validateOAuthCallback,
} from "../src/oauth.mjs";

assert.equal(AUTH_REDIRECTS.length, 3);
assert.equal(isAllowedRedirect("http://localhost:3000/auth/callback"), true);
assert.equal(isAllowedRedirect("https://evil.example/auth/callback"), false);
assert.deepEqual(
  parseOAuthCallback("http://localhost:3000/auth/callback?code=abc&state=xyz"),
  { kind: "success", code: "abc", state: "xyz" },
);
assert.deepEqual(
  parseOAuthCallback(
    "otask://auth/callback?error=access_denied&error_description=cancelled",
  ),
  { kind: "error", code: "access_denied", description: "cancelled" },
);
assert.deepEqual(
  parseOAuthCallback("http://localhost:3000/auth/callback?code=abc"),
  { kind: "error", code: "missing_code_or_state" },
);
assert.deepEqual(
  parseOAuthCallback("http://localhost:3000/auth/callback#access_token=secret"),
  { kind: "error", code: "implicit_flow_not_allowed" },
);

const transaction = await createPkceTransaction({ now: 1000 });
assert.equal(transaction.redirectUri, "otask://auth/callback");
assert.ok(transaction.challenge.length >= 43);
assert.match(
  buildGoogleAuthorizeUrl({
    supabaseUrl: "http://127.0.0.1:54321",
    transaction,
  }),
  /code_challenge_method=S256/,
);
assert.deepEqual(
  validateOAuthCallback(
    `otask://auth/callback?code=abc&state=${transaction.state}`,
    transaction,
    2000,
  ),
  { kind: "success", code: "abc", state: transaction.state },
);
assert.deepEqual(
  validateOAuthCallback(
    "otask://auth/callback?code=abc&state=wrong",
    transaction,
    2000,
  ),
  { kind: "error", code: "state_mismatch" },
);
assert.deepEqual(
  validateOAuthCallback(
    `otask://auth/callback?code=abc&state=${transaction.state}`,
    transaction,
    700_001,
  ),
  { kind: "error", code: "transaction_expired" },
);

console.log("auth: callback and redirect fixtures passed");
