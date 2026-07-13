# OTask authentication contract

OTask uses Supabase Auth with Google OAuth for local/dev. Browser and native
clients start the flow in the system browser and use the authorization-code
flow with PKCE. No embedded WebView, Google client secret, service-role key, or
access token is shipped in a client.

## Local provider configuration

`supabase/config.toml` is the source of truth for local GoTrue configuration:

- Google is enabled through `SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID` and
  `SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_SECRET` environment variables.
- Google Cloud's authorized redirect URI is
  `http://127.0.0.1:54321/auth/v1/callback`.
- Supabase's post-login allowlist contains the web callbacks
  `http://localhost:3000/auth/callback` and
  `http://127.0.0.1:3000/auth/callback`, plus the native
  `otask://auth/callback` scheme.
- Nonce validation stays enabled (`skip_nonce_check = false`).

Copy the placeholders in `supabase/.env.example` into a local, untracked
`.env` only after creating a Google OAuth Web client. Never put real values in
Git, app bundles, CI logs, or mobile configuration.

## Callback rules

1. The start request must include an exact allowlisted `redirectTo` value and a
   PKCE challenge.
2. The callback accepts an authorization `code` only when `state` is present;
   the client exchanges the code with the same PKCE verifier and then clears
   the URL.
3. `error`, `error_description`, missing `state`, missing `code`, fragments,
   and unregistered redirect schemes are handled as a signed-out error state.
4. Native clients open the system browser and receive the result through the
   `otask://auth/callback` deep link. They do not use an embedded WebView.

The reusable parser and redirect tests live in `packages/auth`; the Flutter
callback contract is covered by `apps/mobile/test/auth_callback_test.dart`.
Run `pnpm auth:check` and the normal workspace checks before changing these
redirects. Any production URL must be added explicitly rather than using a
wildcard.

References: [Supabase Google provider setup](https://supabase.com/docs/guides/auth/social-login/auth-google),
[Supabase redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls),
and [RFC 8252](https://www.rfc-editor.org/rfc/rfc8252).
