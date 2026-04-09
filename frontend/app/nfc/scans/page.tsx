"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { OpsShell } from "@/components/ops-shell";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { listNfcScans, type NfcScanRecord } from "@/lib/api";
import {
  AlertTriangle,
  ArrowUpRight,
  Droplets,
  Fingerprint,
  Hash,
  RefreshCw,
  ScanLine,
} from "lucide-react";

function NfcScanHero() {
  return (
    <section
      className="lp-reveal-nfc relative overflow-hidden rounded-3xl border border-white/[0.08] bg-gradient-to-br from-cyan-400/[0.07] via-transparent to-emerald-400/[0.05] p-6 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)] sm:p-8"
      aria-hidden
    >
      <div className="pointer-events-none absolute -right-16 top-1/2 h-48 w-48 -translate-y-1/2 rounded-full bg-cyan-400/10 blur-3xl" />
      <div className="pointer-events-none absolute -left-10 bottom-0 h-32 w-32 rounded-full bg-emerald-400/8 blur-2xl" />
      <div className="relative flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between">
        <div className="flex items-start gap-4">
          <div className="relative flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl border border-cyan-400/25 bg-black/40 shadow-[inset_0_1px_0_rgba(255,255,255,0.08)]">
            <div className="nfc-field-ring absolute inset-1 rounded-xl border border-cyan-400/15" />
            <ScanLine className="relative h-7 w-7 text-cyan-200/90" strokeWidth={1.35} />
          </div>
          <div>
            <p className="font-[family-name:var(--font-syne),sans-serif] text-lg font-semibold tracking-tight text-white sm:text-xl">
              Tag read pipeline
            </p>
            <p className="mt-1 max-w-lg text-sm leading-relaxed text-white/48">
              Each row is one NFC ingest event. Cross-check{" "}
              <code className="rounded border border-white/10 bg-white/[0.04] px-1 py-px font-mono text-[11px] text-white/70">
                card_user_id
              </code>{" "}
              with field reports and the public profile route.
            </p>
          </div>
        </div>
        <div className="flex flex-wrap gap-2 lg:justify-end">
          {["13.56 MHz", "AES-backed payload", "Profile snapshot"].map(
            (label) => (
              <span
                key={label}
                className="rounded-full border border-white/[0.08] bg-black/35 px-3 py-1.5 text-[10px] font-semibold tracking-[0.12em] text-white/45 uppercase"
              >
                {label}
              </span>
            ),
          )}
        </div>
      </div>
    </section>
  );
}

