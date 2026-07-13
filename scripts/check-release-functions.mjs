import assert from "node:assert/strict";
import { validateReleaseDownloadRequest } from "../supabase/functions/_shared/run-grant.mjs";

const valid = {
  release_artifact_id: "release_artifact_p02011_stable",
  expires_in: 300,
};

assert.equal(validateReleaseDownloadRequest(valid), null);
assert.match(
  validateReleaseDownloadRequest({
    ...valid,
    release_artifact_id: "release_bad",
  }),
  /release_artifact_id/,
);
assert.match(
  validateReleaseDownloadRequest({ ...valid, expires_in: 601 }),
  /expires_in/,
);
assert.match(
  validateReleaseDownloadRequest({ ...valid, expires_in: 29 }),
  /expires_in/,
);

console.log(
  "release functions: artifact-id and signed URL TTL fixtures passed",
);
