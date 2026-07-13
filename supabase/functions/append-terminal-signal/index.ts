import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import {
  sha256Hex,
  validateTerminalSignalRequest,
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
  const validationError = validateTerminalSignalRequest(input);
  if (validationError)
    return json({ error: "invalid_request", message: validationError }, 400);

  const expectedHash = await sha256Hex(JSON.stringify(input.payload));
  if (expectedHash !== input.payload_hash)
    return json({ error: "signal_payload_hash_invalid" }, 400);

  const serviceClient = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
  const { data, error } = await serviceClient.rpc("append_terminal_signal", {
    p_signal_id: input.signal_id,
    p_session_id: input.session_id,
    p_user_id: user.id,
    p_sender: "client",
    p_signal_type: input.signal_type,
    p_payload: input.payload,
    p_payload_hash: input.payload_hash,
  });
  if (error) return json({ error: "terminal_signal_rejected" }, 409);
  return json(data, 201);
});
