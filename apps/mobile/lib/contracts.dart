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
  'compatibility.schema.json',
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

const Map<ExecutionState, Set<ExecutionState>> executionTransitions =
    <ExecutionState, Set<ExecutionState>>{
  ExecutionState.draft: <ExecutionState>{
    ExecutionState.validated,
    ExecutionState.rejected,
  },
  ExecutionState.validated: <ExecutionState>{
    ExecutionState.awaitingApproval,
    ExecutionState.queued,
  },
  ExecutionState.awaitingApproval: <ExecutionState>{
    ExecutionState.queued,
    ExecutionState.cancelled,
    ExecutionState.expired,
  },
  ExecutionState.queued: <ExecutionState>{
    ExecutionState.running,
    ExecutionState.cancelled,
    ExecutionState.expired,
  },
  ExecutionState.running: <ExecutionState>{
    ExecutionState.success,
    ExecutionState.failed,
    ExecutionState.cancelled,
    ExecutionState.timeout,
  },
  ExecutionState.success: <ExecutionState>{ExecutionState.evidenceFinalized},
  ExecutionState.failed: <ExecutionState>{
    ExecutionState.evidenceFinalized,
    ExecutionState.retryQueued,
  },
  ExecutionState.cancelled: <ExecutionState>{ExecutionState.evidenceFinalized},
  ExecutionState.timeout: <ExecutionState>{
    ExecutionState.evidenceFinalized,
    ExecutionState.retryQueued,
  },
  ExecutionState.evidenceFinalized: <ExecutionState>{ExecutionState.synced},
  ExecutionState.synced: <ExecutionState>{},
  ExecutionState.rejected: <ExecutionState>{},
  ExecutionState.expired: <ExecutionState>{},
  ExecutionState.retryQueued: <ExecutionState>{
    ExecutionState.queued,
    ExecutionState.cancelled,
    ExecutionState.expired,
  },
};

bool isLegalExecutionTransition(ExecutionState from, ExecutionState to) =>
    executionTransitions[from]?.contains(to) ?? false;
