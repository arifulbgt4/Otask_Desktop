import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import {
  validateTerminalSessionRequest,
  verifyGrantSignature,
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
  if (!url || !anonKey || !serviceRoleKey || !signingSecret)
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
  const validationError = validateTerminalSessionRequest(input);
  if (validationError)
    return json({ error: "invalid_request", message: validationError }, 400);

  const serviceClient = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
  const { data: grant, error: grantError } = await serviceClient
    .from("session_grants")
    .select(
      "grant_id, grant_type, user_id, device_id, run_id, plan_hash, scope, issued_at, expires_at, nonce, signature, revoked_at, used_at",
    )
    .eq("grant_id", input.grant_id as string)
    .eq("user_id", user.id)
    .maybeSingle();
  if (grantError || !grant)
    return json({ error: "terminal_grant_not_found" }, 404);
  if (grant.grant_type !== "terminal")
    return json({ error: "terminal_grant_required" }, 409);
  if (grant.device_id !== input.device_id || grant.run_id !== input.run_id)
    return json({ error: "terminal_grant_target_mismatch" }, 403);

  const validSignature = await verifyGrantSignature(
    grant,
    input.signature as string,
    signingSecret,
  );
  if (!validSignature || grant.signature !== input.signature)
    return json({ error: "terminal_grant_signature_invalid" }, 403);

  const { data, error } = await serviceClient.rpc(
    "initialize_terminal_session",
    {
      p_session_id: input.session_id,
      p_grant_id: input.grant_id,
      p_user_id: user.id,
      p_device_id: input.device_id,
      p_run_id: input.run_id,
      p_transport: input.transport,
      p_initiated_by: input.initiated_by,
      p_scope: input.scope,
    },
  );
  if (error) return json({ error: "terminal_session_rejected" }, 409);
  return json(data, 201);
});
