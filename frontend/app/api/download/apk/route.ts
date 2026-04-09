import { access, readFile } from "node:fs/promises";
import path from "node:path";
import { NextResponse } from "next/server";

export const runtime = "nodejs";

/**
 * Serves the Android APK. Either:
 * - Set APK_DOWNLOAD_URL or NEXT_PUBLIC_APK_DOWNLOAD_URL to a full HTTPS URL (redirect), or
 * - Place the built file at public/app.apk (served as attachment).
 */
export async function GET() {
  const remote =
    process.env.APK_DOWNLOAD_URL?.trim() ||
    process.env.NEXT_PUBLIC_APK_DOWNLOAD_URL?.trim();
  if (remote) {
    return NextResponse.redirect(remote, 302);
  }

  const filePath = path.join(process.cwd(), "public", "app.apk");
  try {
    await access(filePath);
  } catch {
    return NextResponse.json(
      {
        error:
          "APK not available. Add frontend/public/app.apk or set APK_DOWNLOAD_URL.",
      },
      { status: 404 }
    );
  }

  const buf = await readFile(filePath);
  return new NextResponse(buf, {
    headers: {
      "Content-Type": "application/vnd.android.package-archive",
      "Content-Disposition": 'attachment; filename="ResQNet.apk"',
    },
  });
}
