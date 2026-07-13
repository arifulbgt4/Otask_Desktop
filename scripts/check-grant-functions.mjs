import assert from "node:assert/strict";
import {
  canonicalGrantPayload,
  signGrantPayload,
  validateGrantProof,
  validateRunGrantRequest,
  verifyGrantSignature,
} from "../supabase/functions/_shared/run-grant.mjs";

const validRequest = {
  run_id: "run_p02009_grant",
  device_id: "device_p02009_target",
  plan_hash: "a".repeat(64),
  scope: { capabilities: ["workflow_execution"] },
  ttl_seconds: 300,
};

assert.equal(validateRunGrantRequest(validRequest), null);
assert.match(
  validateRunGrantRequest({ ...validRequest, plan_hash: "tampered" }),
  /plan_hash/,
);
assert.match(
  validateRunGrantRequest({ ...validRequest, ttl_seconds: 601 }),
  /ttl_seconds/,
);
assert.match(
  validateRunGrantRequest({
    ...validRequest,
    scope: { target_device_id: "device_other" },
  }),
  /binding/,
);

const grant = {
  grant_id: "grant_p02009_signed",
  grant_type: "run",
  user_id: "00000000-0000-0000-0000-000000000209",
  device_id: validRequest.device_id,
  run_id: validRequest.run_id,
  plan_hash: validRequest.plan_hash,
  scope: {
    ...validRequest.scope,
    run_id: validRequest.run_id,
    target_device_id: validRequest.device_id,
    plan_hash: validRequest.plan_hash,
  },
  issued_at: "2026-07-14T00:00:00.000Z",
  expires_at: "2026-07-14T00:05:00.000Z",
  nonce: "N".repeat(32),
};
const secret = "local-test-grant-secret-012345678901";
const signature = await signGrantPayload(grant, secret);
assert.equal(signature.length, 43);
assert.equal(await verifyGrantSignature(grant, signature, secret), true);
assert.equal(
  await verifyGrantSignature(
    { ...grant, plan_hash: "b".repeat(64) },
    signature,
    secret,
  ),
  false,
);
assert.notEqual(
  canonicalGrantPayload(grant),
  canonicalGrantPayload({ ...grant, expires_at: "2026-07-14T00:06:00.000Z" }),
);

assert.equal(
  validateGrantProof({
    grant_id: grant.grant_id,
    device_id: grant.device_id,
    nonce: grant.nonce,
    signature,
  }),
  null,
);
assert.match(
  validateGrantProof({
    grant_id: grant.grant_id,
    device_id: grant.device_id,
    nonce: "short",
    signature,
  }),
  /nonce/,
);

console.log(
  "run grants: validation, canonical signing, tamper, and proof fixtures passed",
);
