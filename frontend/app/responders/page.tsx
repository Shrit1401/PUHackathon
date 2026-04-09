"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import dynamic from "next/dynamic";
import { OpsShell } from "@/components/ops-shell";
import { ResponderCard } from "@/components/responder-card";
import { StatsCard } from "@/components/stats-card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { ResponderRecord } from "@/lib/ops-types";
import {
  fetchLiveIncidents,
  fetchResponders,
  type IncidentLiveRecord,
  updateResponder,
} from "@/lib/api";
import { subscribeToResponders } from "@/lib/realtime";
import {
  distanceKmBetweenLatLng,
  easeInOutCubic,
  fetchDrivingRoute,
  pointAlongPath,
} from "@/lib/twin-route";
import { Activity, MapPin, Zap } from "lucide-react";

const ResponderDigitalTwinMap = dynamic(
  () =>
    import("@/components/responder-digital-twin-map").then((m) => m.ResponderDigitalTwinMap),
  { ssr: false, loading: () => <Skeleton className="h-[360px] w-full rounded-none" /> },
);

function mapAvailability(value: string): ResponderRecord["availability"] {
  if (value === "deployed") return "Deployed";
  if (value === "en_route") return "En Route";
  if (value === "offline") return "Offline";
  return "Ready";
}

type DispatchIncident = {
  id: string;
  type: string;
  confidence: number;
  severity: "low" | "medium" | "high";
  latitude: number;
  longitude: number;
  createdAt: string;
};

type DigitalTwinMission = {
  responderId: string;
  incidentId: string;
  responderName: string;
  incidentType: string;
  startLat: number;
  startLng: number;
  targetLat: number;
  targetLng: number;
  routePath: [number, number][];
  distanceM: number;
  pathSource: "road" | "straight";
  progress: number;
  bearing: number;
  status: "running" | "arrived";
  startedAt: string;
};

type RoutePreview = {
  path: [number, number][];
  distanceM: number;
  source: "road" | "straight";
};

function pickNearestEmsResponderId(
  list: ResponderRecord[],
  targetLat: number,
  targetLng: number,
): string {
  if (list.length === 0) return "";
  const ems = list.filter((r) => r.specialization.toLowerCase() === "ambulance");
  const pool = ems.length > 0 ? ems : list;
  let best = pool[0];
  let bestKm = Infinity;
  for (const r of pool) {
    const km = distanceKmBetweenLatLng(r.lat, r.lng, targetLat, targetLng);
    if (km < bestKm) {
      bestKm = km;
      best = r;
    }
  }
  return best.id;
}

function livePriorityToSeverity(priority: IncidentLiveRecord["priority"]): DispatchIncident["severity"] {
  if (priority === "critical" || priority === "high") return "high";
  if (priority === "medium") return "medium";
  return "low";
}

function livePriorityToDisplayConfidence(priority: IncidentLiveRecord["priority"]): number {
  switch (priority) {
    case "critical":
      return 96;
    case "high":
      return 82;
    case "medium":
      return 58;
    case "low":
      return 35;
    default:
      return 50;
  }
}

function responderDisplayName(responder: ResponderRecord): string {
  const n = responder.name;
  if (/^unit\s/i.test(n.trim())) return n;
  if (
    responder.specialization.toLowerCase() === "ambulance" &&
    !n.toLowerCase().includes("ambulance")
  ) {
    return `EMS · ${n}`;
  }
  return n;
}

