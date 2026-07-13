pub const CRATE_NAME: &str = "otask-domain";
pub const CONTRACT_SCHEMA_VERSION: &str = "1.0";

/// Generated schema manifest; checked against packages/contracts/src/generated.ts.
pub const GENERATED_SCHEMA_FILES: &[&str] = &[
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
];

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ExecutionState {
    Draft,
    Validated,
    AwaitingApproval,
    Queued,
    Running,
    Success,
    Failed,
    Cancelled,
    Timeout,
    EvidenceFinalized,
    Synced,
    Rejected,
    Expired,
    RetryQueued,
}

pub fn is_legal_transition(from: ExecutionState, to: ExecutionState) -> bool {
    use ExecutionState::*;
    matches!(
        (from, to),
        (Draft, Validated | Rejected)
            | (Validated, AwaitingApproval | Queued)
            | (AwaitingApproval, Queued | Cancelled | Expired)
            | (Queued, Running | Cancelled | Expired)
            | (Running, Success | Failed | Cancelled | Timeout)
            | (Success, EvidenceFinalized)
            | (Failed, EvidenceFinalized | RetryQueued)
            | (Cancelled, EvidenceFinalized)
            | (Timeout, EvidenceFinalized | RetryQueued)
            | (EvidenceFinalized, Synced)
            | (RetryQueued, Queued | Cancelled | Expired)
    )
}
