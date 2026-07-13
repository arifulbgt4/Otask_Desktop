/** Shared, internal contract vocabulary. JSON Schemas remain authoritative. */
export type OTaskId = string & { readonly __brand: "OTaskId" };
export type Timestamp = string & { readonly __brand: "Timestamp" };
export type Revision = number & { readonly __brand: "Revision" };

export type ErrorEnvelope = {
  ok: false;
  error: {
    code: string;
    message: string;
    retryable: boolean;
    details?: Record<string, unknown>;
  };
  request_id: OTaskId;
  occurred_at: Timestamp;
};

export type EventEnvelope = {
  event_id: OTaskId;
  event_type: string;
  aggregate_type:
    | "device"
    | "workflow"
    | "schedule"
    | "run"
    | "approval"
    | "terminal_session"
    | "artifact";
  aggregate_id: OTaskId;
  revision: Revision;
  occurred_at: Timestamp;
  producer: "desktop" | "mobile" | "web" | "cloud";
  trace_id: OTaskId;
  payload: Record<string, unknown>;
};

export const CONTRACT_SCHEMA_VERSION = "1.0" as const;

export function asOTaskId(value: string): OTaskId {
  return value as OTaskId;
}

export function asTimestamp(value: string): Timestamp {
  return value as Timestamp;
}
