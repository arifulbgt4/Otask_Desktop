export type DesktopRoute =
  | "dashboard"
  | "devices"
  | "workflows"
  | "schedules"
  | "approvals"
  | "runs"
  | "reports"
  | "sync"
  | "settings";

export type NavigationItem = {
  id: DesktopRoute;
  label: string;
  description: string;
  group: "operate" | "observe" | "configure";
};

export const navigationItems: readonly NavigationItem[] = [
  {
    id: "dashboard",
    label: "Dashboard",
    description: "Overview and next actions",
    group: "operate",
  },
  {
    id: "devices",
    label: "Devices",
    description: "Trusted endpoints and capabilities",
    group: "operate",
  },
  {
    id: "workflows",
    label: "Workflows",
    description: "Reusable task plans",
    group: "operate",
  },
  {
    id: "schedules",
    label: "Schedules",
    description: "Durable triggers and dispatch",
    group: "operate",
  },
  {
    id: "approvals",
    label: "Approvals",
    description: "Review high-risk actions",
    group: "operate",
  },
  {
    id: "runs",
    label: "Run Monitor",
    description: "Live execution state",
    group: "observe",
  },
  {
    id: "reports",
    label: "Reports",
    description: "Evidence and outcomes",
    group: "observe",
  },
  {
    id: "sync",
    label: "Sync Health",
    description: "Connectivity and outbox status",
    group: "observe",
  },
  {
    id: "settings",
    label: "Settings",
    description: "Account, security, and appearance",
    group: "configure",
  },
];

export const routeById = Object.fromEntries(
  navigationItems.map((item) => [item.id, item]),
) as Record<DesktopRoute, NavigationItem>;