export default function NfcScansPage() {
  const [items, setItems] = useState<NfcScanRecord[]>([]);
  const [count, setCount] = useState(0);
  const [limit, setLimit] = useState(50);
  const [cardUserId, setCardUserId] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await listNfcScans({
        limit,
        card_user_id: cardUserId.trim() || undefined,
      });
      setItems(res.items);
      setCount(res.count);
    } catch (e) {
      setItems([]);
      setCount(0);
      setError(e instanceof Error ? e.message : "Failed to load scans");
    } finally {
      setLoading(false);
    }
  }, [limit, cardUserId]);

  useEffect(() => {
    void load();
  }, [load]);

  return (
    <OpsShell
      title="NFC"
      subtitle="Emergency card telemetry & audit trail"
      lede="Filter by holder UUID to isolate one tag. Rows link to the public emergency profile for that user."
      tag="Tap stream"
      onRefresh={load}
    >
      <div className="space-y-5">
        <NfcScanHero />

        <section className="lp-reveal-nfc [animation-delay:80ms] flex flex-col gap-4 rounded-3xl border border-white/[0.07] bg-black/30 p-5 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)] backdrop-blur-md sm:flex-row sm:flex-wrap sm:items-end sm:gap-5">
          <label className="flex flex-col gap-2">
            <span className="flex items-center gap-1.5 text-[0.65rem] font-semibold tracking-[0.16em] text-white/40 uppercase">
              <Hash className="h-3 w-3 text-cyan-400/50" aria-hidden />
              Limit
            </span>
            <input
              type="number"
              min={1}
              max={500}
              value={limit}
              onChange={(ev) => setLimit(Number(ev.target.value) || 50)}
              className="nfc-input w-28 rounded-xl border border-white/12 bg-black/50 px-3.5 py-2.5 text-sm text-white placeholder:text-white/25"
            />
          </label>
          <label className="flex min-w-[220px] flex-1 flex-col gap-2">
            <span className="flex items-center gap-1.5 text-[0.65rem] font-semibold tracking-[0.16em] text-white/40 uppercase">
              <Fingerprint className="h-3 w-3 text-emerald-400/50" aria-hidden />
              Card user ID
            </span>
            <input
              type="text"
              placeholder="Optional UUID filter…"
              value={cardUserId}
              onChange={(ev) => setCardUserId(ev.target.value)}
              className="nfc-input rounded-xl border border-white/12 bg-black/50 px-3.5 py-2.5 font-mono text-xs text-white placeholder:text-white/22"
            />
          </label>
          <div className="flex flex-wrap gap-2 sm:pb-0.5">
            <Button
              type="button"
              className="nfc-press rounded-xl border border-cyan-400/30 bg-cyan-400/12 text-cyan-50 hover:bg-cyan-400/22"
              onClick={() => void load()}
            >
              <RefreshCw className="mr-2 h-3.5 w-3.5 opacity-80" aria-hidden />
              Apply
            </Button>
            <Button
              type="button"
              variant="ghost"
              className="nfc-press rounded-xl border border-white/10 bg-white/[0.03] text-white/70 hover:bg-white/[0.07] hover:text-white"
              asChild
            >
              <Link href="/nfc">Hub</Link>
            </Button>
          </div>
        </section>

        {error ? (
          <div
            className="lp-reveal-nfc flex items-start gap-3 rounded-2xl border border-red-400/28 bg-red-500/[0.12] px-4 py-3.5 text-sm text-red-50 [animation-delay:40ms]"
            role="alert"
          >
            <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-red-300" />
            <span>{error}</span>
          </div>
        ) : null}

        <div className="lp-reveal-nfc flex flex-wrap items-center justify-between gap-3 text-sm [animation-delay:100ms]">
          <span className="text-white/45">
            {loading ? (
              <span className="inline-flex items-center gap-2">
                <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-cyan-400 shadow-[0_0_8px_rgba(34,211,238,0.6)]" />
                Syncing…
              </span>
            ) : (
              <>
                <span className="font-[family-name:var(--font-syne),sans-serif] text-lg font-semibold tabular-nums text-white/90">
                  {count}
                </span>
                <span className="text-white/40">
                  {" "}
                  scan{count === 1 ? "" : "s"} on this page
                </span>
              </>
            )}
          </span>
        </div>

        <div className="space-y-4">
          {loading
            ? Array.from({ length: 4 }).map((_, i) => (
                <Skeleton
                  key={i}
                  className="h-44 w-full rounded-3xl border border-white/[0.05] bg-white/[0.05]"
                  style={{ animationDelay: `${i * 60}ms` }}
                />
              ))
            : items.map((scan, i) => (
                <article
                  key={scan.id}
                  className="nfc-scan-card lp-reveal-nfc rounded-3xl border border-white/[0.08] bg-black/35 p-5 shadow-[inset_0_1px_0_rgba(255,255,255,0.04)] backdrop-blur-sm sm:p-6"
                  style={{ animationDelay: `${120 + Math.min(i * 42, 360)}ms` }}
                >
                  <div className="flex flex-wrap items-start justify-between gap-4">
                    <div className="min-w-0">
                      <p className="font-mono text-[0.62rem] tracking-wide text-white/35">
                        {scan.id}
                      </p>
                      <p className="font-[family-name:var(--font-syne),sans-serif] mt-1.5 text-xl font-semibold tracking-tight text-white sm:text-2xl">
                        {scan.profile_snapshot?.name ??
                          scan.tag_payload?.display_name ??
                          "Unknown holder"}
                      </p>
                      <p className="mt-1 text-xs text-white/42">
                        Scanned{" "}
                        <time dateTime={scan.scanned_at}>
                          {new Date(scan.scanned_at).toLocaleString()}
                        </time>
                      </p>
                    </div>
                    <Link
                      href={`/profile/${encodeURIComponent(scan.card_user_id)}`}
                      className="nfc-press inline-flex shrink-0 items-center gap-1.5 rounded-full border border-emerald-400/35 bg-emerald-400/[0.1] px-4 py-2 text-[0.65rem] font-semibold tracking-[0.14em] text-emerald-100 uppercase hover:border-emerald-400/50 hover:bg-emerald-400/18"
                    >
                      Open card
                      <ArrowUpRight className="h-3.5 w-3.5 opacity-90" />
                    </Link>
                  </div>
                  <dl className="mt-5 grid gap-4 border-t border-white/[0.06] pt-5 text-sm sm:grid-cols-2 lg:grid-cols-3">
                    <div>
                      <dt className="text-[0.62rem] font-semibold tracking-[0.14em] text-white/38 uppercase">
                        Card user
                      </dt>
                      <dd className="mt-1 break-all font-mono text-[11px] leading-relaxed text-white/78">
                        {scan.card_user_id}
                      </dd>
                    </div>
                    <div>
                      <dt className="flex items-center gap-1.5 text-[0.62rem] font-semibold tracking-[0.14em] text-white/38 uppercase">
                        <Droplets
                          className="h-3 w-3 text-rose-300/60"
                          aria-hidden
                        />
                        Blood / allergies
                      </dt>
                      <dd className="mt-1 text-white/78">
                        {scan.profile_snapshot
                          ? `${scan.profile_snapshot.blood_group} · ${scan.profile_snapshot.allergies}`
                          : "—"}
                      </dd>
                    </div>
                    <div>
                      <dt className="text-[0.62rem] font-semibold tracking-[0.14em] text-white/38 uppercase">
                        Emergency contact
                      </dt>
                      <dd className="mt-1 text-emerald-200/88">
                        {scan.profile_snapshot?.emergency_contact ?? "—"}
                      </dd>
                    </div>
                  </dl>
                  {(scan.reader_context_error ?? scan.profile_fetch_error) ? (
                    <p className="mt-4 rounded-xl border border-amber-400/22 bg-amber-400/[0.06] px-3.5 py-2.5 text-xs leading-relaxed text-amber-100/90">
                      {scan.reader_context_error
                        ? `Context: ${scan.reader_context_error}`
                        : null}
                      {scan.profile_fetch_error
                        ? ` Profile: ${scan.profile_fetch_error}`
                        : null}
                    </p>
                  ) : null}
                </article>
              ))}
        </div>

        {!loading && items.length === 0 && !error ? (
          <div className="lp-reveal-nfc rounded-3xl border border-dashed border-white/[0.12] bg-white/[0.02] px-8 py-16 text-center [animation-delay:160ms]">
            <div className="mx-auto mb-5 flex h-16 w-16 items-center justify-center rounded-2xl border border-white/10 bg-black/40">
              <ScanLine className="h-8 w-8 text-white/25" strokeWidth={1.2} />
            </div>
            <p className="font-[family-name:var(--font-syne),sans-serif] text-lg font-semibold text-white/80">
              No taps for this filter
            </p>
            <p className="mx-auto mt-2 max-w-sm text-sm text-white/42">
              Widen the limit or clear the UUID field, then apply again.
            </p>
            <Button
              type="button"
              variant="outline"
              className="nfc-press mt-6 rounded-full border-white/15 bg-transparent text-white/75 hover:bg-white/[0.06]"
              onClick={() => {
                setCardUserId("");
                setLimit(50);
              }}
            >
              Reset filters
            </Button>
          </div>
        ) : null}
      </div>
    </OpsShell>
  );
}
