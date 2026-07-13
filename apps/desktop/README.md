# OTask Desktop GUI

Tauri 2 + React/Vite GUI shell. The frontend package is bootstrapped here;
native Rust service work lives under `apps/desktop/src-tauri` and `crates/`.

# OTask desktop

The desktop GUI is a Tauri 2 host around a React/Vite frontend. The current
vertical slice provides the shell, typed navigation contract, dashboard state,
and safe empty states for the remaining routes.

## Development

```bash
pnpm --filter @otask/desktop-gui dev
pnpm --filter @otask/desktop-gui build
```

The Tauri configuration uses `http://127.0.0.1:1420` for development and
`../dist` for packaged frontend assets. Native service and IPC work are kept in
the later P03 tasks.

Credential names are allowlisted and routed through `SecureCredentialStore`.
The browser development fallback is process-memory-only; it never writes
tokens or keys to `localStorage`, cookies, or a plaintext settings file.

Native sign-in uses the system browser with an expiring PKCE transaction. The
desktop client accepts only the configured callback URI, exchanges the code,
refreshes sessions, and clears both secure credentials on sign-out.

Device registration generates an Ed25519 key reference through native IPC (or
an in-memory WebCrypto fallback during browser development), discovers local
capabilities, and sends only the public key to the authenticated registration
function.
