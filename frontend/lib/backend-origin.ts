/**
 * Ngrok free tiers often return an HTML interstitial to non-browser clients unless
 * this header is set. Next.js server `fetch` to an ngrok URL needs it.
 * @see https://ngrok.com/docs/troubleshooting/http-502-bad-gateway/#bypass-warning-page
 */
export const NGROK_SKIP_BROWSER_WARNING_HEADER = "ngrok-skip-browser-warning";
export const NGROK_SKIP_BROWSER_WARNING_VALUE = "true";

/** Strip wrapping quotes and trailing slashes from .env values. */
export function normalizeBackendBaseUrlFromEnv(value: string | undefined): string {
  let s = (value ?? "").trim();
  if (
    (s.startsWith('"') && s.endsWith('"')) ||
    (s.startsWith("'") && s.endsWith("'"))
  ) {
    s = s.slice(1, -1).trim();
  }
  return s.replace(/\/+$/, "");
}

export function isNgrokHostname(hostname: string): boolean {
  return hostname.includes("ngrok");
}

export function applyNgrokBypassHeader(headers: Headers, upstreamUrl: URL): void {
  if (isNgrokHostname(upstreamUrl.hostname)) {
    headers.set(NGROK_SKIP_BROWSER_WARNING_HEADER, NGROK_SKIP_BROWSER_WARNING_VALUE);
  }
}
