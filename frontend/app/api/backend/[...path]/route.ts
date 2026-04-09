import {
  applyNgrokBypassHeader,
  normalizeBackendBaseUrlFromEnv,
} from "@/lib/backend-origin";

function getBackendBaseUrl(): string {
  const base = normalizeBackendBaseUrlFromEnv(
    process.env.NEXT_PUBLIC_RESQNET_API_BASE_URL,
  );
  if (!base) {
    throw new Error("NEXT_PUBLIC_RESQNET_API_BASE_URL is not set");
  }
  return base;
}

const UPSTREAM_TIMEOUT_MS = 45_000;
const UPSTREAM_MAX_ATTEMPTS = 3;

async function proxy(
  request: Request,
  context: { params: Promise<{ path: string[] }> },
): Promise<Response> {
  const { path } = await context.params;
  const requestUrl = new URL(request.url);
  const upstream = new URL(
    `${getBackendBaseUrl()}/${path.join("/").replace(/^\/+/, "")}`,
  );
  upstream.search = requestUrl.search;

  const headers = new Headers(request.headers);
  headers.delete("host");
  headers.delete("connection");
  headers.delete("content-length");
  applyNgrokBypassHeader(headers, upstream);

  const method = request.method;
  const body =
    method === "GET" || method === "HEAD"
      ? undefined
      : await request.arrayBuffer();

  const initBase: RequestInit = {
    method,
    headers,
    body,
    redirect: "manual",
  };

  let lastError: unknown;
  for (let attempt = 0; attempt < UPSTREAM_MAX_ATTEMPTS; attempt++) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), UPSTREAM_TIMEOUT_MS);
    try {
      const upstreamResponse = await fetch(upstream, {
        ...initBase,
        signal: controller.signal,
      });
      clearTimeout(timeoutId);

      const responseHeaders = new Headers(upstreamResponse.headers);
      responseHeaders.delete("content-length");
      responseHeaders.delete("content-encoding");

      return new Response(upstreamResponse.body, {
        status: upstreamResponse.status,
        statusText: upstreamResponse.statusText,
        headers: responseHeaders,
      });
    } catch (error) {
      clearTimeout(timeoutId);
      lastError = error;
      if (attempt < UPSTREAM_MAX_ATTEMPTS - 1) {
        await new Promise((r) => setTimeout(r, 300 * (attempt + 1)));
      }
    }
  }

  const message =
    lastError instanceof Error ? lastError.message : String(lastError);
  return new Response(
    JSON.stringify({
      error: "upstream_unavailable",
      message,
    }),
    {
      status: 503,
      headers: { "Content-Type": "application/json" },
    },
  );
}

export async function GET(
  request: Request,
  context: { params: Promise<{ path: string[] }> },
): Promise<Response> {
  return proxy(request, context);
}

export async function POST(
  request: Request,
  context: { params: Promise<{ path: string[] }> },
): Promise<Response> {
  return proxy(request, context);
}

export async function PATCH(
  request: Request,
  context: { params: Promise<{ path: string[] }> },
): Promise<Response> {
  return proxy(request, context);
}

export async function PUT(
  request: Request,
  context: { params: Promise<{ path: string[] }> },
): Promise<Response> {
  return proxy(request, context);
}

export async function DELETE(
  request: Request,
  context: { params: Promise<{ path: string[] }> },
): Promise<Response> {
  return proxy(request, context);
}

export async function OPTIONS(
  request: Request,
  context: { params: Promise<{ path: string[] }> },
): Promise<Response> {
  return proxy(request, context);
}
