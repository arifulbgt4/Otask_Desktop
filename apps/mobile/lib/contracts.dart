// Generated internal mapping surface; checked against the JSON Schema manifest.
const String generatedContractSchemaVersion = '1.0';

const List<String> generatedSchemaFiles = <String>[
  'common.schema.json',
  'error-envelope.schema.json',
  'event-envelope.schema.json',
  'task-plan.schema.json',
  'execution-state.schema.json',
  'execution-event.schema.json',
  'schedule.schema.json',
  'approval.schema.json',
  'device.schema.json',
  'run-grant.schema.json',
  'evidence.schema.json',
  'artifact.schema.json',
  'clipboard.schema.json',
];

enum ExecutionState {
  draft,
  validated,
  awaitingApproval,
  queued,
  running,
  success,
  failed,
  cancelled,
  timeout,
  evidenceFinalized,
  synced,
  rejected,
  expired,
  retryQueued,
}

bool isLegalExecutionTransition(ExecutionState from, ExecutionState to) {
  return switch ((from, to)) {
    (ExecutionState.draft, ExecutionState.validated || ExecutionState.rejected) => true,
    (ExecutionState.validated, ExecutionState.awaitingApproval || ExecutionState.queued) => true,
    (ExecutionState.awaitingApproval, ExecutionState.queued || ExecutionState.cancelled || ExecutionState.expired) => true,
    (ExecutionState.queued, ExecutionState.running || ExecutionState.cancelled || ExecutionState.expired) => true,
    (ExecutionState.running, ExecutionState.success || ExecutionState.failed || ExecutionState.cancelled || ExecutionState.timeout) => true,
    (ExecutionState.success, ExecutionState.evidenceFinalized) => true,
    (ExecutionState.failed, ExecutionState.evidenceFinalized || ExecutionState.retryQueued) => true,
    (ExecutionState.cancelled, ExecutionState.evidenceFinalized) => true,
    (ExecutionState.timeout, ExecutionState.evidenceFinalized || ExecutionState.retryQueued) => true,
    (ExecutionState.evidenceFinalized, ExecutionState.synced) => true,
    (ExecutionState.retryQueued, ExecutionState.queued || ExecutionState.cancelled || ExecutionState.expired) => true,
    _ => false,
  };
}
