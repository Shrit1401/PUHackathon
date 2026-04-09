import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { headers } from "next/headers";
import { notFound } from "next/navigation";
import {
  Activity,
  AlertTriangle,
  ChevronRight,
  Droplets,
  Fingerprint,
  MapPin,
  Phone,
  QrCode,
  Shield,
} from "lucide-react";

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
    rows.push({
      label,
      value: typeof v === "object" ? JSON.stringify(v) : String(v),
    });
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
    <article className="profile-panel lp-reveal-nfc overflow-hidden rounded-3xl border border-amber-400/20 bg-gradient-to-br from-amber-500/[0.08] via-black/40 to-transparent p-6 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)] [animation-delay:320ms] motion-reduce:animate-none motion-reduce:opacity-100 motion-reduce:[animation-delay:0ms]">
      <div className="flex items-start gap-3">
        <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl border border-amber-400/25 bg-black/50">
          <Activity
            className="h-5 w-5 text-amber-200/85"
            strokeWidth={1.5}
            aria-hidden
          />
        </div>
        <div>
          <p className="font-[family-name:var(--font-syne),sans-serif] text-sm font-semibold tracking-tight text-amber-100/95">
            Reader context
          </p>
          <p className="mt-1 text-xs leading-relaxed text-white/45">
            Telemetry from the last tag read—helps place when and where the card
            was tapped.
          </p>
        </div>
      </div>
      <dl className="mt-5 grid gap-2.5 sm:grid-cols-2">
        {rows.map(({ label, value }) => (
          <div
            key={label}
            className="rounded-2xl border border-white/[0.07] bg-black/35 p-3.5"
          >
            <dt className="text-[0.62rem] font-semibold uppercase tracking-[0.14em] text-white/38">
              {label}
            </dt>
            <dd className="mt-1.5 break-all font-mono text-[11px] leading-relaxed text-white/82">
              {value}
            </dd>
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
      return { title: "Emergency card · ResQNet+" };
    }
    return {
      title: `${profile.name} · Emergency card`,
      description: `Blood ${profile.blood_group}. Emergency contact on file.`,
    };
  } catch {
    return { title: "Emergency card · ResQNet+" };
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
      <main className="relative min-h-screen overflow-hidden bg-[#05060a] text-[#f0f4f8]">
        <div className="lp-ambient pointer-events-none absolute inset-0 -z-10" />
        <div className="lp-orbit pointer-events-none absolute inset-0 -z-10 opacity-70" />
        <div className="lp-grain pointer-events-none absolute inset-0 -z-10" />
        <div className="relative z-10 mx-auto flex min-h-screen max-w-lg flex-col justify-center px-6 py-16">
          <div className="lp-reveal-nfc rounded-3xl border border-red-400/25 bg-red-500/[0.09] p-8 text-center shadow-[inset_0_1px_0_rgba(255,255,255,0.06)] backdrop-blur-md">
            <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl border border-red-400/30 bg-black/40">
              <AlertTriangle
                className="h-7 w-7 text-red-300/90"
                strokeWidth={1.4}
                aria-hidden
              />
            </div>
            <h1 className="font-[family-name:var(--font-syne),sans-serif] text-xl font-semibold tracking-tight text-red-100">
              Could not load profile
            </h1>
            <p className="mt-3 text-sm leading-relaxed text-white/50">
              The emergency card API is unreachable or returned an error. Check
              the network and backend configuration.
            </p>
            <Link
              href="/"
              className="nfc-press mt-8 inline-flex items-center justify-center gap-2 rounded-full border border-white/12 bg-white/[0.05] px-5 py-2.5 text-xs font-semibold tracking-[0.14em] text-white/75 uppercase hover:border-white/20 hover:bg-white/[0.08] hover:text-white"
            >
              Back to home
            </Link>
          </div>
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
  const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=240x240&data=${encodeURIComponent(
    absoluteProfileUrl,
  )}`;

  const emergencyTel = profile.emergency_contact.replace(/\s/g, "");

  return (
    <main className="relative min-h-screen overflow-hidden bg-[#05060a] text-[#f0f4f8]">
      <div className="lp-ambient pointer-events-none absolute inset-0 -z-10" />
      <div className="lp-orbit pointer-events-none absolute inset-0 -z-10" />
      <div className="lp-grain pointer-events-none absolute inset-0 -z-10" />
      <div className="pointer-events-none absolute inset-x-0 top-0 -z-10 h-[min(48vh,480px)] bg-[radial-gradient(ellipse_70%_55%_at_50%_-8%,rgba(251,113,133,0.1),transparent_58%)]" />
      <div className="pointer-events-none absolute inset-x-0 bottom-0 -z-10 h-64 bg-[radial-gradient(ellipse_80%_70%_at_50%_100%,rgba(16,185,129,0.08),transparent_55%)]" />

      <header className="relative z-10 mx-auto flex w-full max-w-3xl items-center justify-between px-5 pt-8 sm:px-8">
        <Link
          href="/"
          className="nfc-press group inline-flex items-center gap-2 rounded-full border border-white/[0.08] bg-white/[0.03] px-3 py-2 pr-4 text-[10px] font-semibold tracking-[0.2em] text-white/50 uppercase hover:border-white/[0.14] hover:bg-white/[0.06] hover:text-white/80"
        >
          <Image
            src="/img.png"
            alt="ResQNet"
            width={28}
            height={28}
            className="h-7 w-7 opacity-90"
          />
          <span>ResQNet+</span>
        </Link>
        <Link
          href="/nfc"
          className="nfc-press inline-flex items-center gap-1 text-[10px] font-semibold tracking-[0.16em] text-cyan-200/70 uppercase"
        >
          NFC ops
          <ChevronRight className="h-3 w-3 opacity-70" aria-hidden />
        </Link>
      </header>

      <div className="relative z-10 mx-auto max-w-3xl space-y-5 px-5 pb-20 pt-10 sm:px-8">
        {/* Identity + warning */}
        <section className="lp-reveal-nfc relative overflow-hidden rounded-3xl border border-white/[0.09] bg-white/[0.03] p-6 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)] backdrop-blur-sm sm:p-8">
          <div className="pointer-events-none absolute -right-20 -top-20 h-48 w-48 rounded-full bg-rose-500/15 blur-3xl" />
          <div className="pointer-events-none absolute -bottom-16 -left-12 h-40 w-40 rounded-full bg-emerald-500/10 blur-3xl" />
          <div className="relative">
            <div className="inline-flex items-center gap-2 rounded-full border border-rose-400/25 bg-rose-500/[0.1] px-3 py-1.5">
              <Shield className="h-3.5 w-3.5 text-rose-200/80" aria-hidden />
              <span className="text-[10px] font-semibold tracking-[0.2em] text-rose-100/90 uppercase">
                Emergency medical card
              </span>
            </div>
            <h1 className="font-[family-name:var(--font-syne),sans-serif] mt-5 text-[clamp(1.85rem,5vw,2.75rem)] font-semibold leading-[1.05] tracking-[-0.03em] text-white">
              {profile.name}
            </h1>
            <p className="mt-4 max-w-xl text-sm leading-relaxed text-white/48">
              Details from ResQNet+ for first responders.{" "}
              <span className="text-amber-200/85">
                Always confirm identity at the scene
              </span>{" "}
              before relying on this information.
            </p>
          </div>
        </section>

        {/* Blood + call — critical path */}
        <div className="grid gap-4 sm:grid-cols-2">
          <article className="profile-panel lp-reveal-nfc relative overflow-hidden rounded-3xl border border-rose-400/22 bg-gradient-to-b from-rose-500/[0.12] to-black/50 p-6 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)] [animation-delay:70ms] motion-reduce:animate-none motion-reduce:opacity-100">
            <div className="pointer-events-none absolute right-3 top-3 opacity-[0.07]">
              <Droplets className="h-24 w-24 text-white" strokeWidth={1} />
            </div>
            <div className="relative flex items-center gap-2 text-[10px] font-semibold tracking-[0.18em] text-rose-200/75 uppercase">
              <Droplets className="h-3.5 w-3.5" aria-hidden />
              Blood group
            </div>
            <p className="font-[family-name:var(--font-syne),sans-serif] relative mt-3 text-4xl font-semibold tracking-tight text-rose-100 sm:text-5xl">
              {profile.blood_group}
            </p>
          </article>

          <a
            href={`tel:${emergencyTel}`}
            className="profile-panel lp-reveal-nfc nfc-press group relative flex flex-col justify-between overflow-hidden rounded-3xl border border-emerald-400/28 bg-gradient-to-b from-emerald-500/[0.14] to-black/55 p-6 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)] [animation-delay:120ms] motion-reduce:animate-none motion-reduce:opacity-100"
          >
            <div className="pointer-events-none absolute -right-6 -top-6 h-28 w-28 rounded-full bg-emerald-400/20 blur-2xl transition-opacity duration-200 group-hover:opacity-100" />
            <div>
              <div className="flex items-center gap-2 text-[10px] font-semibold tracking-[0.18em] text-emerald-200/80 uppercase">
                <Phone className="h-3.5 w-3.5" aria-hidden />
                Emergency contact
              </div>
              <p className="font-[family-name:var(--font-syne),sans-serif] mt-3 text-xl font-semibold leading-snug tracking-tight text-white sm:text-2xl">
                {profile.emergency_contact}
              </p>
            </div>
            <span className="relative mt-5 inline-flex items-center gap-2 text-[11px] font-semibold tracking-[0.12em] text-emerald-200/90 uppercase">
              Tap to call
              <ChevronRight className="h-3.5 w-3.5 opacity-80" aria-hidden />
            </span>
          </a>
        </div>

        {/* Allergies */}
        <article className="profile-panel lp-reveal-nfc rounded-3xl border border-white/[0.08] bg-black/35 p-6 shadow-[inset_0_1px_0_rgba(255,255,255,0.04)] backdrop-blur-sm [animation-delay:160ms] motion-reduce:animate-none motion-reduce:opacity-100">
          <p className="text-[10px] font-semibold tracking-[0.18em] text-white/40 uppercase">
            Allergies &amp; notes
          </p>
          <p className="mt-3 text-base leading-relaxed text-white/88">
            {profile.allergies}
          </p>
        </article>

        {/* Card ID */}
        <article className="profile-panel lp-reveal-nfc rounded-3xl border border-white/[0.08] bg-black/30 p-6 [animation-delay:200ms] motion-reduce:animate-none motion-reduce:opacity-100">
          <div className="flex items-center gap-2 text-[10px] font-semibold tracking-[0.18em] text-white/38 uppercase">
            <Fingerprint className="h-3.5 w-3.5 text-cyan-400/60" aria-hidden />
            Card user ID
          </div>
          <p className="mt-3 break-all font-mono text-xs leading-relaxed text-white/72">
            {userId}
          </p>
        </article>

        {/* Location */}
        {coords != null ? (
          <article className="profile-panel lp-reveal-nfc rounded-3xl border border-sky-400/22 bg-sky-500/[0.06] p-6 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)] [animation-delay:240ms] motion-reduce:animate-none motion-reduce:opacity-100">
            <div className="flex items-center gap-2 text-[10px] font-semibold tracking-[0.18em] text-sky-200/75 uppercase">
              <MapPin className="h-3.5 w-3.5" aria-hidden />
              Location reference
            </div>
            <p className="mt-2 text-sm leading-relaxed text-white/55">
              {query.lat != null && query.lng != null
                ? "Coordinates from this link (e.g. QR or shared URL)."
                : "Last reported reader position from the device that scanned the tag."}
            </p>
            <p className="mt-2 font-mono text-xs text-sky-200/65">
              {coords.lat.toFixed(6)}, {coords.lng.toFixed(6)}
            </p>
            <Link
              href={`https://maps.google.com/?q=${coords.lat},${coords.lng}`}
              target="_blank"
              rel="noopener noreferrer"
              className="nfc-press mt-4 inline-flex items-center gap-2 rounded-full border border-sky-400/35 bg-sky-400/12 px-4 py-2 text-[11px] font-semibold tracking-[0.1em] text-sky-100 uppercase hover:border-sky-400/50 hover:bg-sky-400/20"
            >
              Open in Maps
              <ChevronRight className="h-3.5 w-3.5 opacity-80" aria-hidden />
            </Link>
          </article>
        ) : (
          <article className="profile-panel lp-reveal-nfc rounded-3xl border border-dashed border-white/[0.12] bg-white/[0.02] p-6 [animation-delay:240ms] motion-reduce:animate-none motion-reduce:opacity-100">
            <div className="flex items-center gap-2 text-[10px] font-semibold tracking-[0.18em] text-white/32 uppercase">
              <MapPin className="h-3.5 w-3.5 text-white/25" aria-hidden />
              Location reference
            </div>
            <p className="mt-2 text-sm leading-relaxed text-white/42">
              No coordinates yet. Open this page from a scan that includes GPS, or
              add{" "}
              <code className="rounded border border-white/10 bg-black/40 px-1.5 py-0.5 font-mono text-[11px] text-white/55">
                ?lat=&amp;lng=
              </code>{" "}
              to the URL.
            </p>
          </article>
        )}

        {profile.reader_context ? (
          <ReaderContextPanel ctx={profile.reader_context} />
        ) : null}

        {/* QR */}
        <article className="profile-panel lp-reveal-nfc rounded-3xl border border-cyan-400/20 bg-gradient-to-br from-cyan-500/[0.08] via-black/40 to-transparent p-6 sm:p-8 [animation-delay:380ms] motion-reduce:animate-none motion-reduce:opacity-100">
          <div className="flex items-center gap-2 text-[10px] font-semibold tracking-[0.18em] text-cyan-200/80 uppercase">
            <QrCode className="h-3.5 w-3.5" aria-hidden />
            QR fallback
          </div>
          <p className="mt-2 max-w-md text-sm leading-relaxed text-white/50">
            No NFC on this device? Scan to open the same emergency card in a
            browser.
          </p>
          <div className="mt-6 flex flex-col gap-6 sm:flex-row sm:items-center">
            <div className="shrink-0 rounded-2xl border border-white/10 bg-white p-3 shadow-[0_20px_50px_-20px_rgba(0,0,0,0.8)]">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={qrUrl}
                width={216}
                height={216}
                alt="QR code linking to this emergency profile"
                className="h-[216px] w-[216px] rounded-lg"
              />
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-[10px] font-semibold tracking-[0.14em] text-white/35 uppercase">
                Profile URL
              </p>
              <p className="mt-2 break-all font-mono text-[11px] leading-relaxed text-white/55">
                {absoluteProfileUrl}
              </p>
            </div>
          </div>
        </article>
      </div>
    </main>
  );
}
