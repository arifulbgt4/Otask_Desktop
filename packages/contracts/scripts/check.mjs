import Ajv from "ajv/dist/2020.js";
import addFormats from "ajv-formats";
import { readFile } from "node:fs/promises";
import { readdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const schemaDir = join(root, "..", "schemas");
const fixtureDir = join(root, "..", "fixtures");
const ajv = new Ajv({ allErrors: true, strict: true });
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
for (const file of fixtureFiles) {
  const fixture = JSON.parse(await readFile(join(fixtureDir, file), "utf8"));
  const validate = ajv.getSchema(fixture.schema);
  if (!validate) throw new Error(`${file}: unknown schema ${fixture.schema}`);
  const valid = validate(fixture.value);
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
