import type { Metadata } from "next";
import Link from "next/link";
import { headers } from "next/headers";
import { notFound } from "next/navigation";

import type { NfcProfileResponse, NfcReaderContext } from "@/lib/api";
import { loadNfcProfileForPage } from "@/lib/nfc-profile-server";

type ProfilePageProps = {
  params: Promise<{ userId: string }>;
  searchParams: Promise<{ lat?: string; lng?: string }>;
};

async function getBaseUrlFromHeaders(): Promise<string> {
  const requestHeaders = await headers();
  const host = requestHeaders.get("host");
  const proto = requestHeaders.get("x-forwarded-proto") ?? "http";
  if (!host) return "http://localhost:3000";
  return `${proto}://${host}`;
}

function pickCoordinates(
  profile: NfcProfileResponse,
  latQuery?: string,
  lngQuery?: string,
): { lat: number; lng: number } | null {
  const qLat = latQuery != null ? Number(latQuery) : Number.NaN;
  const qLng = lngQuery != null ? Number(lngQuery) : Number.NaN;
  if (Number.isFinite(qLat) && Number.isFinite(qLng)) {
    return { lat: qLat, lng: qLng };
  }
  const ctx = profile.reader_context;
  const rLat = ctx?.reader_latitude;
  const rLng = ctx?.reader_longitude;
  if (
    typeof rLat === "number" &&
    typeof rLng === "number" &&
    Number.isFinite(rLat) &&
    Number.isFinite(rLng)
  ) {
    return { lat: rLat, lng: rLng };
  }
  return null;
}

function ReaderContextPanel({ ctx }: { ctx: NfcReaderContext }) {
  const rows: { label: string; value: string }[] = [];
  const push = (label: string, v: unknown) => {
    if (v === undefined || v === null || v === "") return;
    rows.push({ label, value: typeof v === "object" ? JSON.stringify(v) : String(v) });
  };

  push("Client", ctx.client);
  push("Scan summary", ctx.description_summary);
  push("Client time", ctx.client_ts);
  push("Connectivity", ctx.connectivity);
  push("App language", ctx.app_language);
  push("Battery %", ctx.battery_percent);
  push("People nearby (reported)", ctx.people_count);
  push("Injured (reported)", ctx.injured);
  push("Speed m/s", ctx.speed_mps);
  push("Heading", ctx.heading);
  push("Altitude m", ctx.altitude_m);
  push("Location accuracy m", ctx.location_accuracy_m);
  push("NFC linked (seconds ago)", ctx.nfc_linked_seconds_ago);
  push("Nearest event ID", ctx.nearest_event_id);
  push("Recent NFC user ID", ctx.nfc_user_id_recent);
  if (
    typeof ctx.reader_latitude === "number" &&
    typeof ctx.reader_longitude === "number"
  ) {
    push("Reader latitude", ctx.reader_latitude);
    push("Reader longitude", ctx.reader_longitude);
  }

  if (rows.length === 0) return null;

  return (
    <article className="rounded-2xl border border-amber-400/25 bg-amber-500/10 p-4">
      <p className="text-xs font-medium tracking-[0.18em] text-amber-100/90 uppercase">
        Reader context (last tap)
      </p>
      <p className="mt-1 text-sm text-slate-300">
        Telemetry from the device that read the tag—useful for locating the scan.
      </p>
      <dl className="mt-4 grid gap-3 sm:grid-cols-2">
        {rows.map(({ label, value }) => (
          <div key={label} className="rounded-xl border border-slate-700/80 bg-slate-900/50 p-3">
            <dt className="text-[0.65rem] uppercase tracking-wider text-slate-500">{label}</dt>
            <dd className="mt-1 break-all font-mono text-xs text-slate-200">{value}</dd>
          </div>
        ))}
      </dl>
    </article>
  );
}

export async function generateMetadata({
  params,
}: Pick<ProfilePageProps, "params">): Promise<Metadata> {
  const { userId } = await params;
  try {
    const profile = await loadNfcProfileForPage(userId);
    if (!profile) {
      return { title: "Emergency card · ResQNet" };
    }
    return {
      title: `${profile.name} · Emergency card`,
      description: `Blood ${profile.blood_group}. Emergency contact on file.`,
    };
  } catch {
    return { title: "Emergency card · ResQNet" };
  }
}

