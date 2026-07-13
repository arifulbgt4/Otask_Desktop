import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const map = JSON.parse(
  await readFile(
    join(root, "..", "..", "..", "docs", "ui", "screen-states.json"),
    "utf8",
  ),
);
const requiredStates = new Set(map.global_states);
const seen = new Set();
for (const route of map.routes) {
  const key = `${route.surface}:${route.path}`;
  if (seen.has(key)) throw new Error(`duplicate route: ${key}`);
  seen.add(key);
  for (const state of requiredStates)
    if (!route.states.includes(state))
      throw new Error(`${route.id} is missing ${state}`);
  if (
    route.path.toLowerCase().includes("cli") ||
    route.path.toLowerCase().includes("shell")
  )
    throw new Error(`prohibited route surface: ${route.path}`);
  if (route.risk === "critical" && !route.states.includes("cancellable"))
    throw new Error(`${route.id} must be cancellable`);
}
for (const required of [
  "/dashboard",
  "/approvals",
  "/runs/:runId",
  "/terminal/:sessionId",
  "/settings/sync-health",
]) {
  if (
    !map.routes.some(
      (route) => route.surface === "desktop" && route.path === required,
    )
  )
    throw new Error(`missing desktop route: ${required}`);
}
console.log(
  `routes: ${map.routes.length} GUI routes and required screen states passed`,
);
