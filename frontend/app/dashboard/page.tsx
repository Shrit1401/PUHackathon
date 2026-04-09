"use client";

import dynamic from "next/dynamic";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { HeaderBar } from "../../components/header-bar";
import { MetricsBar } from "../../components/metrics-bar";
import { StatusPill } from "../../components/status-pill";
import { EventDetailsPanel } from "../../components/event-details-panel";
import { WeatherForecastPanel } from "../../components/weather-forecast-panel";
import { OpsGlanceCharts } from "../../components/ops-glance-charts";
import { Skeleton } from "../../components/ui/skeleton";
import { Card, CardContent, CardHeader, CardTitle } from "../../components/ui/card";
import { fetchEvents, fetchPredictions, fetchReports, type ReportDetail } from "../../lib/api";
import { DisasterEvent } from "../../lib/types";
import { IncidentRecord, LiveSummary } from "../../lib/ops-types";
import { subscribeToAssignments, subscribeToIncidents } from "../../lib/realtime";
import type { ApiEvent } from "../../lib/api";

const DisasterMap = dynamic(
  () => import("../../components/disaster-map").then((mod) => mod.DisasterMap),
  { ssr: false, loading: () => <Skeleton className="h-full w-full rounded-2xl" /> },
);

function mapApiEvent(event: ApiEvent): DisasterEvent {
  const name = `${event.type.charAt(0).toUpperCase()}${event.type.slice(1)} Event`;
  const label = `Lat ${event.latitude.toFixed(3)}, Lng ${event.longitude.toFixed(3)}`;
  return {
    id: event.id,
    type: event.type,
    name,
    createdAt: event.created_at,
    location: { label, lat: event.latitude, lng: event.longitude },
    severity: event.severity,
    confidenceScore: Math.round(event.confidence),
    socialCount: event.source_breakdown.social ?? 0,
    newsCount: event.source_breakdown.news ?? 0,
    userReports: event.source_breakdown.app ?? 0,
    whatsappReports: event.source_breakdown.whatsapp ?? 0,
    weatherSeverity: Number((event.weather_severity / 10).toFixed(1)),
  };
}

