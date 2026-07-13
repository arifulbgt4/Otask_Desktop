import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relativePath) =>
  fs.readFileSync(path.join(root, relativePath), "utf8");
const service = read("crates/otask-service/src/lib.rs");
const manifest = read("apps/desktop/src-tauri/Cargo.toml");
const main = read("apps/desktop/src-tauri/src/main.rs");

assert.match(service, /ServiceState::Starting/);
assert.match(service, /ServiceState::Stopping/);
assert.match(service, /pub fn restart/);
assert.match(service, /constant_time_equal/);
assert.match(service, /IpcError::Unauthorized/);
assert.match(service, /pub struct LocalIpcServer/);
assert.match(
  service,
  /unauthorized_local_client_is_rejected_without_state_change/,
);
assert.match(
  manifest,
  /otask-service = \{ path = "\.\.\/\.\.\/\.\.\/crates\/otask-service" \}/,
);
assert.match(main, /LOCAL_IPC_PROTOCOL/);

console.log(
  "service IPC: lifecycle, constant-time authentication, and desktop wiring guards passed",
);
