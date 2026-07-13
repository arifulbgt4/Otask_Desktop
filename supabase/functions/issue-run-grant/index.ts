import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import {
  randomBase64url,
  signGrantPayload,
  validateRunGrantRequest,
} from "../_shared/run-grant.mjs";

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
  const signingSecret = Deno.env.get("OTASK_GRANT_SIGNING_SECRET");
  if (!url || !anonKey || !serviceRoleKey || !signingSecret) {
    return json({ error: "server_not_configured" }, 500);
  }

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
  const validationError = validateRunGrantRequest(input);
  if (validationError)
    return json({ error: "invalid_request", message: validationError }, 400);

  const runId = input.run_id as string;
  const deviceId = input.device_id as string;
  const planHash = input.plan_hash as string;
  const ttlSeconds = input.ttl_seconds as number;
  const scope = {
    ...(input.scope as Record<string, unknown>),
    run_id: runId,
    target_device_id: deviceId,
    plan_hash: planHash,
  };
  const issuedAt = new Date();
  const expiresAt = new Date(issuedAt.getTime() + ttlSeconds * 1000);
  const grant = {
    grant_id: `grant_${crypto.randomUUID().replaceAll("-", "")}`,
    grant_type: "run",
    user_id: user.id,
    device_id: deviceId,
    run_id: runId,
    plan_hash: planHash,
    scope,
    issued_at: issuedAt.toISOString(),
    expires_at: expiresAt.toISOString(),
    nonce: randomBase64url(),
  };
  const signature = await signGrantPayload(grant, signingSecret);

  const serviceClient = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
  const { data, error } = await serviceClient.rpc("issue_run_grant", {
    p_grant_id: grant.grant_id,
    p_user_id: user.id,
    p_device_id: deviceId,
    p_run_id: runId,
    p_plan_hash: planHash,
    p_scope: scope,
    p_issued_at: grant.issued_at,
    p_expires_at: grant.expires_at,
    p_nonce: grant.nonce,
    p_signature: signature,
  });
  if (error) return json({ error: "run_grant_denied" }, 409);

  return json(data);
});
