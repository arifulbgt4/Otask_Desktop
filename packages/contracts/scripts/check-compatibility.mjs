import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const fixtureDir = join(root, "..", "fixtures");
const manifest = JSON.parse(
  await readFile(
    join(root, "..", "fixtures", "compatibility.valid.json"),
    "utf8",
  ),
);
if (manifest.value.current_version !== "1.0")
  throw new Error("fixture current version drifted");
if (!manifest.value.supported_versions.includes(manifest.value.current_version))
  throw new Error("current version must be supported");

for (const file of ["compatibility.valid.json", "compatibility.invalid.json"]) {
  const fixture = JSON.parse(await readFile(join(fixtureDir, file), "utf8"));
  const supported = fixture.value.supported_versions.includes(
    fixture.value.current_version,
  );
  if (supported !== fixture.expected_supported)
    throw new Error(`${file}: compatibility expectation failed`);
}
console.log("compatibility: current and unsupported version fixtures passed");
