# Signed release downloads

`release_artifacts` remains the metadata and publication gate. The
`signed-download-url` Edge Function calls the service-only
`get_release_artifact_for_download` function, which accepts only a published,
non-revoked artifact whose `published_at` is not in the future. It then converts
the constrained `storage://releases/...` reference into a private Storage
object path and asks Supabase Storage for a short-lived signed URL.

Callers choose a TTL from 30 to 600 seconds. The response includes the release
version, platform/architecture, artifact kind, content hash, signature, size,
signed URL, and expiry. Draft or revoked metadata never reaches Storage URL
signing, and no service-role key is exposed to callers.
