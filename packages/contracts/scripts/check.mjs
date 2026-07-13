import Ajv from "ajv/dist/2020.js";
import addFormats from "ajv-formats";
import { readFile } from "node:fs/promises";
import { readdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const schemaDir = join(root, "..", "schemas");
const fixtureDir = join(root, "..", "fixtures");
// The step variants inherit their object type from stepBase through allOf;
// disable only Ajv's redundant strictTypes warning for those refinements.
const ajv = new Ajv({ allErrors: true, strict: true, strictTypes: false });
addFormats(ajv);

const schemaFiles = (await readdir(schemaDir)).filter((file) =>
  file.endsWith(".json"),
);
for (const file of schemaFiles) {
  const schema = JSON.parse(await readFile(join(schemaDir, file), "utf8"));
  ajv.addSchema(schema, file);
}

const fixtureFiles = (await readdir(fixtureDir)).filter((file) =>
  file.endsWith(".json"),
);
let failures = 0;

function validateTaskPlanInvariants(plan) {
  const ids = new Set();
  for (const step of plan.steps) {
    if (ids.has(step.id)) return `duplicate step id: ${step.id}`;
    ids.add(step.id);
  }
  const visiting = new Set();
  const visited = new Set();
  const visit = (id) => {
    if (visiting.has(id)) return `dependency cycle at ${id}`;
    if (visited.has(id)) return null;
    const step = plan.steps.find((candidate) => candidate.id === id);
    if (!step) return `unknown step: ${id}`;
    visiting.add(id);
    for (const dependency of step.depends_on ?? []) {
      const error = visit(dependency);
      if (error) return error;
    }
    visiting.delete(id);
    visited.add(id);
    return null;
  };
  for (const step of plan.steps) {
    const error = visit(step.id);
    if (error) return error;
  }
  return null;
}

for (const file of fixtureFiles) {
  const fixture = JSON.parse(await readFile(join(fixtureDir, file), "utf8"));
  const validate = ajv.getSchema(fixture.schema);
  if (!validate) throw new Error(`${file}: unknown schema ${fixture.schema}`);
  let valid = validate(fixture.value);
  if (valid && fixture.schema === "task-plan.schema.json") {
    const invariantError = validateTaskPlanInvariants(fixture.value);
    valid = invariantError === null;
    if (!valid) console.error(`${file}: ${invariantError}`);
  }
  if (valid !== fixture.valid) {
    failures += 1;
    console.error(`${file}: expected valid=${fixture.valid}, got ${valid}`);
    if (!valid) console.error(validate.errors);
  }
}
if (failures > 0) process.exit(1);
console.log(
  `contracts: ${schemaFiles.length} schemas and ${fixtureFiles.length} fixtures passed`,
);
