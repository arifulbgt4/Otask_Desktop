import {
  buildGoogleAuthorizeUrl,
  createPkceTransaction,
  validateOAuthCallback,
  type PkceTransaction,
} from "@otask/auth/oauth";
import type { SecureCredentialStore } from "../settings";

export type OAuthConfig = {
  supabaseUrl: string;
  anonKey: string;
  redirectUri: string;
};

export type OpenSystemBrowser = (url: string) => Promise<void>;

export type Session = {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  tokenType: string;
  user: { id: string; email?: string } | null;
};

export type SessionTransport = (
  input: RequestInfo | URL,
  init?: RequestInit,
) => Promise<Response>;

const authHeaders = (config: OAuthConfig) => ({
  apikey: config.anonKey,
  "content-type": "application/json",
});

async function jsonOrThrow(response: Response) {
  const body = (await response.json()) as Record<string, unknown>;
  if (!response.ok)
    throw new Error(
      String(
        body.error_description ?? body.msg ?? "authentication request failed",
      ),
    );
  return body;
}

export class DesktopOAuthClient {
  private transaction: PkceTransaction | null = null;

  constructor(
    private readonly config: OAuthConfig,
    private readonly credentials: SecureCredentialStore,
    private readonly transport: SessionTransport = fetch,
  ) {}

  async startGoogleSignIn(openSystemBrowser: OpenSystemBrowser) {
    this.transaction = await createPkceTransaction({
      redirectUri: this.config.redirectUri,
    });
    await openSystemBrowser(
      buildGoogleAuthorizeUrl({
        supabaseUrl: this.config.supabaseUrl,
        transaction: this.transaction,
      }),
    );
  }

  async finishSignIn(rawCallbackUrl: string) {
    const result = validateOAuthCallback(rawCallbackUrl, this.transaction);
    if (result.kind === "error") throw new Error(result.code);
    const response = await this.transport(
      `${this.config.supabaseUrl}/auth/v1/token?grant_type=pkce`,
      {
        method: "POST",
        headers: authHeaders(this.config),
        body: JSON.stringify({
          auth_code: result.code,
          code_verifier: this.transaction?.verifier,
        }),
      },
    );
    const body = await jsonOrThrow(response);
    const session = this.toSession(body);
    await this.persistSession(session);
    this.transaction = null;
    return session;
  }

  async refreshSession() {
    const refreshToken = await this.credentials.get("auth.refreshToken");
    if (!refreshToken) return null;
    const response = await this.transport(
      `${this.config.supabaseUrl}/auth/v1/token?grant_type=refresh_token`,
      {
        method: "POST",
        headers: authHeaders(this.config),
        body: JSON.stringify({ refresh_token: refreshToken }),
      },
    );
    const session = this.toSession(await jsonOrThrow(response));
    await this.persistSession(session);
    return session;
  }

  async signOut() {
    const accessToken = await this.credentials.get("auth.accessToken");
    if (accessToken) {
      await this.transport(`${this.config.supabaseUrl}/auth/v1/logout`, {
        method: "POST",
        headers: {
          ...authHeaders(this.config),
          Authorization: `Bearer ${accessToken}`,
        },
      });
    }
    await this.credentials.delete("auth.accessToken");
    await this.credentials.delete("auth.refreshToken");
  }

  private toSession(body: Record<string, unknown>): Session {
    if (
      typeof body.access_token !== "string" ||
      typeof body.refresh_token !== "string"
    )
      throw new Error("authentication response did not include a session");
    const user = body.user as { id?: unknown; email?: unknown } | undefined;
    if (!user || typeof user.id !== "string")
      throw new Error("authentication response did not include a user");
    return {
      accessToken: body.access_token,
      refreshToken: body.refresh_token,
      expiresIn: typeof body.expires_in === "number" ? body.expires_in : 3600,
      tokenType:
        typeof body.token_type === "string" ? body.token_type : "bearer",
      user: {
        id: user.id,
        ...(typeof user.email === "string" ? { email: user.email } : {}),
      },
    };
  }

  private async persistSession(session: Session) {
    await this.credentials.set("auth.accessToken", session.accessToken);
    await this.credentials.set("auth.refreshToken", session.refreshToken);
  }
}