export default function Home() {
  const [events, setEvents] = useState<DisasterEvent[]>([]);
  const [selectedId, setSelectedId] = useState<string | undefined>(undefined);
  const [predictions, setPredictions] = useState<Array<{ statement: string }>>([]);
  const [loadingEvents, setLoadingEvents] = useState(true);
  const [weatherSeverity, setWeatherSeverity] = useState<number | null>(null);
  const [liveTick, setLiveTick] = useState(0);
  const [eventReports, setEventReports] = useState<ReportDetail[]>([]);
  const [loadingReports, setLoadingReports] = useState(false);
  const selectedIdRef = useRef(selectedId);
  selectedIdRef.current = selectedId;

  const selectedEvent = useMemo(
    () => events.find((e) => e.id === selectedId),
    [events, selectedId],
  );

  const incidents = useMemo<IncidentRecord[]>(
    () => events.map((e) => ({
      id: e.id,
      user: "System",
      incidentType: e.name,
      status: "Assigned",
      location: e.location.label,
      createdAt: e.createdAt ? new Date(e.createdAt).toLocaleString() : "Live",
      createdAtRaw: e.createdAt,
      priority: e.severity === "high" ? "Critical" : e.severity === "medium" ? "High" : "Medium",
      confidence: e.confidenceScore,
      lat: e.location.lat,
      lng: e.location.lng,
      summary: `${e.type} incident detected near ${e.location.label}.`,
    })),
    [events],
  );

  const liveSummaries = useMemo<LiveSummary[]>(
    () => events.slice(0, 3).map((e) => ({
      id: `summary-${e.id}`,
      title: `${e.name} monitoring`,
      detail: `Confidence at ${e.confidenceScore}% in ${e.location.label}.`,
      level: e.severity === "high" ? "critical" : e.severity === "medium" ? "warning" : "info",
      updatedAt: "Live",
    })),
    [events],
  );

  const metrics = useMemo(() => {
    if (!events.length) return { activeDisasters: 0, avgConfidence: 0, totalReports: 0, highRiskZones: 0 };
    const totalReports = events.reduce((s, e) => s + e.socialCount + e.newsCount + e.userReports + e.whatsappReports, 0);
    const avgConfidence = Math.round(events.reduce((s, e) => s + e.confidenceScore, 0) / events.length);
    const highRiskZones = events.filter((e) => e.severity === "high").length;
    return { activeDisasters: events.length, avgConfidence, totalReports, highRiskZones };
  }, [events]);

  const loadData = useCallback(async (showLoading = true) => {
    if (showLoading) setLoadingEvents(true);

    // Fire both in parallel — update events as soon as they land
    const [eventsResult, predictionsResult] = await Promise.allSettled([
      fetchEvents(),
      fetchPredictions(),
    ]);

    if (eventsResult.status === "fulfilled") {
      const mapped = eventsResult.value.map(mapApiEvent);
      setEvents(mapped);
      if (mapped.length > 0 && (!selectedIdRef.current || !mapped.some((e) => e.id === selectedIdRef.current))) {
        setSelectedId(mapped[0].id);
      }
    } else {
      setEvents([]);
    }

    if (predictionsResult.status === "fulfilled") {
      setPredictions(predictionsResult.value.map((p) => ({ statement: p.warning })));
    } else {
      setPredictions([]);
    }

    setLoadingEvents(false);
  }, []); // stable — no deps that change

  useEffect(() => {
    void loadData(true);
  }, []); // run once on mount

  useEffect(() => {
    const unsub1 = subscribeToIncidents(() => setLiveTick((v) => v + 1));
    const unsub2 = subscribeToAssignments(() => setLiveTick((v) => v + 1));
    return () => { unsub1(); unsub2(); };
  }, []);

  // Fetch reports for selected event
  useEffect(() => {
    if (!selectedId) { setEventReports([]); return; }
    setLoadingReports(true);
    fetchReports({ event_id: selectedId, limit: 100 })
      .then(setEventReports)
      .catch(() => setEventReports([]))
      .finally(() => setLoadingReports(false));
  }, [selectedId]);

  const handleSelectEvent = (id: string) => {
    setSelectedId(id);
    setWeatherSeverity(null);
  };

  const activeEmergencies = incidents.filter((i) => i.status !== "Resolved").length;

  return (
    <div className="relative min-h-screen overflow-hidden bg-[#05060a] text-slate-100">
      <div className="lp-ambient pointer-events-none absolute inset-0 -z-10" />
      <div className="lp-orbit pointer-events-none absolute inset-0 -z-10" />
      <div className="lp-grain pointer-events-none absolute inset-0 -z-10" />
      <div className="pointer-events-none absolute inset-x-0 top-0 -z-10 h-56 bg-[radial-gradient(ellipse_at_top,rgba(56,189,248,0.14),transparent_65%)]" />
      <HeaderBar onRefresh={() => void loadData(true)} />

      <main className="h-[calc(100vh-72px)] p-4 sm:p-5">
        <div className="mx-auto flex h-full w-full max-w-[1560px] flex-col gap-3 sm:gap-4">
          {/* Header strip */}
          <section className="motion-reveal rounded-2xl border border-white/[0.08] bg-white/[0.025] px-4 py-3 shadow-[inset_0_1px_0_rgba(255,255,255,0.05),0_14px_42px_rgba(2,6,23,0.45)] backdrop-blur-xl sm:px-5">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="text-[9.5px] uppercase tracking-[0.26em] text-cyan-200/45">Live Operations Grid</p>
                <h1 className="mt-0.5 text-xl font-semibold tracking-tight text-white/92 sm:text-2xl">National Disaster Intelligence Platform</h1>
              </div>
              <div className="flex items-center gap-2 rounded-full border border-cyan-300/18 bg-cyan-300/8 px-3 py-1.5 text-[9.5px] font-semibold uppercase tracking-[0.18em] text-cyan-100/80 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)]">
                <span className={`inline-flex h-1.5 w-1.5 rounded-full shadow-[0_0_8px_rgba(110,231,183,0.8)] ${loadingEvents ? "animate-pulse bg-amber-300" : "status-dot-live bg-emerald-300"}`} />
                {loadingEvents ? "Syncing data" : liveTick > 0 ? "Live feed active" : "Channel standby"}
              </div>
            </div>
          </section>

          {/* Metrics row */}
          <section className="motion-reveal motion-reveal-delay-1">
            <div className="grid gap-2 sm:grid-cols-2 xl:grid-cols-4">
              {loadingEvents ? (
                Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-16 rounded-xl" />)
              ) : (
                <>
                  <CompactMetric label="Total Incidents" value={incidents.length} trend="Live" />
                  <CompactMetric label="Active Emergencies" value={activeEmergencies} trend="Live" />
                  <CompactMetric label="Avg Response Time" value="—" trend="Realtime" />
                  <CompactMetric label="Live Summaries" value={liveSummaries.length} trend="Realtime" />
                </>
              )}
            </div>
          </section>

          {/* Main grid */}
          <div className="grid min-h-0 flex-1 grid-cols-1 gap-4 xl:grid-cols-12">
            {/* Map */}
            <section className="motion-reveal motion-reveal-delay-1 h-full min-h-[66vh] rounded-2xl border border-white/10 bg-black/20 p-2 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)] backdrop-blur-xl xl:col-span-9">
              {loadingEvents ? (
                <div className="flex h-full flex-col gap-3 rounded-2xl border border-white/10 bg-black/25 p-4 backdrop-blur-xl">
                  <div className="flex items-center justify-between">
                    <Skeleton className="h-5 w-40" />
                    <Skeleton className="h-5 w-24" />
                  </div>
                  <Skeleton className="h-8 w-56" />
                  <Skeleton className="flex-1 rounded-xl" />
                </div>
              ) : events.length > 0 ? (
                <DisasterMap
                  events={events}
                  selectedEventId={selectedEvent?.id}
                  onSelectEvent={handleSelectEvent}
                  weatherSeverity={weatherSeverity ?? undefined}
                  responders={[]}
                />
              ) : (
                <div className="flex h-full min-h-[420px] flex-col items-center justify-center rounded-2xl border border-dashed border-cyan-200/20 bg-slate-950/40 px-6 text-center">
                  <p className="text-xs uppercase tracking-[0.22em] text-cyan-100/50">Situation Monitor</p>
                  <h2 className="mt-3 text-2xl font-semibold tracking-tight text-white">No active events right now</h2>
                  <p className="mt-3 max-w-md text-sm text-slate-300/85">The map will automatically populate when new reports or disasters are detected.</p>
                </div>
              )}
            </section>

            {/* Sidebar */}
            <aside className="motion-reveal motion-reveal-delay-2 flex h-full min-h-0 flex-col gap-3 overflow-y-auto pr-1 xl:col-span-3">
              {loadingEvents ? (
                <>
                  <Skeleton className="h-24 w-full rounded-2xl" />
                  <Skeleton className="h-40 w-full rounded-2xl" />
                  <Skeleton className="h-40 w-full rounded-2xl" />
                  <Skeleton className="h-32 w-full rounded-2xl" />
                  <Skeleton className="h-32 w-full rounded-2xl" />
                </>
              ) : (
                <>
                  <MetricsBar
                    activeDisasters={metrics.activeDisasters}
                    avgConfidence={metrics.avgConfidence}
                    totalReports={metrics.totalReports}
                    highRiskZones={metrics.highRiskZones}
                  />
                  <EventDetailsPanel event={selectedEvent} weatherSeverity={weatherSeverity ?? undefined} />
                  {selectedEvent && (
                    <Card motion="surface">
                      <CardHeader><CardTitle>Focused Incident</CardTitle></CardHeader>
                      <CardContent className="space-y-2.5">
                        <div className="rounded-xl border border-white/10 bg-white/[0.03] p-2.5">
                          <p className="text-[10px] uppercase tracking-[0.12em] text-white/45">Incident ID</p>
                          <p className="mt-1 text-sm font-medium text-white/90">{selectedEvent.id}</p>
                        </div>
                        <div className="grid grid-cols-2 gap-2">
                          <div className="rounded-xl border border-white/10 bg-white/[0.03] p-2.5">
                            <p className="text-[10px] uppercase tracking-[0.12em] text-white/45">Status</p>
                            <StatusPill status="Assigned" />
                          </div>
                          <div className="rounded-xl border border-white/10 bg-white/[0.03] p-2.5">
                            <p className="text-[10px] uppercase tracking-[0.12em] text-white/45">Confidence</p>
                            <p className="mt-1 text-sm text-cyan-100/85">{selectedEvent.confidenceScore}%</p>
                          </div>
                        </div>
                        <div className="rounded-xl border border-white/10 bg-white/[0.03] p-2.5">
                          <p className="text-[10px] uppercase tracking-[0.12em] text-white/45">Location</p>
                          <p className="mt-1 text-xs text-white/75">{selectedEvent.location.label}</p>
                        </div>
                        <div className="rounded-xl border border-white/10 bg-white/[0.03] p-2.5">
                          <p className="text-[10px] uppercase tracking-[0.12em] text-white/45">Created</p>
                          <p className="mt-1 text-xs text-white/75">
                            {selectedEvent.createdAt ? new Date(selectedEvent.createdAt).toLocaleString() : "Live feed"}
                          </p>
                        </div>
                      </CardContent>
                    </Card>
                  )}
                  {selectedEvent && (
                    <WeatherForecastPanel event={selectedEvent} onSeverityChange={setWeatherSeverity} />
                  )}

                  {/* Reports linked to selected event */}
                  {selectedEvent && (
                    <Card motion="surface">
                      <CardHeader>
                        <div className="flex items-center justify-between gap-2">
                          <CardTitle>Linked Reports</CardTitle>
                          <span className="rounded-full border border-white/[0.09] bg-white/[0.05] px-2 py-0.5 font-mono text-[10px] text-white/50">
                            {loadingReports ? "…" : eventReports.length}
                          </span>
                        </div>
                      </CardHeader>
                      <CardContent>
                        {loadingReports ? (
                          <div className="space-y-2">
                            {Array.from({ length: 3 }).map((_, i) => (
                              <Skeleton key={i} className="h-14 w-full rounded-xl" />
                            ))}
                          </div>
                        ) : eventReports.length === 0 ? (
                          <p className="py-4 text-center text-[11px] text-white/35">No reports linked to this event.</p>
                        ) : (
                          <div className="max-h-72 space-y-1.5 overflow-y-auto">
                            {eventReports.map((r) => {
                              // Extract first image URL from description if any
                              const imgMatch = r.description?.match(/https?:\/\/\S+\.(jpg|jpeg|png|gif|webp)(\?\S*)?/i);
                              const imgUrl = imgMatch?.[0];
                              const cleanDesc = r.description
                                ?.split("|")
                                .map((p) => p.trim())
                                .filter((p) => !/^https?:\/\//i.test(p) && !/\.(jpg|jpeg|png|gif|webp)/i.test(p))
                                .filter(Boolean)
                                .join(" · ") || undefined;

                              return (
                                <div
                                  key={r.id}
                                  className="overflow-hidden rounded-xl border border-white/[0.08] bg-white/[0.03]"
                                >
                                  {imgUrl && (
                                    <img
                                      src={imgUrl}
                                      alt={r.disaster_type}
                                      className="h-24 w-full object-cover"
                                    />
                                  )}
                                  <div className="p-2.5">
                                    <div className="flex items-center justify-between gap-2">
                                      <span className="text-[10px] font-semibold capitalize text-white/80">{r.disaster_type}</span>
                                      <span className="font-mono text-[9px] text-white/35">{r.source}</span>
                                    </div>
                                    {cleanDesc && (
                                      <p className="mt-0.5 line-clamp-2 text-[10px] leading-relaxed text-white/50">{cleanDesc}</p>
                                    )}
                                    <div className="mt-1.5 flex flex-wrap items-center gap-x-3 gap-y-0.5 text-[9.5px] text-white/35">
                                      <span>{r.latitude.toFixed(3)}, {r.longitude.toFixed(3)}</span>
                                      {r.people_count != null && <span>{r.people_count} people</span>}
                                      {r.injuries && <span className="text-red-400/70">injuries</span>}
                                      {r.created_at && <span>{new Date(r.created_at).toLocaleString()}</span>}
                                    </div>
                                  </div>
                                </div>
                              );
                            })}
                          </div>
                        )}
                      </CardContent>
                    </Card>
                  )}
                  <Card motion="surface">
                    <CardHeader>
                      <CardTitle className="text-base">At a glance</CardTitle>
                      <p className="text-xs font-normal text-white/55">
                        Charts and a single headline — no extra panels to parse.
                      </p>
                    </CardHeader>
                    <CardContent className="space-y-3">
                      <OpsGlanceCharts incidents={incidents} />
                      <div className="rounded-xl border border-white/10 bg-white/[0.03] p-3">
                        <p className="text-[11px] uppercase tracking-[0.12em] text-white/45">Headline</p>
                        <p className="mt-1 text-sm text-white/85">
                          {predictions[0]?.statement ?? "No prediction text yet."}
                        </p>
                      </div>
                    </CardContent>
                  </Card>
                  <Card motion="surface">
                    <CardHeader><CardTitle>Live Operational Summaries</CardTitle></CardHeader>
                    <CardContent className="space-y-2">
                      {liveSummaries.slice(0, 3).map((summary) => (
                        <div key={summary.id} className="rounded-xl border border-white/10 bg-white/[0.03] p-2.5">
                          <div className="flex items-center justify-between gap-2">
                            <p className="text-xs font-medium text-white/85">{summary.title}</p>
                            <StatusPill status={summary.level === "critical" ? "Escalated" : summary.level === "warning" ? "Pending" : "Assigned"} />
                          </div>
                          <p className="mt-1 text-[11px] text-white/60">{summary.detail}</p>
                        </div>
                      ))}
                    </CardContent>
                  </Card>
                </>
              )}
            </aside>
          </div>
        </div>
      </main>
    </div>
  );
}

function CompactMetric({ label, value, trend }: { label: string; value: string | number; trend: string }) {
  return (
    <div className="motion-pressable rounded-xl border border-white/[0.09] bg-black/22 px-3 py-2.5 shadow-[inset_0_1px_0_rgba(255,255,255,0.05),0_2px_8px_rgba(0,0,0,0.25)] hover:-translate-y-0.5 hover:border-white/[0.13] hover:bg-black/28">
      <p className="text-[9.5px] uppercase tracking-[0.16em] text-white/42">{label}</p>
      <p className="mt-0.5 text-lg font-semibold tabular-nums tracking-tight text-white/90">{value}</p>
      <p className="text-[10px] tracking-wide text-cyan-200/60">{trend}</p>
    </div>
  );
}
