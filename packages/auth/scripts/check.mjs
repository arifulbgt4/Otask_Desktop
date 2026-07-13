import assert from "node:assert/strict";
import {
  AUTH_REDIRECTS,
  isAllowedRedirect,
  parseOAuthCallback,
} from "../src/callback.mjs";

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

console.log("auth: callback and redirect fixtures passed");
