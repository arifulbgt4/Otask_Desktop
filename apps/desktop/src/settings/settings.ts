export type ThemePreference = "system" | "light" | "dark";

/** Non-secret preferences only. Tokens and keys belong to SecureCredentialStore. */
export type DesktopSettings = {
  theme: ThemePreference;
  startOnLogin: boolean;
  reduceMotion: boolean;
};

export const defaultSettings: Readonly<DesktopSettings> = {
  theme: "system",
  startOnLogin: false,
  reduceMotion: false,
};

export const normalizeSettings = (
  input: Partial<DesktopSettings> | null | undefined,
): DesktopSettings => ({
  theme:
    input?.theme === "light" || input?.theme === "dark"
      ? input.theme
      : "system",
  startOnLogin: input?.startOnLogin === true,
  reduceMotion: input?.reduceMotion === true,
});
