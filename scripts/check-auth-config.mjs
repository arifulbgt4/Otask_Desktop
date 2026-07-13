import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const config = readFileSync("supabase/config.toml", "utf8");
const envExample = readFileSync("supabase/.env.example", "utf8");
const authBlock = config.match(/\[auth\][\s\S]*?(?=\n\[[^\]]+\]|$)/)?.[0] ?? "";
const googleBlock =
  config.match(/\[auth\.external\.google\][\s\S]*?(?=\n\[[^\]]+\]|$)/)?.[0] ??
  "";
const redirects = [
  ...authBlock.matchAll(/"((?:https?|otask):\/\/[^"\n]+)"/g),
].map((match) => match[1]);

assert.match(config, /\[auth\]/);
assert.match(authBlock, /enabled\s*=\s*true/);
assert.match(authBlock, /site_url\s*=\s*"http:\/\/localhost:3000"/);
assert.ok(redirects.includes("http://localhost:3000/auth/callback"));
assert.ok(redirects.includes("http://127.0.0.1:3000/auth/callback"));
assert.ok(redirects.includes("otask://auth/callback"));
assert.match(googleBlock, /enabled\s*=\s*true/);
assert.match(
  googleBlock,
  /client_id\s*=\s*"env\(SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID\)"/,
);
assert.match(
  googleBlock,
  /secret\s*=\s*"env\(SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_SECRET\)"/,
);
assert.match(
  googleBlock,
  /redirect_uri\s*=\s*"http:\/\/127\.0\.0\.1:54321\/auth\/v1\/callback"/,
);
assert.match(googleBlock, /skip_nonce_check\s*=\s*false/);
assert.match(envExample, /^SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID=/m);
assert.match(envExample, /^SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_SECRET=/m);
assert.doesNotMatch(googleBlock, /client_id\s*=\s*"(?!env\()/);
assert.doesNotMatch(googleBlock, /secret\s*=\s*"(?!env\()/);

console.log("auth: Supabase Google local/dev config passed");
