import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { validateReleaseDownloadRequest } from "../_shared/run-grant.mjs";

const corsHeaders = {
  "Access-Control-Allow-Headers": "content-type, x-client-info, apikey",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Origin": "*",
  "Content-Type": "application/json",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { headers: corsHeaders, status });

Deno.serve(async (request) => {
  if (request.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST")
    return json({ error: "method_not_allowed" }, 405);

  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey)
    return json({ error: "server_not_configured" }, 500);

  let input: Record<string, unknown>;
  try {
    input = await request.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }
  const validationError = validateReleaseDownloadRequest(input);
  if (validationError)
    return json({ error: "invalid_request", message: validationError }, 400);

  const serviceClient = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
  const { data: artifact, error: artifactError } = await serviceClient.rpc(
    "get_release_artifact_for_download",
    { p_release_artifact_id: input.release_artifact_id },
  );
  if (artifactError || !artifact)
    return json({ error: "release_artifact_not_downloadable" }, 404);

  const downloadRef = artifact.download_ref as string;
  const prefix = "storage://releases/";
  if (!downloadRef.startsWith(prefix))
    return json({ error: "release_storage_ref_invalid" }, 500);
  const objectPath = downloadRef.slice(prefix.length);
  const expiresIn = input.expires_in as number;
  const { data: signed, error: signedError } = await serviceClient.storage
    .from("releases")
    .createSignedUrl(objectPath, expiresIn);
  if (signedError || !signed?.signedUrl)
    return json({ error: "release_signed_url_failed" }, 503);

  return json({
    release_artifact_id: artifact.release_artifact_id,
    release_version: artifact.release_version,
    channel: artifact.channel,
    platform: artifact.platform,
    architecture: artifact.architecture,
    artifact_kind: artifact.artifact_kind,
    content_hash: artifact.content_hash,
    size_bytes: artifact.size_bytes,
    signature: artifact.signature,
    signed_url: signed.signedUrl,
    expires_at: new Date(Date.now() + expiresIn * 1000).toISOString(),
  });
});
