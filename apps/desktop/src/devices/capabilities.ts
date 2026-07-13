export type DeviceCapabilities = {
  workflow_execution: boolean;
  clipboard: boolean;
  terminal: boolean;
  screenshots: boolean;
  notifications: boolean;
};

export const discoverCapabilities = (): DeviceCapabilities => ({
  workflow_execution: true,
  clipboard: typeof navigator !== "undefined" && "clipboard" in navigator,
  terminal: typeof window !== "undefined" && "__TAURI_INTERNALS__" in window,
  screenshots: typeof window !== "undefined" && "__TAURI_INTERNALS__" in window,
  notifications: typeof Notification !== "undefined",
});

export const platformName = () => {
  const userAgent =
    typeof navigator === "undefined" ? "" : navigator.userAgent.toLowerCase();
  if (userAgent.includes("windows")) return "windows" as const;
  if (userAgent.includes("mac")) return "macos" as const;
  if (userAgent.includes("linux")) return "linux" as const;
  return "web" as const;
};
