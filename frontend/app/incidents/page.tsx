"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { OpsShell } from "@/components/ops-shell";
import { StatsCard } from "@/components/stats-card";
import { StatusPill } from "@/components/status-pill";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { IncidentRecord } from "@/lib/ops-types";
import {
  confirmSocialEvent,
  fetchDisasterPhotos,
  fetchEvents,
  fetchLiveIncidents,
  fetchReports,
  fetchSocialEventConfirmations,
  postSocialObservation,
  type ApiEvent,
  type DisasterPhoto,
  type IncidentLiveRecord,
  type ReportDetail,
  type SocialEventConfirmationsResponse,
} from "@/lib/api";
import { Activity, AlertTriangle, MapPin } from "lucide-react";

const LIVE_INCIDENT_POLL_MS = 12_000;

/* ── helpers ──────────────────────────────────────────────────────────────── */

function normalizeIncidentDescription(raw?: string, type?: string): string | undefined {
  const input = raw?.trim();
  if (!input) return undefined;
  const cleanedParts = input
    .split("|")
    .map((p) => p.trim())
    .filter(Boolean)
    .filter((p) => !/^https?:\/\//i.test(p))
    .filter((p) => !/\.(jpg|jpeg|png|gif|webp)(\?.*)?$/i.test(p))
    .filter((p) => (type ? p.toLowerCase() !== type.trim().toLowerCase() : true));
  return cleanedParts.at(-1);
}

/** Extract all image URLs embedded in a raw description string (pipe-separated or bare). */
function extractImageUrls(raw?: string): string[] {
  if (!raw) return [];
  return raw
    .split("|")
    .map((p) => p.trim())
    .filter((p) => /^https?:\/\//i.test(p) && /\.(jpg|jpeg|png|gif|webp)(\?.*)?$/i.test(p));
}

const mapLiveStatus = (s: string): IncidentRecord["status"] => {
  if (s === "resolved") return "Resolved";
  if (s === "escalated") return "Escalated";
  if (s === "assigned") return "Assigned";
  return "Pending";
};

const mapPriority = (p: string): IncidentRecord["priority"] => {
  if (p === "critical") return "Critical";
  if (p === "high") return "High";
  if (p === "medium") return "Medium";
  return "Low";
};

/* ── Flat child incident type ─────────────────────────────────────────────── */

type FlatIncident = {
  id: string;
  eventId: string;
  eventType: string;
  kind: "incident" | "report";
  source: string;
  status: IncidentRecord["status"];
  priority: IncidentRecord["priority"];
  location: string;
  createdAt: string;
  createdAtRaw: string;
  description?: string;
  disasterType: string;
  peopleCount?: number | null;
  injuries?: boolean;
  lat: number;
  lng: number;
  mediaUrls?: string[];  // extracted from raw description bucket URLs
};

function findNearestEvent(events: ApiEvent[], lat: number, lng: number): ApiEvent | undefined {
  let best: ApiEvent | undefined;
  let bestDist = Infinity;
  for (const e of events) {
    const d = Math.abs(e.latitude - lat) + Math.abs(e.longitude - lng);
    if (d < bestDist) { bestDist = d; best = e; }
  }
  // Only associate if within ~0.5 degrees (~55 km)
  return bestDist < 0.5 ? best : undefined;
}

function buildAllIncidents(
  events: ApiEvent[],
  liveRecords: IncidentLiveRecord[],
  reports: ReportDetail[],
): FlatIncident[] {
  const out: FlatIncident[] = [];

  // All live-queue incidents (always shown, regardless of event linkage)
  for (const live of liveRecords) {
    const parentEvent = findNearestEvent(events, live.latitude, live.longitude);
    out.push({
      id: `live-${live.incident_id}`,
      eventId: parentEvent?.id ?? "unlinked",
      eventType: parentEvent?.type ?? live.type,
      kind: "incident",
      source: "Live Queue",
      status: mapLiveStatus(live.status),
      priority: mapPriority(live.priority),
      location: `${live.latitude.toFixed(3)}, ${live.longitude.toFixed(3)}`,
      createdAt: new Date(live.created_at).toLocaleString(),
      createdAtRaw: live.created_at,
      description: parentEvent ? normalizeIncidentDescription(parentEvent.description, live.type) : undefined,
      disasterType: live.type,
      lat: live.latitude,
      lng: live.longitude,
    });
  }

  // All reports
  for (const r of reports) {
    const mediaUrls = extractImageUrls(r.description);
    out.push({
      id: `report-${r.id}`,
      eventId: r.event_id ?? "unlinked",
      eventType: r.disaster_type,
      kind: "report",
      source: r.source || "Report",
      status: "Pending",
      priority: r.injuries || (r.people_count ?? 0) > 3 ? "High" : "Medium",
      location: `${r.latitude.toFixed(3)}, ${r.longitude.toFixed(3)}`,
      createdAt: r.created_at ? new Date(r.created_at).toLocaleString() : "N/A",
      createdAtRaw: r.created_at ?? "",
      description: normalizeIncidentDescription(r.description, r.disaster_type),
      disasterType: r.disaster_type,
      peopleCount: r.people_count,
      injuries: r.injuries,
      lat: r.latitude,
      lng: r.longitude,
      mediaUrls: mediaUrls.length > 0 ? mediaUrls : undefined,
    });
  }

  return out.sort((a, b) => {
    const aTs = a.createdAtRaw ? new Date(a.createdAtRaw).getTime() : 0;
    const bTs = b.createdAtRaw ? new Date(b.createdAtRaw).getTime() : 0;
    return bTs - aTs;
  });
}

/* ── Priority chip ────────────────────────────────────────────────────────── */

const PRIORITY_STYLES: Record<string, string> = {
  Critical: "border-red-400/30 bg-red-500/15 text-red-300",
  High: "border-orange-400/30 bg-orange-500/15 text-orange-300",
  Medium: "border-amber-400/25 bg-amber-500/10 text-amber-300",
  Low: "border-slate-600/30 bg-slate-700/20 text-slate-400",
};

function PriorityChip({ priority }: { priority: string }) {
  return (
    <span className={`inline-flex items-center rounded-md border px-1.5 py-0.5 text-[10px] font-semibold ${PRIORITY_STYLES[priority] ?? PRIORITY_STYLES.Low}`}>
      {priority}
    </span>
  );
}

/* ── Left table ───────────────────────────────────────────────────────────── */

function IncidentRow({
  inc,
  selected,
  onClick,
}: {
  inc: FlatIncident;
  selected: boolean;
  onClick: () => void;
}) {
  return (
    <tr
      onClick={onClick}
      className={`cursor-pointer border-b border-white/[0.05] text-sm transition ${
        selected
          ? "border-l-2 border-l-cyan-400/70 bg-cyan-500/[0.06] text-white"
          : inc.kind === "incident"
          ? "text-white/85 hover:bg-white/[0.035]"
          : "text-white/70 hover:bg-white/[0.025]"
      }`}
    >
      {/* Type + kind badge */}
      <td className="px-4 py-3 align-top">
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="font-medium capitalize">{inc.disasterType || "Unknown"}</span>
          <span className={`rounded px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide ${
            inc.kind === "incident"
              ? "bg-cyan-500/15 text-cyan-300/80"
              : "bg-white/[0.06] text-white/40"
          }`}>
            {inc.kind}
          </span>
        </div>
        {/* Parent event context */}
        <p className="mt-0.5 font-mono text-[9.5px] text-white/30 truncate">
          event · {inc.eventId}
        </p>
      </td>

      {/* Source */}
      <td className="px-4 py-3 align-top text-xs text-white/55">{inc.source}</td>

      {/* Location */}
      <td className="px-4 py-3 align-top font-mono text-[11px] text-white/50">{inc.location}</td>

      {/* Created */}
      <td className="px-4 py-3 align-top font-mono text-[11px] text-white/45">{inc.createdAt}</td>

      {/* Priority */}
      <td className="px-4 py-3 align-top">
        <PriorityChip priority={inc.priority} />
      </td>
    </tr>
  );
}

/* ── Page ─────────────────────────────────────────────────────────────────── */

export default function IncidentsPage() {
  const [allEvents, setAllEvents] = useState<ApiEvent[]>([]);
  const [allReports, setAllReports] = useState<ReportDetail[]>([]);
  const [liveRecords, setLiveRecords] = useState<IncidentLiveRecord[]>([]);
  const [loading, setLoading] = useState(true);

  const [feedFilter, setFeedFilter] = useState<"all" | "incident" | "report">("all");
  const [selectedId, setSelectedId] = useState<string>("");

  // Sidebar
  const [incidentPhotos, setIncidentPhotos] = useState<DisasterPhoto[]>([]);
  const [loadingPhotos, setLoadingPhotos] = useState(false);
  const [expandedPhoto, setExpandedPhoto] = useState<DisasterPhoto | null>(null);
  const [confirmations, setConfirmations] = useState<SocialEventConfirmationsResponse | null>(null);
  const [socialLoading, setSocialLoading] = useState(false);
  const [socialMessage, setSocialMessage] = useState("");
  const [observationText, setObservationText] = useState("");

  const refreshData = useCallback(async () => {
    let events: ApiEvent[] = [];
    try {
      events = await fetchEvents({ active_only: false, limit: 500 });
      if (!events.length) events = await fetchEvents();
    } catch (e) { console.error(e); }
    setAllEvents(events);

    const liveIncidents = await fetchLiveIncidents();
    setLiveRecords(liveIncidents);

    let reports: ReportDetail[] = [];
    try { reports = await fetchReports({ limit: 1000 }); }
    catch (e) { console.error(e); }
    setAllReports(reports);
  }, []);

  useEffect(() => {
    async function load() {
      try { await refreshData(); }
      finally { setLoading(false); }
    }
    void load();
  }, [refreshData]);

  useEffect(() => {
    const id = window.setInterval(() => void refreshData(), LIVE_INCIDENT_POLL_MS);
    return () => window.clearInterval(id);
  }, [refreshData]);

  // Build flat incident list
  const allIncidents = useMemo(
    () => buildAllIncidents(allEvents, liveRecords, allReports),
    [allEvents, liveRecords, allReports],
  );

  const filtered = useMemo(() => {
    if (feedFilter === "incident") return allIncidents.filter((i) => i.kind === "incident");
    if (feedFilter === "report") return allIncidents.filter((i) => i.kind === "report");
    return allIncidents;
  }, [allIncidents, feedFilter]);

  // Auto-select first on load
  useEffect(() => {
    if (filtered.length === 0) { setSelectedId(""); return; }
    if (!filtered.some((i) => i.id === selectedId)) setSelectedId(filtered[0].id);
  }, [filtered, selectedId]);

  const selected = filtered.find((i) => i.id === selectedId);

  // Find parent event for selected incident
  const parentEvent = useMemo(
    () => allEvents.find((e) => e.id === selected?.eventId),
    [allEvents, selected],
  );

  const stats = useMemo(() => ({
    total: allIncidents.length,
    live: liveRecords.length,
    reports: allReports.length,
    critical: allIncidents.filter((i) => i.priority === "Critical").length,
  }), [allIncidents, liveRecords, allReports]);

  // Photos — if the report has embedded bucket URLs use those directly, else fetch generic
  useEffect(() => {
    if (!selected) { setIncidentPhotos([]); return; }
    // Use media URLs extracted from the report description (Supabase bucket)
    if (selected.mediaUrls && selected.mediaUrls.length > 0) {
      setIncidentPhotos(
        selected.mediaUrls.map((url, i) => ({ id: `media-${i}`, url, label: selected.disasterType })),
      );
      return;
    }
    setLoadingPhotos(true);
    fetchDisasterPhotos({ disaster_type: selected.disasterType.toLowerCase(), limit: 6 })
      .then(setIncidentPhotos)
      .catch(() => setIncidentPhotos([]))
      .finally(() => setLoadingPhotos(false));
  }, [selected]);

  // Social confirmations — use the parent event id
  useEffect(() => {
    if (!selected?.eventId || selected.eventId === "unlinked") { setConfirmations(null); return; }
    fetchSocialEventConfirmations(selected.eventId)
      .then(setConfirmations)
      .catch(() => setConfirmations(null));
  }, [selected]);

  const handleSocialConfirm = async () => {
    if (!selected) return;
    setSocialLoading(true);
    setSocialMessage("");
    try {
      const result = await confirmSocialEvent(selected.eventId, { latitude: selected.lat, longitude: selected.lng });
      setSocialMessage(`${result.message} Confidence: ${Math.round(result.new_confidence * 100)}%.`);
      setConfirmations(await fetchSocialEventConfirmations(selected.eventId));
      await refreshData();
    } catch { setSocialMessage("Unable to record confirmation."); }
    finally { setSocialLoading(false); }
  };

  const handleSocialObservation = async () => {
    if (!selected || !observationText.trim()) return;
    setSocialLoading(true);
    setSocialMessage("");
    try {
      const result = await postSocialObservation({
        latitude: selected.lat,
        longitude: selected.lng,
        disaster_type: selected.disasterType.toLowerCase(),
        observation: observationText.trim(),
      });
      setSocialMessage(`${result.message} Linked event ${result.event_id}.`);
      setObservationText("");
      await refreshData();
      if (selected.eventId !== "unlinked") {
        setConfirmations(await fetchSocialEventConfirmations(selected.eventId));
      }
    } catch { setSocialMessage("Unable to post observation."); }
    finally { setSocialLoading(false); }
  };

  const tabs = [
    { key: "all" as const, label: "All", count: allIncidents.length },
    { key: "incident" as const, label: "Live incidents", count: stats.live },
    { key: "report" as const, label: "Reports", count: stats.reports },
  ];

  return (
    <OpsShell
      title="Incident Command Board"
      subtitle="All linked incidents and reports across every event."
      tag="Incident stream live"
    >
      {/* Stats */}
      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {loading ? (
          Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-24 rounded-2xl" />)
        ) : (
          <>
            <StatsCard label="Total Incidents" value={stats.total} trend="up" delta="+4 in last hour" />
            <StatsCard label="Live Queue" value={stats.live} trend="up" delta="Active" />
            <StatsCard label="Reports" value={stats.reports} trend="flat" delta="Filed" />
            <StatsCard label="Critical" value={stats.critical} trend="flat" delta="High priority" />
          </>
        )}
      </section>

      {/* Table + sidebar */}
      <section className="grid gap-4 xl:grid-cols-12">

        {/* Left: flat incident list */}
        <div className="xl:col-span-8">
          {/* Filter tabs */}
          <div
            role="tablist"
            className="mb-3 flex items-center gap-0 overflow-hidden rounded-xl border border-white/[0.09] bg-black/30 p-1 shadow-[inset_0_1px_0_rgba(255,255,255,0.04)]"
          >
            {tabs.map((tab) => (
              <button
                key={tab.key}
                role="tab"
                aria-selected={feedFilter === tab.key}
                onClick={() => setFeedFilter(tab.key)}
                className={`flex flex-1 items-center justify-center gap-2 rounded-lg px-3 py-1.5 text-[11px] font-semibold uppercase tracking-[0.14em] transition-all ${
                  feedFilter === tab.key
                    ? "bg-white/[0.09] text-white shadow-[inset_0_1px_0_rgba(255,255,255,0.08)]"
                    : "text-white/40 hover:text-white/60"
                }`}
              >
                {tab.label}
                <span className={`rounded-md px-1.5 py-0.5 text-[10px] font-bold tabular-nums ${
                  feedFilter === tab.key ? "bg-white/[0.12] text-white/80" : "bg-white/[0.06] text-white/30"
                }`}>
                  {tab.count}
                </span>
              </button>
            ))}
          </div>

          <div className="overflow-hidden rounded-2xl border border-white/[0.09] bg-black/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)]">
            {loading ? (
              <div className="space-y-2 p-4">
                <Skeleton className="h-10 w-full rounded-xl" />
                {Array.from({ length: 7 }).map((_, i) => <Skeleton key={i} className="h-14 w-full rounded-xl" />)}
              </div>
            ) : (
              <div className="max-h-[66vh] overflow-auto">
                <table className="w-full min-w-[760px] table-fixed text-left">
                  <thead className="sticky top-0 z-10 border-b border-white/[0.09] bg-slate-950/60 backdrop-blur-sm">
                    <tr className="text-[10px] uppercase tracking-[0.18em] text-white/40">
                      <th className="w-[24%] px-4 py-3 font-semibold">Type · Event</th>
                      <th className="w-[12%] px-4 py-3 font-semibold">Source</th>
                      <th className="w-[20%] px-4 py-3 font-semibold">Location</th>
                      <th className="w-[18%] px-4 py-3 font-semibold">Created</th>
                      <th className="w-[10%] px-4 py-3 font-semibold">Priority</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filtered.length === 0 ? (
                      <tr>
                        <td colSpan={6} className="px-4 py-16 text-center">
                          <div className="flex flex-col items-center gap-3">
                            <div className="flex h-10 w-10 items-center justify-center rounded-xl border border-white/[0.09] bg-white/[0.04]">
                              <Activity className="h-5 w-5 text-white/25" />
                            </div>
                            <p className="text-sm font-medium text-white/50">No incidents yet</p>
                            <p className="text-xs text-white/30">Incidents will appear as events are reported.</p>
                          </div>
                        </td>
                      </tr>
                    ) : (
                      filtered.map((inc) => (
                        <IncidentRow
                          key={inc.id}
                          inc={inc}
                          selected={inc.id === selectedId}
                          onClick={() => setSelectedId(inc.id)}
                        />
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>

        {/* Right sidebar */}
        <aside className="xl:col-span-4">
          <div className="sticky top-24 space-y-3">

            {/* Selected incident detail */}
            <div className="overflow-hidden rounded-2xl border border-white/[0.09] bg-black/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)]">
              <div className="border-b border-white/[0.07] px-4 py-3">
                <p className="text-[9.5px] font-semibold uppercase tracking-[0.18em] text-white/35">
                  {selected?.kind === "incident" ? "Live Incident" : "Report"} Detail
                </p>
              </div>

              {loading ? (
                <div className="space-y-3 p-4">
                  <Skeleton className="h-16 w-full rounded-xl" />
                  <Skeleton className="h-10 w-full rounded-xl" />
                </div>
              ) : selected ? (
                <div className="divide-y divide-white/[0.05]">
                  {/* Hero */}
                  <div className="p-4">
                    <div className="flex items-start justify-between gap-2">
                      <div className="min-w-0">
                        <p className="truncate text-base font-bold capitalize text-white">{selected.disasterType}</p>
                        <p className="mt-0.5 font-mono text-[9.5px] text-white/30 break-all">{selected.id}</p>
                      </div>
                      <StatusPill status={selected.status} />
                    </div>
                    <div className="mt-2 flex gap-2">
                      <PriorityChip priority={selected.priority} />
                      <span className={`inline-flex items-center rounded px-2 py-0.5 text-[9px] font-semibold uppercase tracking-wide ${
                        selected.kind === "incident"
                          ? "bg-cyan-500/15 text-cyan-300/80"
                          : "bg-white/[0.06] text-white/40"
                      }`}>
                        {selected.kind}
                      </span>
                    </div>
                  </div>

                  {/* Parent event */}
                  {parentEvent && (
                    <div className="px-4 py-3">
                      <p className="text-[9.5px] uppercase tracking-[0.16em] text-white/35">Parent Event</p>
                      <p className="mt-0.5 text-sm font-semibold capitalize text-white/80">{parentEvent.type}</p>
                      <p className="mt-0.5 font-mono text-[10px] text-white/30 break-all">{parentEvent.id}</p>
                      <div className="mt-1 flex flex-wrap gap-2">
                        <span className="text-[10px] text-white/40">
                          Severity · <span className="capitalize">{parentEvent.severity}</span>
                        </span>
                        <span className="text-[10px] text-white/40">
                          Confidence · {Math.round(parentEvent.confidence)}%
                        </span>
                        <span className={`text-[10px] ${parentEvent.active ? "text-emerald-400/70" : "text-white/30"}`}>
                          {parentEvent.active ? "Active" : "Closed"}
                        </span>
                      </div>
                    </div>
                  )}

                  {/* Location */}
                  <div className="px-4 py-3">
                    <p className="flex items-center gap-1 text-[9.5px] uppercase tracking-[0.16em] text-white/35">
                      <MapPin className="h-2.5 w-2.5" /> Location
                    </p>
                    <p className="mt-0.5 font-mono text-sm text-white/75">{selected.location}</p>
                    <p className="mt-0.5 text-[10px] text-white/40">{selected.createdAt}</p>
                  </div>

                  {/* Source */}
                  <div className="px-4 py-3">
                    <p className="text-[9.5px] uppercase tracking-[0.16em] text-white/35">Source</p>
                    <p className="mt-0.5 text-sm text-white/75">{selected.source}</p>
                  </div>

                  {/* People / injuries (reports only) */}
                  {selected.kind === "report" && selected.peopleCount != null && (
                    <div className="px-4 py-3">
                      <p className="text-[9.5px] uppercase tracking-[0.16em] text-white/35">People Affected</p>
                      <p className="mt-0.5 text-sm font-semibold text-white/80">{selected.peopleCount}</p>
                      {selected.injuries && (
                        <p className="mt-0.5 text-[10px] text-red-300/80">Injuries reported</p>
                      )}
                    </div>
                  )}

                  {/* Description */}
                  {selected.description && (
                    <div className="px-4 py-3">
                      <p className="text-[9.5px] uppercase tracking-[0.16em] text-white/35">Description</p>
                      <p className="mt-0.5 text-xs leading-relaxed text-white/65">{selected.description}</p>
                    </div>
                  )}
                </div>
              ) : (
                <div className="flex flex-col items-center gap-3 px-4 py-12 text-center">
                  <div className="flex h-10 w-10 items-center justify-center rounded-xl border border-white/[0.09] bg-white/[0.04]">
                    <AlertTriangle className="h-5 w-5 text-white/20" />
                  </div>
                  <p className="text-sm text-white/40">Select an incident</p>
                </div>
              )}
            </div>

            {/* Photos */}
            {selected && (
              <div className="overflow-hidden rounded-2xl border border-white/[0.09] bg-black/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)]">
                <div className="flex items-center justify-between border-b border-white/[0.07] px-4 py-3">
                  <p className="text-[9.5px] font-semibold uppercase tracking-[0.18em] text-white/35">Incident Photos</p>
                  {selected.mediaUrls && selected.mediaUrls.length > 0 && (
                    <span className="rounded-full bg-emerald-500/10 px-2 py-0.5 text-[9px] font-semibold text-emerald-400/80 border border-emerald-400/20">
                      from report
                    </span>
                  )}
                </div>
                <div className="p-3">
                  {loadingPhotos ? (
                    <div className="grid grid-cols-3 gap-2">
                      {Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} className="h-16 rounded-lg" />)}
                    </div>
                  ) : incidentPhotos.length > 0 ? (
                    <div className="grid grid-cols-3 gap-2">
                      {incidentPhotos.map((photo) => (
                        <button
                          key={photo.id}
                          type="button"
                          onClick={() => setExpandedPhoto(photo)}
                          className="overflow-hidden rounded-lg border border-white/[0.08] transition hover:border-white/20"
                        >
                          <img
                            src={photo.url}
                            alt={photo.label ?? selected.disasterType}
                            className="h-16 w-full object-cover transition hover:scale-[1.04]"
                          />
                        </button>
                      ))}
                    </div>
                  ) : (
                    <div className="flex flex-col items-center gap-1.5 py-4">
                      <Activity className="h-4 w-4 text-white/20" />
                      <p className="text-[11px] text-white/35">No photos for this type.</p>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Social signals */}
            {selected && selected.eventId !== "unlinked" && (
              <div className="overflow-hidden rounded-2xl border border-white/[0.09] bg-black/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)]">
                <div className="flex items-center justify-between border-b border-white/[0.07] px-4 py-3">
                  <p className="text-[9.5px] font-semibold uppercase tracking-[0.18em] text-white/35">Social Signals</p>
                  <span className="rounded-md border border-white/[0.09] bg-white/[0.05] px-1.5 py-0.5 text-[10px] font-bold tabular-nums text-white/60">
                    {confirmations?.confirmation_count ?? 0} confirmations
                  </span>
                </div>
                <div className="space-y-2 p-3">
                  <Button size="xs" variant="outline" className="w-full" onClick={() => void handleSocialConfirm()} disabled={socialLoading}>
                    {socialLoading ? "Submitting..." : "Confirm Event Nearby"}
                  </Button>
                  <textarea
                    value={observationText}
                    onChange={(e) => setObservationText(e.target.value)}
                    className="w-full rounded-xl border border-white/[0.12] bg-slate-950/80 px-3 py-2 text-xs text-white placeholder:text-white/30 focus:border-white/25 focus:outline-none"
                    rows={3}
                    placeholder="Post local observation for this location..."
                  />
                  <Button size="xs" className="w-full" onClick={() => void handleSocialObservation()} disabled={socialLoading || !observationText.trim()}>
                    Post Observation
                  </Button>
                  {socialMessage && <p className="text-[11px] leading-relaxed text-cyan-300/90">{socialMessage}</p>}
                </div>
              </div>
            )}

          </div>
        </aside>
      </section>

      {/* Photo lightbox */}
      {expandedPhoto && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4" onClick={() => setExpandedPhoto(null)}>
          <div className="relative max-h-[90vh] w-full max-w-5xl rounded-2xl border border-white/[0.12] bg-black/70 p-2 shadow-[0_32px_80px_rgba(0,0,0,0.7)]" onClick={(e) => e.stopPropagation()}>
            <button type="button" className="absolute right-3 top-3 rounded-lg border border-white/[0.15] bg-black/60 px-2.5 py-1 text-xs font-medium text-white/80 transition hover:bg-white/10" onClick={() => setExpandedPhoto(null)}>
              Close
            </button>
            <img src={expandedPhoto.url} alt={expandedPhoto.label ?? selected?.disasterType ?? "Photo"} className="max-h-[82vh] w-full rounded-xl object-contain" />
          </div>
        </div>
      )}
    </OpsShell>
  );
}
