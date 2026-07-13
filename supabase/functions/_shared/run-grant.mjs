const ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_-]{7,95}$/;
const DEVICE_ID_PATTERN = /^device_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$/;
const RUN_ID_PATTERN = /^run_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$/;
const HASH_PATTERN = /^[a-f0-9]{64}$/;
const BASE64URL_PATTERN = /^[A-Za-z0-9_-]+$/;
const SESSION_ID_PATTERN = /^session_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$/;
const SIGNAL_ID_PATTERN = /^signal_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$/;

function stableStringify(value) {
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(",")}]`;
  if (value && typeof value === "object") {
    return `{${Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${stableStringify(value[key])}`)
      .join(",")}}`;
  }
  return JSON.stringify(value);
}

function bytesToBase64url(bytes) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function base64urlToBytes(value) {
  const normalized = value
    .replace(/-/g, "+")
    .replace(/_/g, "/")
    .padEnd(Math.ceil(value.length / 4) * 4, "=");
  const binary = atob(normalized);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function grantPayload(input) {
  return {
    grant_id: input.grant_id,
    grant_type: input.grant_type ?? "run",
    user_id: input.user_id,
    device_id: input.device_id,
    run_id: input.run_id,
    plan_hash: input.plan_hash,
    scope: input.scope,
    issued_at: input.issued_at,
    expires_at: input.expires_at,
    nonce: input.nonce,
  };
}

export function canonicalGrantPayload(input) {
  return stableStringify(grantPayload(input));
}

export async function signGrantPayload(input, secret) {
  if (typeof secret !== "string" || secret.length < 32) {
    throw new Error("grant signing secret must be at least 32 characters");
  }
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(canonicalGrantPayload(input)),
  );
  return bytesToBase64url(new Uint8Array(signature));
}

export async function verifyGrantSignature(input, signature, secret) {
  if (typeof secret !== "string" || secret.length < 32) return false;
  try {
    const key = await crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["verify"],
    );
    return crypto.subtle.verify(
      "HMAC",
      key,
      base64urlToBytes(signature),
      new TextEncoder().encode(canonicalGrantPayload(input)),
    );
  } catch {
    return false;
  }
}

export function randomBase64url(byteLength = 24) {
  const bytes = new Uint8Array(byteLength);
  crypto.getRandomValues(bytes);
  return bytesToBase64url(bytes);
}

export function validateRunGrantRequest(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    return "request body must be an object";
  }
  if (typeof input.run_id !== "string" || !RUN_ID_PATTERN.test(input.run_id)) {
    return "run_id is invalid";
  }
  if (
    typeof input.device_id !== "string" ||
    !DEVICE_ID_PATTERN.test(input.device_id)
  ) {
    return "device_id is invalid";
  }
  if (
    typeof input.plan_hash !== "string" ||
    !HASH_PATTERN.test(input.plan_hash)
  ) {
    return "plan_hash is invalid";
  }
  if (
    !input.scope ||
    typeof input.scope !== "object" ||
    Array.isArray(input.scope)
  ) {
    return "scope must be an object";
  }
  if (
    (input.scope.run_id !== undefined && input.scope.run_id !== input.run_id) ||
    (input.scope.target_device_id !== undefined &&
      input.scope.target_device_id !== input.device_id) ||
    (input.scope.plan_hash !== undefined &&
      input.scope.plan_hash !== input.plan_hash)
  ) {
    return "scope binding does not match request";
  }
  if (
    !Number.isInteger(input.ttl_seconds) ||
    input.ttl_seconds < 30 ||
    input.ttl_seconds > 600
  ) {
    return "ttl_seconds must be between 30 and 600";
  }
  return null;
}

export function validateGrantProof(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    return "request body must be an object";
  }
  if (
    typeof input.grant_id !== "string" ||
    !input.grant_id.startsWith("grant_") ||
    !ID_PATTERN.test(input.grant_id.slice("grant_".length))
  ) {
    return "grant_id is invalid";
  }
  if (
    typeof input.device_id !== "string" ||
    !DEVICE_ID_PATTERN.test(input.device_id)
  ) {
    return "device_id is invalid";
  }
  if (
    typeof input.nonce !== "string" ||
    input.nonce.length < 16 ||
    input.nonce.length > 128 ||
    !BASE64URL_PATTERN.test(input.nonce)
  ) {
    return "nonce is invalid";
  }
  if (
    typeof input.signature !== "string" ||
    input.signature.length < 43 ||
    input.signature.length > 256 ||
    !BASE64URL_PATTERN.test(input.signature)
  ) {
    return "signature is invalid";
  }
  return null;
}

export function validateTerminalSessionRequest(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    return "request body must be an object";
  }
  if (
    typeof input.session_id !== "string" ||
    !SESSION_ID_PATTERN.test(input.session_id)
  ) {
    return "session_id is invalid";
  }
  const grantError = validateGrantProof(input);
  if (grantError) return grantError;
  if (typeof input.run_id !== "string" || !RUN_ID_PATTERN.test(input.run_id)) {
    return "run_id is invalid";
  }
  if (
    typeof input.transport !== "string" ||
    !["webrtc", "relay"].includes(input.transport)
  ) {
    return "transport is invalid";
  }
  if (
    typeof input.initiated_by !== "string" ||
    !["desktop", "mobile", "web"].includes(input.initiated_by)
  ) {
    return "initiated_by is invalid";
  }
  if (
    !input.scope ||
    typeof input.scope !== "object" ||
    Array.isArray(input.scope)
  ) {
    return "scope must be an object";
  }
  if (typeof input.scope.read_only !== "boolean") {
    return "scope.read_only must be boolean";
  }
  return null;
}

export function validateTerminalSignalRequest(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    return "request body must be an object";
  }
  if (
    typeof input.signal_id !== "string" ||
    !SIGNAL_ID_PATTERN.test(input.signal_id)
  ) {
    return "signal_id is invalid";
  }
  if (
    typeof input.session_id !== "string" ||
    !SESSION_ID_PATTERN.test(input.session_id)
  ) {
    return "session_id is invalid";
  }
  if (
    typeof input.signal_type !== "string" ||
    !["offer", "answer", "ice_candidate", "renegotiate", "close"].includes(
      input.signal_type,
    )
  ) {
    return "signal_type is invalid";
  }
  if (
    !input.payload ||
    typeof input.payload !== "object" ||
    Array.isArray(input.payload)
  ) {
    return "payload must be an object";
  }
  if (
    typeof input.payload_hash !== "string" ||
    !/^[a-f0-9]{64}$/.test(input.payload_hash)
  ) {
    return "payload_hash is invalid";
  }
  return null;
}

export async function sha256Hex(value) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}
