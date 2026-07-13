import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const tokens = JSON.parse(
  await readFile(join(root, "..", "tokens.json"), "utf8"),
);

const hex = /^#[0-9A-F]{6}$/i;
const hexToRgb = (value) =>
  [0, 2, 4].map(
    (offset) => Number.parseInt(value.slice(offset + 1, offset + 3), 16) / 255,
  );
const luminance = (value) =>
  hexToRgb(value)
    .map((channel) =>
      channel <= 0.03928 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4,
    )
    .reduce(
      (sum, channel, index) => sum + channel * [0.2126, 0.7152, 0.0722][index],
      0,
    );
const contrast = (foreground, background) => {
  const light = Math.max(luminance(foreground), luminance(background));
  const dark = Math.min(luminance(foreground), luminance(background));
  return (light + 0.05) / (dark + 0.05);
};

for (const value of [
  tokens.color.canvas,
  tokens.color.surface,
  tokens.color.surfaceRaised,
  tokens.color.textPrimary,
  tokens.color.textMuted,
  tokens.color.border,
  tokens.color.focus,
  tokens.color.accent,
]) {
  if (!hex.test(value)) throw new Error(`invalid color token: ${value}`);
}
for (const [name, status] of Object.entries(tokens.color.status)) {
  if (!hex.test(status.background) || !hex.test(status.foreground))
    throw new Error(`invalid ${name} status color`);
  if (contrast(status.foreground, status.background) < 4.5)
    throw new Error(`${name} status contrast is below WCAG AA`);
}
if (contrast(tokens.color.textPrimary, tokens.color.canvas) < 4.5)
  throw new Error("primary text contrast is below WCAG AA");
if (contrast(tokens.color.textMuted, tokens.color.canvas) < 4.5)
  throw new Error("muted text contrast is below WCAG AA");
if (tokens.interaction.minimumTarget < 44)
  throw new Error("interactive target is below 44px");
if (
  tokens.typography.body.fontSize < 16 ||
  tokens.typography.body.lineHeight < 1.4
)
  throw new Error("body typography is not accessible");
for (const [level, risk] of Object.entries(tokens.risk)) {
  if (
    !risk.label ||
    !tokens.color.status[risk.status] ||
    typeof risk.requiresApproval !== "boolean"
  )
    throw new Error(`incomplete risk semantics: ${level}`);
}
console.log(
  "design-system: tokens, contrast, target sizing, and risk semantics passed",
);
