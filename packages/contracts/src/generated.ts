/**
 * Generated internal mapping surface for the versioned JSON Schemas.
 * Do not hand-edit schema names here; `check-mappings.mjs` is the guard.
 */
export const GENERATED_CONTRACT_SCHEMA_VERSION = "1.0" as const;

export const GENERATED_SCHEMA_FILES = [
  "common.schema.json",
  "error-envelope.schema.json",
  "event-envelope.schema.json",
  "task-plan.schema.json",
  "execution-state.schema.json",
  "execution-event.schema.json",
  "schedule.schema.json",
  "approval.schema.json",
  "device.schema.json",
  "run-grant.schema.json",
  "evidence.schema.json",
  "artifact.schema.json",
  "clipboard.schema.json",
  "compatibility.schema.json",
] as const;

export type GeneratedId = string;
export type GeneratedTimestamp = string;

export interface GeneratedSchedule {
  schema_version: "1.0";
  schedule_id: GeneratedId;
  workflow_version_id: GeneratedId;
  target_device_id: GeneratedId;
  timezone: string;
  trigger: Record<string, unknown>;
  next_run_at: GeneratedTimestamp | null;
  approval_mode: "always" | "first_run" | "risk_change" | "preapproved";
  lateness_policy: "skip" | "run_immediately" | "ask";
  retry_policy: Record<string, unknown>;
  preconditions: Record<string, unknown>;
  enabled: boolean;
  revision: number;
}

export interface GeneratedDevice {
  schema_version: "1.0";
  device_id: GeneratedId;
  user_id: GeneratedId;
  name: string;
  platform: "macos" | "windows" | "linux" | "android" | "ios";
  architecture: "x64" | "arm64" | "armv7";
  app_version: string;
  capabilities: Record<string, boolean>;
  status: "pairing" | "trusted" | "offline" | "revoked";
  last_seen_at?: GeneratedTimestamp | null;
  key_version: number;
  revision: number;
}

export interface GeneratedArtifact {
  schema_version: "1.0";
  artifact_id: GeneratedId;
  run_id: GeneratedId;
  kind: "log" | "file" | "screenshot" | "manifest";
  content_hash: string;
  size_bytes: number;
  mime_type: string;
  storage_ref: string;
  redacted: boolean;
  created_at: GeneratedTimestamp;
}
