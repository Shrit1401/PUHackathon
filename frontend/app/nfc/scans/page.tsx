"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { OpsShell } from "@/components/ops-shell";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { listNfcScans, type NfcScanRecord } from "@/lib/api";

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
      title="NFC scan log"
      subtitle="Reads ingested from emergency tags—pulled live from the ResQNet API."
      lede="Filter by card user UUID to audit a specific tag. Each row links to the public emergency card for that holder."
      tag="Backend feed"
      onRefresh={load}
    >
      <section className="flex flex-col gap-4 rounded-2xl border border-white/[0.06] bg-white/[0.02] p-4 backdrop-blur-sm sm:flex-row sm:flex-wrap sm:items-end">
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="text-[0.65rem] uppercase tracking-wider text-white/45">Limit</span>
          <input
            type="number"
            min={1}
            max={500}
            value={limit}
            onChange={(ev) => setLimit(Number(ev.target.value) || 50)}
            className="w-28 rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-white outline-none focus:border-cyan-400/40"
          />
        </label>
        <label className="flex min-w-[200px] flex-1 flex-col gap-1.5 text-sm">
          <span className="text-[0.65rem] uppercase tracking-wider text-white/45">
            Card user ID (optional)
          </span>
          <input
            type="text"
            placeholder="UUID filter…"
            value={cardUserId}
            onChange={(ev) => setCardUserId(ev.target.value)}
            className="rounded-lg border border-white/10 bg-black/40 px-3 py-2 font-mono text-xs text-white outline-none placeholder:text-white/25 focus:border-cyan-400/40"
          />
        </label>
        <Button
          type="button"
          variant="secondary"
          className="border border-cyan-400/25 bg-cyan-400/10 text-cyan-100 hover:bg-cyan-400/20"
          onClick={() => void load()}
        >
          Apply
        </Button>
      </section>

      {error ? (
        <div className="rounded-xl border border-red-400/30 bg-red-500/10 px-4 py-3 text-sm text-red-100">
          {error}
        </div>
      ) : null}

      <div className="flex items-center justify-between text-sm text-white/50">
        <span>
          {loading ? "Loading…" : `${count} scan${count === 1 ? "" : "s"} in this page`}
        </span>
      </div>

      <div className="space-y-3">
        {loading
          ? Array.from({ length: 4 }).map((_, i) => (
              <Skeleton key={i} className="h-40 w-full rounded-2xl bg-white/[0.06]" />
            ))
          : items.map((scan) => (
              <article
                key={scan.id}
                className="rounded-2xl border border-white/[0.08] bg-black/30 p-4 shadow-inner backdrop-blur-sm"
              >
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <p className="font-mono text-[0.65rem] text-white/40">{scan.id}</p>
                    <p className="mt-1 text-lg font-semibold text-white">
                      {scan.profile_snapshot?.name ?? scan.tag_payload?.display_name ?? "Unknown"}
                    </p>
                    <p className="text-xs text-white/45">
                      Scanned {new Date(scan.scanned_at).toLocaleString()}
                    </p>
                  </div>
                  <Link
                    href={`/profile/${encodeURIComponent(scan.card_user_id)}`}
                    className="shrink-0 rounded-full border border-emerald-400/30 bg-emerald-400/10 px-3 py-1.5 text-[0.65rem] font-semibold tracking-wider text-emerald-100 uppercase hover:bg-emerald-400/20"
                  >
                    Open card
                  </Link>
                </div>
                <dl className="mt-4 grid gap-3 text-sm sm:grid-cols-2 lg:grid-cols-3">
                  <div>
                    <dt className="text-[0.65rem] uppercase tracking-wider text-white/40">
                      Card user
                    </dt>
                    <dd className="mt-0.5 break-all font-mono text-xs text-white/80">
                      {scan.card_user_id}
                    </dd>
                  </div>
                  <div>
                    <dt className="text-[0.65rem] uppercase tracking-wider text-white/40">
                      Blood / allergies
                    </dt>
                    <dd className="mt-0.5 text-white/80">
                      {scan.profile_snapshot
                        ? `${scan.profile_snapshot.blood_group} · ${scan.profile_snapshot.allergies}`
                        : "—"}
                    </dd>
                  </div>
                  <div>
                    <dt className="text-[0.65rem] uppercase tracking-wider text-white/40">
                      Emergency
                    </dt>
                    <dd className="mt-0.5 text-emerald-200/90">
                      {scan.profile_snapshot?.emergency_contact ?? "—"}
                    </dd>
                  </div>
                </dl>
                {(scan.reader_context_error ?? scan.profile_fetch_error) ? (
                  <p className="mt-3 rounded-lg border border-amber-400/20 bg-amber-400/5 px-3 py-2 text-xs text-amber-100/90">
                    {scan.reader_context_error ? `Context: ${scan.reader_context_error}` : null}
                    {scan.profile_fetch_error ? ` Profile: ${scan.profile_fetch_error}` : null}
                  </p>
                ) : null}
              </article>
            ))}
      </div>

      {!loading && items.length === 0 && !error ? (
        <p className="py-12 text-center text-sm text-white/45">No scans returned for this filter.</p>
      ) : null}
    </OpsShell>
  );
}
