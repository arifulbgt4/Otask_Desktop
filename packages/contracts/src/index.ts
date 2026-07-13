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

export type ExecutionState =
  | "draft"
  | "validated"
  | "awaiting_approval"
  | "queued"
  | "running"
  | "success"
  | "failed"
  | "cancelled"
  | "timeout"
  | "evidence_finalized"
  | "synced"
  | "rejected"
  | "expired"
  | "retry_queued";

export const EXECUTION_TRANSITIONS: Readonly<
  Record<ExecutionState, readonly ExecutionState[]>
> = {
  draft: ["validated", "rejected"],
  validated: ["awaiting_approval", "queued"],
  awaiting_approval: ["queued", "cancelled", "expired"],
  queued: ["running", "cancelled", "expired"],
  running: ["success", "failed", "cancelled", "timeout"],
  success: ["evidence_finalized"],
  failed: ["evidence_finalized", "retry_queued"],
  cancelled: ["evidence_finalized"],
  timeout: ["evidence_finalized", "retry_queued"],
  evidence_finalized: ["synced"],
  synced: [],
  rejected: [],
  expired: [],
  retry_queued: ["queued", "cancelled", "expired"],
};

export function isLegalExecutionTransition(
  from: ExecutionState,
  to: ExecutionState,
): boolean {
  return EXECUTION_TRANSITIONS[from].includes(to);
}

export function asOTaskId(value: string): OTaskId {
  return value as OTaskId;
}

export function asTimestamp(value: string): Timestamp {
  return value as Timestamp;
}
