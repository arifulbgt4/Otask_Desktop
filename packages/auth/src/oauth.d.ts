export type PkceTransaction = {
  state: string;
  verifier: string;
  challenge: string;
  redirectUri: string;
  createdAt: number;
  expiresAt: number;
};

export function sha256Base64Url(value: string): Promise<string>;
export function createPkceTransaction(input?: {
  redirectUri?: string;
  now?: number;
  ttlMs?: number;
}): Promise<PkceTransaction>;
export function buildGoogleAuthorizeUrl(input: {
  supabaseUrl: string;
  transaction: PkceTransaction;
  prompt?: string;
}): string;
export function validateOAuthCallback(
  rawUrl: string,
  transaction: PkceTransaction | null | undefined,
  now?: number,
):
  | { kind: "success"; code: string; state: string }
  | { kind: "error"; code: string; description?: string };
