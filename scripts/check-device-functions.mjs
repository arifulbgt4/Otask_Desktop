import assert from "node:assert/strict";
import {
  sha256Hex,
  validatePairingInput,
  validateRevocationInput,
  validateRegistrationInput,
  validateRotationInput,
} from "../supabase/functions/_shared/device-validation.mjs";

const validRegistration = {
  device_id: "device_p02007_test",
  name: "Test device",
  platform: "linux",
  architecture: "x64",
  app_version: "1.0.0",
  key_algorithm: "ed25519",
  key_version: 1,
  public_key: "A".repeat(43),
  capabilities: { workflow_execution: true, clipboard: false },
};

assert.equal(validateRegistrationInput(validRegistration), null);
assert.match(
  validateRegistrationInput({ ...validRegistration, platform: "unknown" }),
  /platform/,
);
assert.match(
  validateRegistrationInput({ ...validRegistration, key_algorithm: "rsa" }),
  /ed25519/,
);
assert.match(
  validateRegistrationInput({ ...validRegistration, public_key: "secret" }),
  /base64url/,
);

const validPairing = {
  challenge_id: "pairing_p02007_test",
  device_id: validRegistration.device_id,
  challenge: "A".repeat(43),
  signature: "B".repeat(86),
};
assert.equal(validatePairingInput(validPairing), null);
assert.match(
  validatePairingInput({ ...validPairing, challenge_id: "pairing_short" }),
  /challenge_id/,
);
assert.match(
  validatePairingInput({ ...validPairing, signature: "bad" }),
  /signature/,
);
const validRotation = {
  device_id: validRegistration.device_id,
  current_key_version: 1,
  new_key_version: 2,
  new_public_key: "C".repeat(43),
  signature: "D".repeat(86),
};
assert.equal(validateRotationInput(validRotation), null);
assert.match(
  validateRotationInput({ ...validRotation, new_key_version: 1 }),
  /increase/,
);
assert.equal(
  validateRevocationInput({
    device_id: validRegistration.device_id,
    reason: "lost",
  }),
  null,
);
assert.match(
  validateRevocationInput({
    device_id: validRegistration.device_id,
    reason: "x".repeat(501),
  }),
  /reason/,
);
assert.equal(
  await sha256Hex("otask-pairing"),
  "666f7f3c5d7b377a6f711d480418dedf9fdd5ee5aaaf274dc16a2a9e30c66031",
);

console.log(
  "device functions: validation and challenge hashing fixtures passed",
);
