import { NextResponse } from "next/server";

function getBackendBaseUrl(): string {
  const fromEnv = process.env.NEXT_PUBLIC_RESQNET_API_BASE_URL?.trim();
  if (!fromEnv) {
    return "";
  }
  return fromEnv;
}

type RouteContext = {
  params: Promise<{ userId: string }>;
};

/** Proxies to ResQNet `GET /nfc/profile/{user_id}` so this app exposes the same JSON as the backend. */
export async function GET(
  _request: Request,
  context: RouteContext,
): Promise<Response> {
  const { userId } = await context.params;
  const url = `${getBackendBaseUrl()}/nfc/profile/${encodeURIComponent(userId)}`;

  let upstream: Response;
  try {
    upstream = await fetch(url, {
      headers: { accept: "application/json" },
      next: { revalidate: 0 },
    });
  } catch {
    return NextResponse.json(
      { detail: "Upstream NFC profile unavailable" },
      { status: 503 },
    );
  }

  const body = await upstream.text();
  const contentType =
    upstream.headers.get("content-type") || "application/json";
  return new NextResponse(body, {
    status: upstream.status,
    headers: { "Content-Type": contentType },
  });
}
