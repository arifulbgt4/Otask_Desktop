import assert from "node:assert/strict";
import {
  canonicalGrantPayload,
  sha256Hex,
  signGrantPayload,
  validateTerminalSessionRequest,
  validateTerminalSignalRequest,
  verifyGrantSignature,
} from "../supabase/functions/_shared/run-grant.mjs";

const terminalScope = { read_only: true, workspace_refs: ["workspace_demo"] };
const validSession = {
  session_id: "session_p02010_terminal",
  grant_id: "grant_p02010_terminal",
  device_id: "device_p02010_target",
  run_id: "run_p02010_terminal",
  nonce: "N".repeat(32),
  signature: "S".repeat(43),
  transport: "webrtc",
  initiated_by: "desktop",
  scope: terminalScope,
};
assert.equal(validateTerminalSessionRequest(validSession), null);
assert.match(
  validateTerminalSessionRequest({ ...validSession, transport: "tcp" }),
  /transport/,
);
assert.match(
  validateTerminalSessionRequest({
    ...validSession,
    scope: { read_only: "yes" },
  }),
  /read_only/,
);

const payload = { sdp: "v=0", type: "offer" };
const validSignal = {
  signal_id: "signal_p02010_offer",
  session_id: validSession.session_id,
  signal_type: "offer",
  payload,
  payload_hash: await sha256Hex(JSON.stringify(payload)),
};
assert.equal(validateTerminalSignalRequest(validSignal), null);
assert.match(
  validateTerminalSignalRequest({ ...validSignal, signal_type: "shell" }),
  /signal_type/,
);
assert.notEqual(
  validSignal.payload_hash,
  await sha256Hex(JSON.stringify({ ...payload, sdp: "tampered" })),
);

const grant = {
  grant_id: validSession.grant_id,
  grant_type: "terminal",
  user_id: "00000000-0000-0000-0000-000000000210",
  device_id: validSession.device_id,
  run_id: validSession.run_id,
  plan_hash: "a".repeat(64),
  scope: terminalScope,
  issued_at: "2026-07-14T00:00:00.000Z",
  expires_at: "2026-07-14T00:05:00.000Z",
  nonce: validSession.nonce,
};
const secret = "local-terminal-grant-secret-012345678901";
const signature = await signGrantPayload(grant, secret);
assert.equal(await verifyGrantSignature(grant, signature, secret), true);
assert.equal(
  await verifyGrantSignature(
    { ...grant, scope: { read_only: false } },
    signature,
    secret,
  ),
  false,
);
assert.match(canonicalGrantPayload(grant), /terminal/);

console.log(
  "terminal functions: session/signal validation, payload hash, and terminal grant fixtures passed",
);