export default function RespondersPage() {
  const [responders, setResponders] = useState<ResponderRecord[]>([]);
  const [incidents, setIncidents] = useState<DispatchIncident[]>([]);
  const [loading, setLoading] = useState(true);
  const [dispatchMessage, setDispatchMessage] = useState<string>("");
  const [errorMessage, setErrorMessage] = useState<string>("");
  const [selectedResponderId, setSelectedResponderId] = useState("");
  const [twinTargetIncidentId, setTwinTargetIncidentId] = useState("");
  const [digitalTwinMission, setDigitalTwinMission] = useState<DigitalTwinMission | null>(null);
  const [previewRoute, setPreviewRoute] = useState<RoutePreview | null>(null);
  const [twinRouteLoading, setTwinRouteLoading] = useState(false);

  const animRunRef = useRef<string | null>(null);
  const missionRef = useRef<DigitalTwinMission | null>(null);
  missionRef.current = digitalTwinMission;
  const lastIncidentIdForNearestRef = useRef<string | null>(null);

  const loadDashboardData = useCallback(async () => {
    try {
      const [responderResult, incidentResult] = await Promise.all([
        fetchResponders({ limit: 200 }),
        fetchLiveIncidents({ includeSos: false }),
      ]);

      const mappedResponders: ResponderRecord[] = responderResult.map((responder) => ({
        id: responder.id,
        name: responder.name,
        unit: responder.type.toUpperCase(),
        specialization: responder.type,
        availability: mapAvailability(responder.availability),
        currentStatus: responder.current_status,
        eta: responder.eta_minutes > 0 ? `${responder.eta_minutes} min` : "0 min",
        lat: responder.latitude,
        lng: responder.longitude,
      }));
      setResponders(mappedResponders);

      const mappedIncidents: DispatchIncident[] = incidentResult
        .filter((incident) => incident.status !== "resolved")
        .map((incident) => ({
          id: incident.incident_id,
          type: incident.type,
          confidence: livePriorityToDisplayConfidence(incident.priority),
          severity: livePriorityToSeverity(incident.priority),
          latitude: incident.latitude,
          longitude: incident.longitude,
          createdAt: incident.created_at,
        }))
        .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
      setIncidents(mappedIncidents);
      setTwinTargetIncidentId((previous) => {
        if (previous && mappedIncidents.some((incident) => incident.id === previous)) {
          return previous;
        }
        return mappedIncidents[0]?.id ?? "";
      });
    } catch (error) {
      console.error(error);
      setResponders([]);
      setIncidents([]);
      setErrorMessage("Could not load EMS units or live incidents from the API.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const timeout = window.setTimeout(() => {
      setLoading(true);
      void loadDashboardData();
    }, 0);
    return () => window.clearTimeout(timeout);
  }, [loadDashboardData]);

  useEffect(() => {
    const unsub = subscribeToResponders(() => void loadDashboardData());
    return () => unsub();
  }, [loadDashboardData]);

  const selectedResponder = useMemo(
    () => responders.find((responder) => responder.id === selectedResponderId),
    [responders, selectedResponderId],
  );
  const twinTargetIncident = useMemo(
    () => incidents.find((incident) => incident.id === twinTargetIncidentId),
    [incidents, twinTargetIncidentId],
  );

  useEffect(() => {
    if (!twinTargetIncident || responders.length === 0) return;
    if (digitalTwinMission?.status === "running") return;

    const id = twinTargetIncidentId;
    const incidentChanged = lastIncidentIdForNearestRef.current !== id;
    lastIncidentIdForNearestRef.current = id;

    const selectionStillValid =
      Boolean(selectedResponderId) && responders.some((r) => r.id === selectedResponderId);

    if (!incidentChanged && selectionStillValid) return;

    const nearestId = pickNearestEmsResponderId(
      responders,
      twinTargetIncident.latitude,
      twinTargetIncident.longitude,
    );
    if (nearestId) setSelectedResponderId(nearestId);
  }, [
    twinTargetIncidentId,
    twinTargetIncident,
    responders,
    digitalTwinMission?.status,
    selectedResponderId,
  ]);

  const liveTwin = useMemo(() => {
    if (!digitalTwinMission) return null;
    return pointAlongPath(digitalTwinMission.routePath, digitalTwinMission.progress);
  }, [digitalTwinMission]);

  useEffect(() => {
    if (!selectedResponder || !twinTargetIncident || digitalTwinMission?.status === "running") return;
    let cancelled = false;
    setTwinRouteLoading(true);
    void fetchDrivingRoute(
      selectedResponder.lat,
      selectedResponder.lng,
      twinTargetIncident.latitude,
      twinTargetIncident.longitude,
    )
      .then((route) => {
        if (cancelled) return;
        setPreviewRoute({
          path: route.path,
          distanceM: route.distanceMeters,
          source: route.source,
        });
        setDispatchMessage(
          route.source === "road"
            ? `Street route ready — ${(route.distanceMeters / 1000).toFixed(1)} km on the road network. Tap Dispatch to run the twin.`
            : "Straight-line preview (roads unavailable). Tap Dispatch to run the twin.",
        );
      })
      .catch(() => {
        if (cancelled) return;
        setPreviewRoute(null);
      })
      .finally(() => {
        if (cancelled) return;
        setTwinRouteLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [selectedResponder, twinTargetIncident, digitalTwinMission?.status]);

  useEffect(() => {
    const mission = missionRef.current;
    if (!mission || mission.status !== "running") return;

    const runId = mission.startedAt;
    animRunRef.current = runId;

    const path = mission.routePath;
    if (path.length < 2) return;

    const durationMs = Math.min(48_000, Math.max(8_000, (mission.distanceM / 20) * 1000));

    let startTime: number | null = null;
    let frameId = 0;
    let cancelled = false;

    const step = (now: number) => {
      if (cancelled || animRunRef.current !== runId) return;
      if (startTime === null) startTime = now;

      const raw = (now - startTime) / durationMs;
      const t = easeInOutCubic(Math.min(1, raw));
      const { lat, lng, bearing } = pointAlongPath(path, t);

      setDigitalTwinMission((prev) => {
        if (!prev || prev.startedAt !== runId || prev.status !== "running") return prev;
        return { ...prev, progress: t, bearing };
      });

      setResponders((prev) =>
        prev.map((item) => {
          if (item.id !== mission.responderId) return item;
          return {
            ...item,
            lat,
            lng,
            availability: t >= 1 ? "Deployed" : "En Route",
            currentStatus:
              t >= 1 ? `Arrived at ${mission.incidentId}` : `En route to ${mission.incidentId}`,
            eta:
              t >= 1 ? "0 min" : `${Math.max(1, Math.ceil((1 - t) * (durationMs / 60_000)))} min`,
          };
        }),
      );

      if (raw < 1) {
        frameId = requestAnimationFrame(step);
      } else {
        setDigitalTwinMission((prev) => {
          if (!prev || prev.startedAt !== runId) return prev;
          return { ...prev, status: "arrived", progress: 1, bearing };
        });
      }
    };

    frameId = requestAnimationFrame(step);
    return () => {
      cancelled = true;
      cancelAnimationFrame(frameId);
    };
  }, [digitalTwinMission?.startedAt]);

  const launchDigitalTwin = async () => {
    if (!selectedResponder || !twinTargetIncident) {
      setErrorMessage("Pick an EMS unit and an active incident first.");
      return;
    }

    setErrorMessage("");

    const startLat = selectedResponder.lat;
    const startLng = selectedResponder.lng;
    const targetLat = twinTargetIncident.latitude;
    const targetLng = twinTargetIncident.longitude;

    const route = previewRoute
      ? { path: previewRoute.path, distanceMeters: previewRoute.distanceM, source: previewRoute.source }
      : await fetchDrivingRoute(startLat, startLng, targetLat, targetLng);
    const p0 = pointAlongPath(route.path, 0);

    const startedAt = new Date().toISOString();
    setDigitalTwinMission({
      responderId: selectedResponder.id,
      incidentId: twinTargetIncident.id,
      responderName: selectedResponder.name,
      incidentType: twinTargetIncident.type,
      startLat,
      startLng,
      targetLat,
      targetLng,
      routePath: route.path,
      distanceM: route.distanceMeters,
      pathSource: route.source,
      progress: 0,
      bearing: p0.bearing,
      status: "running",
      startedAt,
    });

    setDispatchMessage(
      route.source === "road"
        ? `Twin live — ${(route.distanceMeters / 1000).toFixed(1)} km on the driving route. Track the unit on the map.`
        : `Twin running on a straight fallback — road service did not return a path.`,
    );
  };

  const idleMapPosition = selectedResponder
    ? { lat: selectedResponder.lat, lng: selectedResponder.lng }
    : null;

  const progressPct = Math.round((digitalTwinMission?.progress ?? 0) * 100);

  return (
    <OpsShell
      title="EMS · digital twin"
      subtitle="Route ambulances and field units to live incidents from the ResQNet API. Map: pan and zoom; routes use backend driving geometry when available, with a public fallback if needed."
      tag="Global ops live"
    >
      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <StatsCard
          label="On scene"
          value={responders.filter((r) => r.availability === "Deployed").length}
          trend="up"
          delta="Worldwide"
        />
        <StatsCard
          label="Staging / ready"
          value={responders.filter((r) => r.availability === "Ready").length}
          trend="flat"
          delta="Fleet"
        />
        <StatsCard
          label="Rolling code-3"
          value={responders.filter((r) => r.availability === "En Route").length}
          trend="up"
          delta="Lights & sirens"
        />
        <StatsCard
          label="Off net"
          value={responders.filter((r) => r.availability === "Offline").length}
          trend="down"
          delta="Not in service"
        />
      </section>

      {/* Dispatch console */}
      <section className="rounded-2xl border border-white/[0.09] bg-black/30 p-4 shadow-[inset_0_1px_0_rgba(255,255,255,0.06),0_18px_40px_rgba(0,0,0,0.35)] sm:p-5">
        {/* Console header */}
        <div className="mb-4 flex flex-wrap items-start justify-between gap-3 border-b border-white/[0.07] pb-4">
          <div>
            <p className="text-[10px] uppercase tracking-[0.18em] text-white/40">Dispatch Console</p>
            <h2 className="mt-1 text-base font-bold text-white">EMS Dispatch & Digital Twin</h2>
            <p className="mt-0.5 text-xs text-white/45">
              Pick an EMS unit and an open incident. Dispatch runs the digital twin along the previewed route.
            </p>
          </div>
          <Button
            size="sm"
            onClick={() => void launchDigitalTwin()}
            disabled={
              !selectedResponderId ||
              !twinTargetIncidentId ||
              twinRouteLoading ||
              digitalTwinMission?.status === "running"
            }
          >
            <Zap className="mr-1.5 h-3.5 w-3.5" />
            {twinRouteLoading ? "Plotting route…" : digitalTwinMission?.status === "running" ? "Twin running…" : "Dispatch"}
          </Button>
        </div>

        <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(300px,440px)] xl:grid-cols-[minmax(0,1fr)_minmax(340px,500px)] lg:items-start">
          <div className="min-w-0 space-y-4">
            {/* Unit + incident selects */}
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="rounded-xl border border-white/[0.09] bg-black/30 p-3 shadow-[inset_0_1px_0_rgba(255,255,255,0.04)]">
                <p className="text-[10px] uppercase tracking-[0.16em] text-white/45">EMS Unit</p>
                <select
                  value={selectedResponderId}
                  onChange={(event) => setSelectedResponderId(event.target.value)}
                  className="mt-2 w-full rounded-xl border border-white/[0.12] bg-slate-950/80 px-3 py-2 text-sm text-white focus:border-white/25 focus:outline-none"
                >
                  {responders.map((responder) => (
                    <option key={responder.id} value={responder.id}>
                      {responderDisplayName(responder)}
                    </option>
                  ))}
                </select>
                {selectedResponder ? (
                  <p className="mt-1.5 font-mono text-[11px] text-white/35">
                    {selectedResponder.lat.toFixed(5)}, {selectedResponder.lng.toFixed(5)}
                  </p>
                ) : null}
              </div>
              <div className="rounded-xl border border-white/[0.09] bg-black/30 p-3 shadow-[inset_0_1px_0_rgba(255,255,255,0.04)]">
                <p className="text-[10px] uppercase tracking-[0.16em] text-white/45">Target Incident</p>
                <select
                  value={twinTargetIncidentId}
                  onChange={(event) => setTwinTargetIncidentId(event.target.value)}
                  className="mt-2 w-full rounded-xl border border-white/[0.12] bg-slate-950/80 px-3 py-2 text-sm text-white focus:border-white/25 focus:outline-none"
                >
                  {incidents.map((incident) => (
                    <option key={incident.id} value={incident.id}>
                      {incident.type} · …{incident.id.slice(-8)}
                    </option>
                  ))}
                </select>
                {twinTargetIncident ? (
                  <p className="mt-1.5 font-mono text-[11px] text-white/35">
                    {twinTargetIncident.latitude.toFixed(5)}, {twinTargetIncident.longitude.toFixed(5)}
                  </p>
                ) : null}
              </div>
            </div>

            {dispatchMessage ? (
              <p className="text-xs font-medium text-emerald-300/90">{dispatchMessage}</p>
            ) : null}
            {errorMessage ? (
              <p className="text-xs font-medium text-rose-300/90">{errorMessage}</p>
            ) : null}

            {/* Runsheet info box */}
            {digitalTwinMission ? (
              <div className="rounded-xl border border-white/[0.09] bg-black/30 p-3 shadow-[inset_0_1px_0_rgba(255,255,255,0.04)]">
                <p className="text-[10px] uppercase tracking-[0.16em] text-white/45">Runsheet</p>
                <div className="mt-2 grid grid-cols-2 gap-x-4 gap-y-1.5 font-mono text-[11px]">
                  <div>
                    <span className="text-white/30">Network</span>
                    <p className="text-white/70">
                      {digitalTwinMission.pathSource === "road" ? "OSRM driving" : "Straight fallback"}
                    </p>
                  </div>
                  <div>
                    <span className="text-white/30">Distance</span>
                    <p className="text-white/70">{(digitalTwinMission.distanceM / 1000).toFixed(1)} km</p>
                  </div>
                  <div>
                    <span className="text-white/30">Unit</span>
                    <p className="text-white/70">{digitalTwinMission.responderName}</p>
                  </div>
                  <div>
                    <span className="text-white/30">Status</span>
                    <p className="text-white/70">
                      {digitalTwinMission.status === "running" ? "Twin in motion" : "On scene"}
                    </p>
                  </div>
                </div>
              </div>
            ) : null}

            {/* Progress bar */}
            <div className="rounded-xl border border-white/[0.09] bg-black/30 p-3 shadow-[inset_0_1px_0_rgba(255,255,255,0.04)]">
              <div className="mb-2 flex items-center justify-between">
                <p className="text-[10px] uppercase tracking-[0.16em] text-white/45">Route Progress</p>
                <span className="font-mono text-[11px] font-semibold tabular-nums text-white/60">
                  {progressPct}%
                </span>
              </div>
              <div className="relative h-2 overflow-hidden rounded-full bg-white/[0.08]">
                <div
                  className="h-full rounded-full bg-emerald-400 transition-[width] duration-200 ease-out"
                  style={{ width: `${Math.max(2, progressPct)}%` }}
                />
              </div>
              <div className="mt-3 grid gap-y-1.5 gap-x-3 font-mono text-[11px] text-white/45 sm:grid-cols-3">
                <div>
                  <p className="text-[10px] text-white/25">BASE</p>
                  <p>
                    {digitalTwinMission
                      ? `${digitalTwinMission.startLat.toFixed(5)}, ${digitalTwinMission.startLng.toFixed(5)}`
                      : idleMapPosition
                        ? `${idleMapPosition.lat.toFixed(5)}, ${idleMapPosition.lng.toFixed(5)}`
                        : "—"}
                  </p>
                </div>
                <div>
                  <p className="text-[10px] text-white/25">AVL</p>
                  <p>
                    {liveTwin
                      ? `${liveTwin.lat.toFixed(5)}, ${liveTwin.lng.toFixed(5)}`
                      : idleMapPosition
                        ? `${idleMapPosition.lat.toFixed(5)}, ${idleMapPosition.lng.toFixed(5)}`
                        : "—"}
                  </p>
                </div>
                <div>
                  <p className="text-[10px] text-white/25">INCIDENT</p>
                  <p>
                    {twinTargetIncident
                      ? `${twinTargetIncident.latitude.toFixed(5)}, ${twinTargetIncident.longitude.toFixed(5)}`
                      : "—"}
                  </p>
                </div>
              </div>
            </div>

            <Button
              size="sm"
              variant="outline"
              onClick={() => {
                setLoading(true);
                void loadDashboardData();
              }}
              disabled={loading}
            >
              Sync feed
            </Button>
          </div>

          {/* Map panel */}
          <div className="min-w-0 lg:sticky lg:top-4">
            <div className="flex h-[min(72vh,560px)] min-h-[420px] flex-col overflow-hidden rounded-2xl border border-white/[0.09] bg-[#060708] shadow-[inset_0_1px_0_rgba(255,255,255,0.06)]">
              <div className="flex items-center justify-between border-b border-white/[0.07] px-4 py-2.5">
                <div className="flex items-center gap-2">
                  <MapPin className="h-3.5 w-3.5 text-white/30" />
                  <p className="text-[10px] uppercase tracking-[0.16em] text-white/45">Street Map</p>
                </div>
                <p className="text-[11px] text-white/35">
                  {twinRouteLoading ? "Computing route…" : "Pan / zoom freely"}
                </p>
              </div>
              <div className="relative min-h-0 flex-1">
                <ResponderDigitalTwinMap
                  key="responder-twin-map"
                  routePath={digitalTwinMission?.routePath ?? previewRoute?.path ?? null}
                  livePosition={
                    liveTwin ? { lat: liveTwin.lat, lng: liveTwin.lng } : digitalTwinMission ? null : idleMapPosition
                  }
                  targetLat={twinTargetIncident?.latitude ?? selectedResponder?.lat ?? 22.5937}
                  targetLng={twinTargetIncident?.longitude ?? selectedResponder?.lng ?? 78.9629}
                  idlePosition={!digitalTwinMission ? idleMapPosition : null}
                  pathSource={digitalTwinMission?.pathSource ?? previewRoute?.source ?? null}
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Responder cards grid */}
      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {loading ? (
          Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="rounded-2xl border border-white/[0.09] bg-black/30 p-4">
              <Skeleton className="h-5 w-1/2 rounded-md" />
              <Skeleton className="mt-3 h-4 w-2/3 rounded-md" />
              <Skeleton className="mt-2 h-4 w-1/3 rounded-md" />
              <Skeleton className="mt-4 h-9 w-full rounded-xl" />
            </div>
          ))
        ) : null}
        {!loading && responders.length === 0 ? (
          <div className="md:col-span-2 xl:col-span-3 flex flex-col items-center justify-center gap-3 rounded-2xl border border-white/[0.09] bg-black/30 p-12 text-center">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl border border-white/[0.09] bg-white/[0.04]">
              <Activity className="h-5 w-5 text-white/20" />
            </div>
            <div>
              <p className="text-sm font-medium text-white/50">No EMS units on the wire</p>
              <p className="mt-1 text-xs text-white/30">Check the API or your backend feed.</p>
            </div>
          </div>
        ) : null}
        {responders.map((responder) => (
          <ResponderCard
            key={responder.id}
            responder={responder}
            onAssign={(id) =>
              void updateResponder(id, {
                availability: "en_route",
                current_status: "Console dispatch acknowledged",
                eta_minutes: 10,
              })
            }
          />
        ))}
      </section>
    </OpsShell>
  );
}
