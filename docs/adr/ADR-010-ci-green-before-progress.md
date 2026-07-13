# ADR-010: CI-green-before-progress continuation rule

Status: Accepted

Required checks are a workflow gate. A failed or pending required check blocks
task completion, merge, release, and advancement to unrelated backlog work.
