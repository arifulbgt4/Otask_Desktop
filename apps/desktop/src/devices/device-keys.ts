import { invoke } from "@tauri-apps/api/core";

export type DeviceKeyReference = {
  keyId: string;
  publicKey: string;
  algorithm: "ed25519";
  version: number;
};

export interface DeviceKeyProvider {
  generate(deviceId: string): Promise<DeviceKeyReference>;
  sign(keyId: string, payload: string): Promise<string>;
}

const toBase64Url = (bytes: Uint8Array) => {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
};

/** Native implementation; private keys stay inside the platform key store. */
export class TauriDeviceKeyProvider implements DeviceKeyProvider {
  generate(deviceId: string) {
    return invoke<DeviceKeyReference>("device_generate_key", { deviceId });
  }

  sign(keyId: string, payload: string) {
    return invoke<string>("device_sign", { keyId, payload });
  }
}

/** Development fallback; CryptoKey objects are non-exported and process-local. */
export class WebCryptoDeviceKeyProvider implements DeviceKeyProvider {
  private readonly keys = new Map<string, CryptoKey>();

  async generate(deviceId: string) {
    if (!deviceId) throw new Error("device ID is required");
    const pair = (await crypto.subtle.generateKey(
      { name: "Ed25519" } as AlgorithmIdentifier,
      true,
      ["sign", "verify"],
    )) as CryptoKeyPair;
    const keyId = `device_key_${crypto.randomUUID().replaceAll("-", "")}`;
    this.keys.set(keyId, pair.privateKey);
    const publicKey = await crypto.subtle.exportKey("raw", pair.publicKey);
    return {
      keyId,
      publicKey: toBase64Url(new Uint8Array(publicKey)),
      algorithm: "ed25519" as const,
      version: 1,
    };
  }

  async sign(keyId: string, payload: string) {
    const key = this.keys.get(keyId);
    if (!key) throw new Error("device key is not available in this process");
    const signature = await crypto.subtle.sign(
      { name: "Ed25519" } as AlgorithmIdentifier,
      key,
      new TextEncoder().encode(payload),
    );
    return toBase64Url(new Uint8Array(signature));
  }
}

export const isTauriDeviceRuntime = () =>
  typeof window !== "undefined" &&
  Object.prototype.hasOwnProperty.call(window, "__TAURI_INTERNALS__");

export const createDeviceKeyProvider = (): DeviceKeyProvider =>
  isTauriDeviceRuntime()
    ? new TauriDeviceKeyProvider()
    : new WebCryptoDeviceKeyProvider();
