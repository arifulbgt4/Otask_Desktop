export const CURRENT_CONTRACT_VERSION = "1.0" as const;
export const SUPPORTED_CONTRACT_VERSIONS = [CURRENT_CONTRACT_VERSION] as const;

export type ContractVersion = (typeof SUPPORTED_CONTRACT_VERSIONS)[number];

export function isSupportedContractVersion(
  version: string,
): version is ContractVersion {
  return (SUPPORTED_CONTRACT_VERSIONS as readonly string[]).includes(version);
}

export function assertSupportedContractVersion(
  version: string,
): asserts version is ContractVersion {
  if (!isSupportedContractVersion(version)) {
    throw new Error(`Unsupported OTask contract version: ${version}`);
  }
}
