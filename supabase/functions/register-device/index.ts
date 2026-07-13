import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import {
  sha256Hex,
  validateRegistrationInput,
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

function randomBase64Url(bytes = 32) {
  const buffer = new Uint8Array(bytes);
  crypto.getRandomValues(buffer);
  return btoa(String.fromCharCode(...buffer))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
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
  const validationError = validateRegistrationInput(input);
  if (validationError)
    return json({ error: "invalid_request", message: validationError }, 400);
  const deviceId = input.device_id as string;
  const name = input.name as string;
  const platform = input.platform as string;
  const architecture = input.architecture as string;
  const appVersion = input.app_version as string;
  const publicKey = input.public_key as string;
  const keyAlgorithm = input.key_algorithm as string;
  const keyVersion = input.key_version as number;
  const capabilities = input.capabilities as Record<string, boolean>;

  const serviceClient = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
  const challenge = randomBase64Url();
  const challengeId = `pairing_${crypto.randomUUID().replaceAll("-", "")}`;
  const keyId = `device_key_${crypto.randomUUID().replaceAll("-", "")}`;
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

  const { error: deviceError } = await serviceClient.from("devices").insert({
    device_id: deviceId,
    user_id: user.id,
    name,
    platform,
    architecture,
    app_version: appVersion,
    status: "pairing",
    capabilities,
  });
  if (deviceError) return json({ error: "device_registration_failed" }, 409);

  const { error: keyError } = await serviceClient.from("device_keys").insert({
    key_id: keyId,
    device_id: deviceId,
    public_key: publicKey,
    algorithm: keyAlgorithm,
    version: keyVersion,
  });
  if (keyError) return json({ error: "device_key_registration_failed" }, 409);

  const { error: challengeError } = await serviceClient
    .from("device_pairing_challenges")
    .insert({
      challenge_id: challengeId,
      device_id: deviceId,
      user_id: user.id,
      challenge_hash: await sha256Hex(challenge),
      expires_at: expiresAt,
    });
  if (challengeError) return json({ error: "pairing_challenge_failed" }, 500);

  return json(
    {
      device_id: deviceId,
      status: "pairing",
      challenge_id: challengeId,
      challenge,
      expires_at: expiresAt,
    },
    201,
  );
});
