import { invoke } from "@tauri-apps/api/core";

export const secureCredentialNames = [
  "auth.accessToken",
  "auth.refreshToken",
  "device.privateKey",
] as const;

export type SecureCredentialName = (typeof secureCredentialNames)[number];

export interface SecureCredentialStore {
  get(name: SecureCredentialName): Promise<string | null>;
  set(name: SecureCredentialName, value: string): Promise<void>;
  delete(name: SecureCredentialName): Promise<void>;
}

const validName = (name: string): name is SecureCredentialName =>
  secureCredentialNames.includes(name as SecureCredentialName);

const validateValue = (value: string) => {
  if (value.length === 0 || value.length > 16_384)
    throw new Error("credential value must be between 1 and 16384 characters");
};

/** IPC-backed store. Native commands must map to the OS keychain/keyring. */
export class TauriCredentialStore implements SecureCredentialStore {
  async get(name: SecureCredentialName) {
    if (!validName(name)) throw new Error("credential name is not allowlisted");
    return invoke<string | null>("credential_get", { name });
  }

  async set(name: SecureCredentialName, value: string) {
    if (!validName(name)) throw new Error("credential name is not allowlisted");
    validateValue(value);
    await invoke("credential_set", { name, value });
  }

  async delete(name: SecureCredentialName) {
    if (!validName(name)) throw new Error("credential name is not allowlisted");
    await invoke("credential_delete", { name });
  }
}

/** Development-only fallback; values disappear with the renderer process. */
export class MemoryCredentialStore implements SecureCredentialStore {
  private readonly values = new Map<SecureCredentialName, string>();

  async get(name: SecureCredentialName) {
    return this.values.get(name) ?? null;
  }

  async set(name: SecureCredentialName, value: string) {
    validateValue(value);
    this.values.set(name, value);
  }

  async delete(name: SecureCredentialName) {
    this.values.delete(name);
  }
}

export const isTauriRuntime = () =>
  typeof window !== "undefined" &&
  Object.prototype.hasOwnProperty.call(window, "__TAURI_INTERNALS__");

export const createCredentialStore = (): SecureCredentialStore =>
  isTauriRuntime() ? new TauriCredentialStore() : new MemoryCredentialStore();
