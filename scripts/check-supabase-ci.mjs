import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relativePath) =>
  fs.readFileSync(path.join(root, relativePath), "utf8");
const exists = (relativePath) => fs.existsSync(path.join(root, relativePath));

const config = read("supabase/config.toml");
const seed = read("supabase/seed.sql");
const workflow = read(".github/workflows/ci-supabase.yml");
const ciTest = read("supabase/tests/p02_012_ci.sql");

assert.match(seed, /insert into storage\.buckets/i);
assert.match(seed, /resource_seed_learning/);
assert.match(seed, /on conflict \(id\) do update/i);
assert.match(seed, /on conflict \(slug, locale, version\) do update/i);
assert.match(ciTest, /select plan\(11\)/);
assert.match(ciTest, /set local role anon/);

const functions = {
  "register-device": true,
  "pairing-challenge": true,
  "rotate-device-key": true,
  "revoke-device": true,
  "issue-run-grant": true,
  "consume-run-grant": true,
  "initialize-terminal-session": true,
  "append-terminal-signal": true,
  "signed-download-url": false,
};

for (const [name, verifyJwt] of Object.entries(functions)) {
  const relativePath = `supabase/functions/${name}/index.ts`;
  assert.ok(exists(relativePath), `${relativePath} exists`);
  const source = read(relativePath);
  assert.match(source, /Deno\.serve\(/, `${name} uses Deno.serve`);
  assert.match(source, /Access-Control-Allow-Origin/, `${name} defines CORS`);
  assert.match(
    source,
    /method_not_allowed/,
    `${name} rejects unsupported methods`,
  );
  assert.match(
    config,
    new RegExp(`\\[functions\\.${name.replaceAll("-", "\\-")}\\]`),
    `${name} has a config section`,
  );
  assert.match(
    config,
    new RegExp(
      `\\[functions\\.${name.replaceAll("-", "\\-")}\\][\\s\\S]*?verify_jwt = ${verifyJwt}`,
    ),
    `${name} has the expected JWT boundary`,
  );
}

assert.match(workflow, /node scripts\/check-supabase-ci\.mjs/);
assert.match(workflow, /supabase db reset --local/);
assert.match(workflow, /supabase test db/);
assert.match(workflow, /supabase stop/);

console.log(
  `supabase CI: seed, ${Object.keys(functions).length} Edge Functions, RLS, and reset/test workflow checks passed`,
);
