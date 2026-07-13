# Terminal sessions and signaling

P02-010 keeps interactive terminal control state in `terminal_sessions` and
short-lived negotiation messages in `terminal_signals`. The database never
carries terminal bytes: WebRTC DataChannels (or the visible relay fallback)
carry the encrypted stream, while Supabase Realtime carries only these state
and signaling records.

`initialize-terminal-session` accepts an authenticated user's env-signed
terminal grant, verifies the grant's owner/device/run/scope binding, consumes it
once, and creates a `requested` session with an expiry. A session is limited to
`webrtc` or `relay`, a declared initiator, and an explicit `scope.read_only`
flag.

`append-terminal-signal` hashes the JSON payload before calling the service-only
append function. Signals have a unique per-session sequence, allowed types
(`offer`, `answer`, `ice_candidate`, `renegotiate`, `close`), expiry, and an
append-only trigger. A `close` signal moves the session to `closing`; closed,
expired, rejected, cancelled, or foreign-owner sessions cannot accept signals.

No client receives a service-role credential, and no shell command or terminal
output is sent through these records.
