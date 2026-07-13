import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relativePath) =>
  fs.readFileSync(path.join(root, relativePath), "utf8");
const oauth = read("apps/desktop/src/auth/oauth.ts");
const authPackage = read("packages/auth/src/oauth.mjs");

assert.match(oauth, /startGoogleSignIn/);
assert.match(oauth, /grant_type=pkce/);
assert.match(oauth, /grant_type=refresh_token/);
assert.match(oauth, /auth\/v1\/logout/);
assert.match(oauth, /auth\.accessToken/);
assert.match(oauth, /auth\.refreshToken/);
assert.doesNotMatch(oauth, /localStorage|sessionStorage|document\.cookie/);
assert.match(authPackage, /code_challenge_method/);
assert.match(authPackage, /state_mismatch/);
assert.match(authPackage, /transaction_expired/);

console.log(
  "desktop auth: PKCE system-browser, refresh, sign-out, and callback guards passed",
);
