export const otaskTokens = {
  version: "1.0",
  color: {
    canvas: "#0B1020",
    surface: "#151D33",
    surfaceRaised: "#202A44",
    textPrimary: "#F8FAFC",
    textMuted: "#CBD5E1",
    border: "#475569",
    focus: "#FACC15",
    accent: "#38BDF8",
    status: {
      success: { background: "#14532D", foreground: "#DCFCE7" },
      warning: { background: "#713F12", foreground: "#FEF3C7" },
      danger: { background: "#7F1D1D", foreground: "#FEE2E2" },
      info: { background: "#0C4A6E", foreground: "#E0F2FE" },
      neutral: { background: "#334155", foreground: "#F1F5F9" },
    },
  },
  interaction: {
    minimumTarget: 44,
    focusRingWidth: 3,
    reducedMotionDuration: 0,
  },
} as const;

export type RiskLevel = "low" | "medium" | "high" | "critical";
export type StatusTone = keyof typeof otaskTokens.color.status;