export default async function EmergencyProfilePage({
  params,
  searchParams,
}: ProfilePageProps) {
  const { userId } = await params;
  const query = await searchParams;

  let profile: NfcProfileResponse;
  try {
    const loaded = await loadNfcProfileForPage(userId);
    if (!loaded) notFound();
    profile = loaded;
  } catch {
    return (
      <main className="min-h-screen bg-slate-950 px-4 py-12 text-slate-100 sm:px-6">
        <div className="mx-auto max-w-lg rounded-2xl border border-red-400/30 bg-red-500/10 p-6 text-center">
          <h1 className="text-lg font-semibold text-red-100">Could not load profile</h1>
          <p className="mt-2 text-sm text-slate-300">
            The emergency card API is unreachable or returned an error. Check the network and
            backend configuration.
          </p>
          <Link
            href="/"
            className="mt-6 inline-block text-sm text-cyan-300 underline-offset-4 hover:underline"
          >
            Back to home
          </Link>
        </div>
      </main>
    );
  }

  const coords = pickCoordinates(profile, query.lat, query.lng);
  const profilePath =
    coords != null
      ? `/profile/${encodeURIComponent(userId)}?lat=${coords.lat}&lng=${coords.lng}`
      : `/profile/${encodeURIComponent(userId)}`;
  const absoluteProfileUrl = `${await getBaseUrlFromHeaders()}${profilePath}`;
  const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${encodeURIComponent(
    absoluteProfileUrl,
  )}`;

  const emergencyTel = profile.emergency_contact.replace(/\s/g, "");

  return (
    <main className="min-h-screen bg-slate-950 px-4 py-8 text-slate-100 sm:px-6">
      <div className="mx-auto mb-6 max-w-3xl">
        <Link
          href="/"
          className="text-xs font-medium tracking-wider text-slate-500 uppercase hover:text-slate-300"
        >
          ← ResQNet
        </Link>
      </div>
      <section className="mx-auto max-w-3xl space-y-6 rounded-3xl border border-slate-800 bg-slate-900/80 p-5 shadow-2xl backdrop-blur sm:p-8">
        <div className="rounded-2xl border border-red-400/30 bg-red-500/10 p-4">
          <p className="text-xs font-semibold tracking-[0.2em] text-red-200 uppercase">
            NFC emergency card
          </p>
          <h1 className="mt-2 text-2xl font-bold sm:text-3xl">{profile.name}</h1>
          <p className="mt-2 text-sm text-slate-300">
            Medical and contact details from ResQNet. Always verify identity at the scene.
          </p>
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          <article className="rounded-2xl border border-slate-700 bg-slate-800/70 p-4">
            <p className="text-xs text-slate-400 uppercase">Blood group</p>
            <p className="mt-1 text-lg font-semibold text-rose-200">{profile.blood_group}</p>
          </article>
          <article className="rounded-2xl border border-slate-700 bg-slate-800/70 p-4">
            <p className="text-xs text-slate-400 uppercase">Card user ID</p>
            <p className="mt-1 break-all font-mono text-sm text-slate-200">{userId}</p>
          </article>
        </div>

        <article className="rounded-2xl border border-slate-700 bg-slate-800/70 p-4">
          <p className="text-xs text-slate-400 uppercase">Allergies</p>
          <p className="mt-2 text-sm leading-relaxed text-slate-200">{profile.allergies}</p>
        </article>

        <article className="rounded-2xl border border-slate-700 bg-slate-800/70 p-4">
          <p className="text-xs text-slate-400 uppercase">Emergency contact</p>
          <a
            className="mt-2 inline-block text-lg font-semibold text-emerald-300"
            href={`tel:${emergencyTel}`}
          >
            {profile.emergency_contact}
          </a>
        </article>

        {coords != null ? (
          <article className="rounded-2xl border border-slate-700 bg-slate-800/70 p-4">
            <p className="text-xs text-slate-400 uppercase">Location reference</p>
            <p className="mt-2 text-sm text-slate-200">
              {query.lat != null && query.lng != null
                ? "Coordinates from URL (e.g. QR or shared link)."
                : "Last known reader position from the device that scanned the tag."}
            </p>
            <p className="mt-1 font-mono text-xs text-slate-400">
              {coords.lat.toFixed(6)}, {coords.lng.toFixed(6)}
            </p>
            <Link
              href={`https://maps.google.com/?q=${coords.lat},${coords.lng}`}
              target="_blank"
              rel="noreferrer"
              className="mt-3 inline-flex rounded-full border border-sky-300/35 bg-sky-400/10 px-3 py-1 text-xs font-medium text-sky-100"
            >
              Open in Maps
            </Link>
          </article>
        ) : (
          <article className="rounded-2xl border border-slate-600/50 bg-slate-800/40 p-4">
            <p className="text-xs text-slate-500 uppercase">Location reference</p>
            <p className="mt-2 text-sm text-slate-400">
              No coordinates yet. Open this page from a scan that includes GPS, or add{" "}
              <span className="font-mono text-slate-300">?lat=&amp;lng=</span> to the URL.
            </p>
          </article>
        )}

        {profile.reader_context ? (
          <ReaderContextPanel ctx={profile.reader_context} />
        ) : null}

        <article className="rounded-2xl border border-sky-400/30 bg-sky-500/10 p-4">
          <p className="text-xs text-sky-100 uppercase">QR fallback</p>
          <p className="mt-2 text-sm text-slate-200">
            If NFC is not available, scan this code to open the same emergency card in a browser.
          </p>
          <div className="mt-3 flex flex-wrap items-center gap-4">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={qrUrl}
              width={220}
              height={220}
              alt="QR code for this emergency profile"
              className="rounded-lg border border-slate-700 bg-white p-2"
            />
            <p className="max-w-sm break-all text-xs text-slate-300">{absoluteProfileUrl}</p>
          </div>
        </article>
      </section>
    </main>
  );
}
