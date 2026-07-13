import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import {
  base64urlToBytes,
  validateRotationInput,
} from "../_shared/device-validation.mjs";

const corsHeaders = {
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Origin": "*",
  "Content-Type": "application/json",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { headers: corsHeaders, status });

function bearerToken(request: Request) {
  const value = request.headers.get("Authorization") ?? "";
  return value.startsWith("Bearer ") ? value.slice("Bearer ".length) : null;
}

async function verifySignature(
  publicKey: string,
  message: string,
  signature: string,
) {
  const key = await crypto.subtle.importKey(
    "raw",
    base64urlToBytes(publicKey),
    { name: "Ed25519" },
    false,
    ["verify"],
  );
  return crypto.subtle.verify(
    { name: "Ed25519" },
    key,
    base64urlToBytes(signature),
    new TextEncoder().encode(message),
  );
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST")
    return json({ error: "method_not_allowed" }, 405);
  const token = bearerToken(request);
  if (!token) return json({ error: "missing_authorization" }, 401);

  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !anonKey || !serviceRoleKey)
    return json({ error: "server_not_configured" }, 500);

  const authClient = createClient(url, anonKey, {
    auth: { persistSession: false },
  });
  const {
    data: { user },
    error: authError,
  } = await authClient.auth.getUser(token);
  if (authError || !user) return json({ error: "invalid_session" }, 401);

  let input: Record<string, unknown>;
  try {
    input = await request.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }
  const validationError = validateRotationInput(input);
  if (validationError)
    return json({ error: "invalid_request", message: validationError }, 400);
  const deviceId = input.device_id as string;
  const currentVersion = input.current_key_version as number;
  const newVersion = input.new_key_version as number;
  const newPublicKey = input.new_public_key as string;
  const signature = input.signature as string;

  const serviceClient = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
  const { data: device, error: deviceError } = await serviceClient
    .from("devices")
    .select("device_id, user_id, status")
    .eq("device_id", deviceId)
    .eq("user_id", user.id)
    .maybeSingle();
  if (deviceError || !device) return json({ error: "device_not_found" }, 404);
  if (device.status === "revoked")
    return json({ error: "device_revoked" }, 409);

  const { data: currentKey, error: keyError } = await serviceClient
    .from("device_keys")
    .select("public_key")
    .eq("device_id", deviceId)
    .eq("version", currentVersion)
    .is("revoked_at", null)
    .maybeSingle();
  if (keyError || !currentKey)
    return json({ error: "active_key_not_found" }, 404);

  const signedMessage = `${deviceId}:${newVersion}:${newPublicKey}`;
  let valid = false;
  try {
    valid = await verifySignature(
      currentKey.public_key,
      signedMessage,
      signature,
    );
  } catch {
    valid = false;
  }
  if (!valid) return json({ error: "rotation_signature_invalid" }, 403);

  const { data, error: rotationError } = await serviceClient.rpc(
    "rotate_device_key",
    {
      p_device_id: deviceId,
      p_user_id: user.id,
      p_current_version: currentVersion,
      p_new_public_key: newPublicKey,
      p_new_version: newVersion,
    },
  );
  if (rotationError) return json({ error: "device_key_rotation_failed" }, 409);
  return json(data);
});
