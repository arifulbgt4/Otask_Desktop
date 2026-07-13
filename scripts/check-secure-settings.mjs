import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relativePath) =>
  fs.readFileSync(path.join(root, relativePath), "utf8");

const secure = read("apps/desktop/src/settings/secure-settings.ts");
const settings = read("apps/desktop/src/settings/settings.ts");
const native = read("apps/desktop/src-tauri/src/secure_settings.rs");

assert.match(secure, /credential_get/);
assert.match(secure, /credential_set/);
assert.match(secure, /credential_delete/);
assert.match(secure, /MemoryCredentialStore/);
assert.match(secure, /__TAURI_INTERNALS__/);
assert.doesNotMatch(settings, /localStorage|sessionStorage|document\.cookie/);
assert.doesNotMatch(settings, /accessToken|refreshToken|privateKey/);
assert.match(native, /trait CredentialStore/);
assert.match(native, /auth\.accessToken/);
assert.match(native, /ValueTooLarge/);
assert.match(native, /allowlisted_memory_store_round_trips/);

console.log(
  "secure settings: IPC contract, key allowlist, and no-plaintext guards passed",
);
