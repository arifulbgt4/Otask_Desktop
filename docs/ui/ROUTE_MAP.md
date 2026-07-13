# OTask GUI route and navigation map

The map is a GUI contract, not an API or CLI surface. The machine-readable
state contract lives in [`screen-states.json`](./screen-states.json); route
changes must update both files.

## Desktop navigation

```text
Dashboard
├── Workflows → Workflow detail → Plan review → Run monitor
├── Schedules → Schedule editor
├── Devices → Device detail → Pair/revoke
├── Approvals → Approval detail
├── Terminal sessions → Scoped terminal session
├── Evidence → Evidence report → Artifact detail
├── Model Manager → Install/verify Gemma
└── Settings → Sync Health
```

Desktop is the only execution surface. A graphical terminal is scoped to a
supervised process and always shows target, workspace, timer, route, and a
disconnect control.

## Mobile and web navigation

Mobile mirrors Dashboard, Workflows, Schedules, Approvals, Runs, Devices,
Evidence, and Settings with explicit offline states. Web provides authenticated
control pages plus public/reader-focused Learn, Docs, and Releases routes; it
never executes a local command.

## Navigation rules

- Every route exposes loading, empty, ready, error, and offline states.
- Approval and risk surfaces show exact plan version/hash, target device,
  affected steps, expiry, and a destructive-action confirmation.
- Run and terminal routes expose cancellation/disconnect without hiding it in a
  menu.
- Status uses the design-system semantic tokens and text labels; color is never
  the only state signal.
- No route represents an unrestricted shell, full remote desktop, or CLI
  administration surface.
