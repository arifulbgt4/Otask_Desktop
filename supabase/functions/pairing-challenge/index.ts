import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import {
  base64urlToBytes,
  sha256Hex,
  validatePairingInput,
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
  challenge: string,
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
    new TextEncoder().encode(challenge),
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
  const validationError = validatePairingInput(input);
  if (validationError)
    return json({ error: "invalid_request", message: validationError }, 400);
  const challengeId = input.challenge_id as string;
  const deviceId = input.device_id as string;
  const challengeValue = input.challenge as string;
  const signature = input.signature as string;

  const serviceClient = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
  const { data: challenge, error: challengeError } = await serviceClient
    .from("device_pairing_challenges")
    .select(
      "challenge_id, device_id, user_id, challenge_hash, expires_at, consumed_at, attempt_count",
    )
    .eq("challenge_id", challengeId)
    .eq("device_id", deviceId)
    .eq("user_id", user.id)
    .maybeSingle();
  if (challengeError || !challenge)
    return json({ error: "pairing_challenge_not_found" }, 404);
  if (challenge.consumed_at)
    return json({ error: "pairing_challenge_consumed" }, 409);
  if (
    new Date(challenge.expires_at).getTime() <= Date.now() ||
    challenge.attempt_count >= 5
  ) {
    return json({ error: "pairing_challenge_expired" }, 410);
  }

  const challengeHash = await sha256Hex(challengeValue);
  if (challengeHash !== challenge.challenge_hash)
    return json({ error: "pairing_challenge_invalid" }, 403);

  const { data: key, error: keyError } = await serviceClient
    .from("device_keys")
    .select("public_key")
    .eq("device_id", deviceId)
    .is("revoked_at", null)
    .order("version", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (keyError || !key) return json({ error: "device_key_not_found" }, 404);

  let valid = false;
  try {
    valid = await verifySignature(key.public_key, challengeValue, signature);
  } catch {
    valid = false;
  }
  if (!valid) {
    await serviceClient
      .from("device_pairing_challenges")
      .update({ attempt_count: challenge.attempt_count + 1 })
      .eq("challenge_id", challengeId)
      .is("consumed_at", null);
    return json({ error: "pairing_signature_invalid" }, 403);
  }

  const { error: consumeError } = await serviceClient
    .from("device_pairing_challenges")
    .update({ consumed_at: new Date().toISOString() })
    .eq("challenge_id", challengeId)
    .is("consumed_at", null);
  if (consumeError) return json({ error: "pairing_consume_failed" }, 409);

  const { error: deviceError } = await serviceClient
    .from("devices")
    .update({ status: "trusted", last_seen_at: new Date().toISOString() })
    .eq("device_id", deviceId)
    .eq("user_id", user.id)
    .eq("status", "pairing");
  if (deviceError) return json({ error: "device_trust_update_failed" }, 500);

  return json({ device_id: deviceId, status: "trusted" });
});
