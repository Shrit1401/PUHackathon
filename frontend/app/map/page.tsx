"use client";

import dynamic from "next/dynamic";
import { useEffect, useState } from "react";
import { OpsShell } from "@/components/ops-shell";
import { Skeleton } from "@/components/ui/skeleton";
import { IncidentRecord } from "@/lib/ops-types";
import { subscribeToAssignments, subscribeToIncidents } from "@/lib/realtime";
import { fetchEvents, fetchAllEonetEvents, type EonetEvent } from "@/lib/api";

const MapView = dynamic(
  () => import("@/components/map-view").then((m) => m.MapView),
  { ssr: false, loading: () => <Skeleton className="h-[calc(100vh-170px)] w-full rounded-2xl" /> },
);

function eonetToIncidents(events: EonetEvent[]): IncidentRecord[] {
  const out: IncidentRecord[] = [];
  for (const ev of events) {
    const geom = ev.geometry.at(-1);
    if (!geom || geom.type !== "Point") continue;
    const [lng, lat] = geom.coordinates as number[];
    if (typeof lat !== "number" || typeof lng !== "number") continue;
    if (!isFinite(lat) || !isFinite(lng)) continue;

    const category = ev.categories[0]?.title ?? "Natural Event";
    const critical = ["Volcanoes", "Wildfires", "Severe Storms", "Earthquakes"];
    const high = ["Floods", "Landslides", "Snow", "Drought"];
    const priority = critical.some((c) => category.includes(c))
      ? "Critical"
      : high.some((c) => category.includes(c))
        ? "High"
        : "Medium";

    out.push({
      id: ev.id,
      user: "NASA EONET",
      incidentType: category,
      status: ev.closed ? "Resolved" : "Assigned",
      location: `${lat.toFixed(3)}, ${lng.toFixed(3)}`,
      createdAt: geom.date ? new Date(geom.date).toLocaleDateString() : "",
      priority,
      confidence: 85,
      lat,
      lng,
      summary: ev.title,
      source: "eonet" as const,
      eonetLink: ev.link,
    });
  }
  return out;
}

export default function MapPage() {
  const [incidents, setIncidents] = useState<IncidentRecord[]>([]);
  const [eonetIncidents, setEonetIncidents] = useState<IncidentRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [eonetLoading, setEonetLoading] = useState(true);
  const [heartbeat, setHeartbeat] = useState(0);

  // Backend events load first
  useEffect(() => {
    fetchEvents()
      .then((events) => {
        setIncidents(events.map((event) => ({
          id: event.id,
          user: "System",
          incidentType: event.type,
          status: event.active ? "Assigned" : "Resolved",
          location: `${event.latitude.toFixed(3)}, ${event.longitude.toFixed(3)}`,
          createdAt: "Live",
          priority: event.severity === "high" ? "Critical" : event.severity === "medium" ? "High" : "Medium",
          confidence: Math.round(event.confidence),
          lat: event.latitude,
          lng: event.longitude,
          summary: `${event.type} — backend event feed.`,
          source: "backend" as const,
        })));
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  // EONET loads separately (can be slow — up to 2000 events)
  useEffect(() => {
    fetchAllEonetEvents()
      .then((events) => setEonetIncidents(eonetToIncidents(events)))
      .catch(console.error)
      .finally(() => setEonetLoading(false));
  }, []);

  useEffect(() => {
    const unsub1 = subscribeToIncidents(() => setHeartbeat((v) => v + 1));
    const unsub2 = subscribeToAssignments(() => setHeartbeat((v) => v + 1));
    return () => { unsub1(); unsub2(); };
  }, []);

  const totalEvents = incidents.length + eonetIncidents.length;

  return (
    <OpsShell
      title="Real-Time Operational Map"
      subtitle={
        eonetLoading
          ? "Loading global disaster data from NASA EONET…"
          : `${totalEvents.toLocaleString()} events worldwide — NASA EONET + backend feed`
      }
      tag={`Live sync ${heartbeat > 0 ? "active" : "connecting"}`}
    >
      {loading ? (
        <Skeleton className="h-[calc(100vh-170px)] w-full rounded-2xl" />
      ) : (
        <MapView
          incidents={incidents}
          eonetIncidents={eonetIncidents}
          eonetLoading={eonetLoading}
          responders={[]}
        />
      )}
    </OpsShell>
  );
}
