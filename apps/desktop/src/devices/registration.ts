import type { DeviceKeyProvider, DeviceKeyReference } from "./device-keys";
import {
  discoverCapabilities,
  platformName,
  type DeviceCapabilities,
} from "./capabilities";

export type DeviceRegistrationInput = {
  deviceId: string;
  name: string;
  appVersion: string;
  architecture: "x64" | "arm64" | "armv7" | "universal";
  accessToken: string;
};

export type RegisteredDevice = {
  device_id: string;
  status: string;
  challenge_id: string;
  challenge: string;
};

export type RegistrationTransport = (
  input: RequestInfo | URL,
  init?: RequestInit,
) => Promise<Response>;

export class DeviceRegistrar {
  constructor(
    private readonly supabaseUrl: string,
    private readonly anonKey: string,
    private readonly keys: DeviceKeyProvider,
    private readonly transport: RegistrationTransport = fetch,
  ) {}

  async register(
    input: DeviceRegistrationInput,
    capabilities: DeviceCapabilities = discoverCapabilities(),
  ) {
    const key: DeviceKeyReference = await this.keys.generate(input.deviceId);
    const response = await this.transport(
      `${this.supabaseUrl}/functions/v1/register-device`,
      {
        method: "POST",
        headers: {
          apikey: this.anonKey,
          Authorization: `Bearer ${input.accessToken}`,
          "content-type": "application/json",
        },
        body: JSON.stringify({
          device_id: input.deviceId,
          name: input.name,
          platform: platformName(),
          architecture: input.architecture,
          app_version: input.appVersion,
          public_key: key.publicKey,
          key_algorithm: key.algorithm,
          key_version: key.version,
          capabilities,
        }),
      },
    );
    const body = (await response.json()) as
      | RegisteredDevice
      | { error?: string };
    if (!response.ok || !("challenge_id" in body))
      throw new Error("device registration failed");
    return { device: body, key };
  }
}
