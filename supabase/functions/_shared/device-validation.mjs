const ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_-]{7,95}$/;
const DEVICE_ID_PATTERN = /^device_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$/;
const APP_VERSION_PATTERN = /^\d+\.\d+\.\d+$/;
const BASE64URL_PATTERN = /^[A-Za-z0-9_-]+$/;
const PLATFORMS = new Set(["macos", "windows", "linux", "android", "ios"]);
const ARCHITECTURES = new Set(["x64", "arm64", "armv7"]);
const CAPABILITIES = new Set([
  "workflow_execution",
  "pty",
  "webrtc",
  "clipboard",
]);

export function validateRegistrationInput(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    return "request body must be an object";
  }
  if (
    typeof input.device_id !== "string" ||
    !DEVICE_ID_PATTERN.test(input.device_id)
  ) {
    return "device_id is invalid";
  }
  if (
    typeof input.name !== "string" ||
    input.name.length < 1 ||
    input.name.length > 120
  ) {
    return "name is invalid";
  }
  if (typeof input.platform !== "string" || !PLATFORMS.has(input.platform)) {
    return "platform is invalid";
  }
  if (
    typeof input.architecture !== "string" ||
    !ARCHITECTURES.has(input.architecture)
  ) {
    return "architecture is invalid";
  }
  if (
    typeof input.app_version !== "string" ||
    !APP_VERSION_PATTERN.test(input.app_version)
  ) {
    return "app_version is invalid";
  }
  if (input.key_algorithm !== "ed25519") {
    return "key_algorithm must be ed25519";
  }
  if (!Number.isInteger(input.key_version) || input.key_version < 1) {
    return "key_version is invalid";
  }
  if (
    typeof input.public_key !== "string" ||
    input.public_key.length < 43 ||
    input.public_key.length > 256 ||
    !BASE64URL_PATTERN.test(input.public_key)
  ) {
    return "public_key must be base64url encoded";
  }
  if (
    !input.capabilities ||
    typeof input.capabilities !== "object" ||
    Array.isArray(input.capabilities)
  ) {
    return "capabilities must be an object";
  }
  for (const [name, granted] of Object.entries(input.capabilities)) {
    if (!CAPABILITIES.has(name) || typeof granted !== "boolean") {
      return "capabilities contains an invalid entry";
    }
  }
  return null;
}

export function validatePairingInput(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    return "request body must be an object";
  }
  if (
    typeof input.challenge_id !== "string" ||
    !/^pairing_/.test(input.challenge_id) ||
    !ID_PATTERN.test(input.challenge_id.slice(8))
  ) {
    return "challenge_id is invalid";
  }
  if (
    typeof input.device_id !== "string" ||
    !DEVICE_ID_PATTERN.test(input.device_id)
  ) {
    return "device_id is invalid";
  }
  if (
    typeof input.challenge !== "string" ||
    input.challenge.length < 32 ||
    input.challenge.length > 256 ||
    !BASE64URL_PATTERN.test(input.challenge)
  ) {
    return "challenge is invalid";
  }
  if (
    typeof input.signature !== "string" ||
    input.signature.length < 86 ||
    input.signature.length > 256 ||
    !BASE64URL_PATTERN.test(input.signature)
  ) {
    return "signature must be base64url encoded";
  }
  return null;
}

export function base64urlToBytes(value) {
  const normalized = value
    .replace(/-/g, "+")
    .replace(/_/g, "/")
    .padEnd(Math.ceil(value.length / 4) * 4, "=");
  const binary = atob(normalized);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
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
