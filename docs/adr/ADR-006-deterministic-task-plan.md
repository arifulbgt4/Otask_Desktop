# ADR-006: Deterministic TaskPlan boundary

Status: Accepted

AI output is untrusted data. A versioned JSON Schema, typed-step validators,
capability policy, approvals, and deterministic success criteria are required
before execution. Model text can never set authoritative run status.
