import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relativePath) =>
  fs.readFileSync(path.join(root, relativePath), "utf8");
const app = read("apps/desktop/src/App.tsx");
const navigation = read("apps/desktop/src/navigation.ts");
const vite = read("apps/desktop/vite.config.ts");
const tauri = JSON.parse(read("apps/desktop/src-tauri/tauri.conf.json"));

assert.match(vite, /@vitejs\/plugin-react/);
assert.match(vite, /plugins: \[react\(\)\]/);
assert.match(navigation, /export type DesktopRoute/);
assert.match(navigation, /dashboard/);
assert.match(navigation, /settings/);
assert.ok((navigation.match(/id: "/g) ?? []).length >= 9);
assert.match(app, /<nav aria-label="Primary navigation">/);
assert.match(app, /aria-current=/);
assert.match(app, /data-shell="tauri-v2"/);
assert.match(read("apps/desktop/index.html"), /id="root"/);
assert.equal(tauri.$schema, "https://schema.tauri.app/config/2");
assert.equal(tauri.build.devUrl, "http://127.0.0.1:1420");
assert.equal(tauri.build.frontendDist, "../dist");
assert.equal(tauri.app.windows[0].label, "main");
assert.equal(tauri.app.windows[0].minWidth, 960);

console.log(
  "desktop shell: React/Vite, Tauri 2 config, and navigation guards passed",
);
