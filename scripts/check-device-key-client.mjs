import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relativePath) =>
  fs.readFileSync(path.join(root, relativePath), "utf8");
const keys = read("apps/desktop/src/devices/device-keys.ts");
const registration = read("apps/desktop/src/devices/registration.ts");
const capabilities = read("apps/desktop/src/devices/capabilities.ts");
const native = read("apps/desktop/src-tauri/src/device_keys.rs");

assert.match(keys, /TauriDeviceKeyProvider/);
assert.match(keys, /device_generate_key/);
assert.match(keys, /device_sign/);
assert.match(keys, /WebCryptoDeviceKeyProvider/);
assert.match(keys, /Ed25519/);
assert.doesNotMatch(keys, /exportKey\("pkcs8"/);
assert.doesNotMatch(keys, /localStorage|sessionStorage/);
assert.match(registration, /functions\/v1\/register-device/);
assert.match(registration, /public_key/);
assert.match(registration, /capabilities/);
assert.match(capabilities, /workflow_execution/);
assert.match(capabilities, /platformName/);
assert.match(native, /trait DeviceKeyStore/);
assert.match(native, /never_exports_private_key_material/);

console.log(
  "device keys: native IPC, WebCrypto fallback, registration, and capability guards passed",
);
