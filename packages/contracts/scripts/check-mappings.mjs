import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const schemaDir = join(root, "..", "schemas");
const expected = [
  "common.schema.json",
  "error-envelope.schema.json",
  "event-envelope.schema.json",
  "task-plan.schema.json",
  "execution-state.schema.json",
  "execution-event.schema.json",
  "schedule.schema.json",
  "approval.schema.json",
  "device.schema.json",
  "run-grant.schema.json",
  "evidence.schema.json",
  "artifact.schema.json",
  "clipboard.schema.json",
];

for (const file of expected) await readFile(join(schemaDir, file), "utf8");

const outputs = [
  join(root, "..", "src", "generated.ts"),
  join(root, "..", "..", "..", "crates", "otask-domain", "src", "lib.rs"),
  join(root, "..", "..", "..", "apps", "mobile", "lib", "contracts.dart"),
];
for (const output of outputs) {
  const content = await readFile(output, "utf8");
  for (const schema of expected) {
    if (!content.includes(schema))
      throw new Error(`${output} is missing ${schema}`);
  }
}

const [ts, rust, dart] = await Promise.all(
  outputs.map((output) => readFile(output, "utf8")),
);
if (!ts.includes('GENERATED_CONTRACT_SCHEMA_VERSION = "1.0"'))
  throw new Error("TypeScript mapping version mismatch");
if (!rust.includes('CONTRACT_SCHEMA_VERSION: &str = "1.0"'))
  throw new Error("Rust mapping version mismatch");
if (!dart.includes("generatedContractSchemaVersion = '1.0'"))
  throw new Error("Dart mapping version mismatch");
console.log(
  `mappings: ${expected.length} schemas mapped in TypeScript, Rust, and Dart`,
);
