"use client";

import "leaflet/dist/leaflet.css";

import { useMemo, useState } from "react";
import L from "leaflet";
import { CircleMarker, MapContainer, Marker, Popup, TileLayer } from "react-leaflet";
import { IncidentRecord, ResponderRecord } from "@/lib/ops-types";
import { StatusPill } from "./status-pill";

type MapViewProps = {
  incidents: IncidentRecord[];
  eonetIncidents?: IncidentRecord[];
  eonetLoading?: boolean;
  responders: ResponderRecord[];
};

/* ── Icon helpers ─────────────────────────────────────────────────────────── */

function makeBackendIcon() {
  return L.divIcon({
    className: "",
    html: `<div style="width:10px;height:10px;border-radius:999px;background:#ef4444;box-shadow:0 0 14px rgba(239,68,68,0.8);"></div>`,
    iconSize: [10, 10],
    iconAnchor: [5, 5],
  });
}

function makeResponderIcon() {
  return L.divIcon({
    className: "",
    html: `<div style="width:10px;height:10px;border-radius:999px;background:#38bdf8;box-shadow:0 0 14px rgba(56,189,248,0.8);"></div>`,
    iconSize: [10, 10],
    iconAnchor: [5, 5],
  });
}

// EONET category → color
const EONET_COLORS: Record<string, string> = {
  Wildfires: "#f97316",
  Volcanoes: "#dc2626",
  "Severe Storms": "#a855f7",
  Floods: "#3b82f6",
  Earthquakes: "#eab308",
  Landslides: "#78716c",
  Snow: "#93c5fd",
  "Sea and Lake Ice": "#67e8f9",
  Drought: "#d97706",
  "Dust and Haze": "#d4d4d8",
  "Temperature Extremes": "#fb923c",
};

const EONET_GLOWS: Record<string, string> = {
  Wildfires: "rgba(249,115,22,0.85)",
  Volcanoes: "rgba(220,38,38,0.85)",
  "Severe Storms": "rgba(168,85,247,0.85)",
  Floods: "rgba(59,130,246,0.85)",
  Earthquakes: "rgba(234,179,8,0.85)",
  Landslides: "rgba(120,113,108,0.85)",
  Snow: "rgba(147,197,253,0.85)",
  "Sea and Lake Ice": "rgba(103,232,249,0.85)",
  Drought: "rgba(217,119,6,0.85)",
  "Dust and Haze": "rgba(212,212,216,0.75)",
  "Temperature Extremes": "rgba(251,146,60,0.85)",
};

function makeEonetIcon(category: string) {
  const color = EONET_COLORS[category] ?? "#22d3ee";
  const glow = EONET_GLOWS[category] ?? "rgba(34,211,238,0.75)";
  return L.divIcon({
    className: "",
    html: `<div style="width:9px;height:9px;border-radius:999px;background:${color};box-shadow:0 0 12px ${glow};border:1.5px solid rgba(255,255,255,0.25);"></div>`,
    iconSize: [9, 9],
    iconAnchor: [4.5, 4.5],
  });
}

/* ── Category emoji for popup ─────────────────────────────────────────────── */
const CATEGORY_EMOJI: Record<string, string> = {
  Wildfires: "🔥",
  Volcanoes: "🌋",
  "Severe Storms": "⛈️",
  Floods: "🌊",
  Earthquakes: "📳",
  Landslides: "⛰️",
  Snow: "❄️",
  Drought: "☀️",
  "Sea and Lake Ice": "🧊",
  "Dust and Haze": "💨",
  "Temperature Extremes": "🌡️",
};

/* ── Legend categories ────────────────────────────────────────────────────── */
const LEGEND_ITEMS = [
  { label: "Wildfire", color: EONET_COLORS.Wildfires },
  { label: "Volcano", color: EONET_COLORS.Volcanoes },
  { label: "Storm", color: EONET_COLORS["Severe Storms"] },
  { label: "Flood", color: EONET_COLORS.Floods },
  { label: "Earthquake", color: EONET_COLORS.Earthquakes },
  { label: "Other", color: "#22d3ee" },
  { label: "Backend", color: "#ef4444" },
];

/* ── Component ────────────────────────────────────────────────────────────── */

export function MapView({ incidents, eonetIncidents = [], eonetLoading = false, responders }: MapViewProps) {
  const [selectedId, setSelectedId] = useState<string>(
    eonetIncidents[0]?.id ?? incidents[0]?.id ?? "",
  );
  const [showEonet, setShowEonet] = useState(true);
  const [showBackend, setShowBackend] = useState(true);
  const [showEscalatedOverlay, setShowEscalatedOverlay] = useState(true);
  const [filterCategory, setFilterCategory] = useState<string>("All");

  const backendIcon = useMemo(() => makeBackendIcon(), []);
  const responderIcon = useMemo(() => makeResponderIcon(), []);

  // Unique EONET categories present
  const eonetCategories = useMemo(() => {
    const cats = new Set(eonetIncidents.map((e) => e.incidentType));
    return ["All", ...Array.from(cats).sort()];
  }, [eonetIncidents]);

  const visibleEonet = useMemo(() => {
    if (!showEonet) return [];
    if (filterCategory === "All") return eonetIncidents;
    return eonetIncidents.filter((e) => e.incidentType === filterCategory);
  }, [eonetIncidents, showEonet, filterCategory]);

  const visibleBackend = useMemo(
    () => (showBackend ? incidents : []),
    [incidents, showBackend],
  );

  // Stable icon map keyed by category
  const eonetIconMap = useMemo(() => {
    const map: Record<string, L.DivIcon> = {};
    for (const inc of eonetIncidents) {
      if (!map[inc.incidentType]) {
        map[inc.incidentType] = makeEonetIcon(inc.incidentType);
      }
    }
    return map;
  }, [eonetIncidents]);

  const allVisible = [...visibleEonet, ...visibleBackend];
  const selected = allVisible.find((i) => i.id === selectedId) ?? allVisible[0];

  // World view when EONET data present
  const center: [number, number] = [20, 0];
  const zoom = 2;

  return (
    <div className="relative h-[calc(100vh-170px)] overflow-hidden rounded-2xl border border-white/10 bg-black/30">
      <MapContainer
        center={center}
        zoom={zoom}
        minZoom={2}
        maxBounds={[[-90, -200], [90, 200]]}
        maxBoundsViscosity={0.8}
        worldCopyJump={true}
        className="h-full w-full"
        zoomControl={false}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        />

        {/* EONET events */}
        {visibleEonet.map((inc) => (
          <Marker
            key={inc.id}
            position={[inc.lat, inc.lng]}
            icon={eonetIconMap[inc.incidentType] ?? makeEonetIcon(inc.incidentType)}
            eventHandlers={{ click: () => setSelectedId(inc.id) }}
          >
            <Popup>
              <div style={{ minWidth: 180 }}>
                <p style={{ fontWeight: 700, fontSize: 13, marginBottom: 2 }}>
                  {CATEGORY_EMOJI[inc.incidentType] ?? "🌍"} {inc.incidentType}
                </p>
                <p style={{ fontSize: 11, color: "#94a3b8", marginBottom: 4 }}>{inc.summary}</p>
                <p style={{ fontSize: 10, color: "#64748b" }}>{inc.location}</p>
                <p style={{ fontSize: 10, color: "#64748b" }}>{inc.createdAt}</p>
                {inc.eonetLink && (
                  <a href={inc.eonetLink} target="_blank" rel="noreferrer"
                    style={{ fontSize: 10, color: "#38bdf8", display: "block", marginTop: 4 }}>
                    NASA EONET →
                  </a>
                )}
              </div>
            </Popup>
          </Marker>
        ))}

        {/* Backend incidents */}
        {visibleBackend.map((incident) => (
          <>
            <CircleMarker
              key={`${incident.id}-ring`}
              center={[incident.lat, incident.lng]}
              radius={incident.status === "Escalated" ? 16 : 11}
              pathOptions={{
                color: "rgba(239,68,68,0.95)",
                fillColor: "rgba(239,68,68,0.45)",
                fillOpacity: incident.id === selected?.id ? 0.6 : 0.3,
                weight: 1.8,
              }}
              eventHandlers={{ click: () => setSelectedId(incident.id) }}
            />
            <Marker
              key={`${incident.id}-dot`}
              position={[incident.lat, incident.lng]}
              icon={backendIcon}
              eventHandlers={{ click: () => setSelectedId(incident.id) }}
            >
              <Popup>
                <p style={{ fontWeight: 600 }}>{incident.incidentType}</p>
                <p>{incident.location}</p>
                <p>Priority: {incident.priority}</p>
              </Popup>
            </Marker>
          </>
        ))}

        {/* Responders */}
        {responders.map((responder) => (
          <Marker key={responder.id} position={[responder.lat, responder.lng]} icon={responderIcon}>
            <Popup>
              <p style={{ fontWeight: 600 }}>{responder.name}</p>
              <p>{responder.specialization}</p>
              <p>ETA: {responder.eta}</p>
            </Popup>
          </Marker>
        ))}
      </MapContainer>

      {/* Glow overlay */}
      {showEscalatedOverlay && (
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_40%_30%,rgba(239,68,68,0.14),transparent_48%),radial-gradient(circle_at_70%_65%,rgba(56,189,248,0.10),transparent_50%)]" />
      )}

      {/* Controls */}
      <div className="absolute left-4 top-4 z-[500] flex flex-col gap-2 rounded-xl border border-white/[0.1] bg-[#0b1019]/90 p-3 backdrop-blur-md">
        <div className="flex items-center justify-between gap-2">
          <p className="text-[9px] font-semibold uppercase tracking-[0.18em] text-white/35">Layers</p>
          {eonetLoading && (
            <span className="flex items-center gap-1 rounded-full bg-cyan-400/10 px-2 py-0.5 text-[9px] text-cyan-400/70">
              <span className="inline-block h-1.5 w-1.5 animate-pulse rounded-full bg-cyan-400/60" />
              Loading…
            </span>
          )}
        </div>

        <div className="flex flex-col gap-1.5">
          <label className="flex cursor-pointer items-center gap-2">
            <input
              type="checkbox"
              checked={showEonet}
              onChange={(e) => setShowEonet(e.target.checked)}
              className="h-3 w-3 accent-cyan-400"
            />
            <span className="text-[11px] text-white/70">NASA EONET</span>
            <span className="rounded-full bg-white/[0.07] px-1.5 py-0.5 font-mono text-[9px] text-white/40">
              {eonetIncidents.length}
            </span>
          </label>

          <label className="flex cursor-pointer items-center gap-2">
            <input
              type="checkbox"
              checked={showBackend}
              onChange={(e) => setShowBackend(e.target.checked)}
              className="h-3 w-3 accent-red-400"
            />
            <span className="text-[11px] text-white/70">Backend events</span>
            <span className="rounded-full bg-white/[0.07] px-1.5 py-0.5 font-mono text-[9px] text-white/40">
              {incidents.length}
            </span>
          </label>
        </div>

        <div className="mt-1 border-t border-white/[0.06] pt-2">
          <p className="mb-1.5 text-[9px] font-semibold uppercase tracking-[0.18em] text-white/35">Category</p>
          <select
            value={filterCategory}
            onChange={(e) => setFilterCategory(e.target.value)}
            className="w-full rounded-md border border-white/[0.1] bg-white/[0.04] px-2 py-1 text-[11px] text-white/70 focus:outline-none"
          >
            {eonetCategories.map((cat) => (
              <option key={cat} value={cat} className="bg-slate-900">
                {cat}
              </option>
            ))}
          </select>
        </div>

        <button
          type="button"
          className="mt-1 rounded-md border border-white/[0.1] bg-white/[0.04] px-2 py-1 text-left text-[11px] text-white/60 transition-colors hover:bg-white/[0.07]"
          onClick={() => setShowEscalatedOverlay((v) => !v)}
        >
          {showEscalatedOverlay ? "Hide" : "Show"} overlay
        </button>
      </div>

      {/* Legend */}
      <div className="absolute right-4 top-4 z-[500] rounded-xl border border-white/[0.1] bg-[#0b1019]/90 p-3 backdrop-blur-md">
        <p className="mb-2 text-[9px] font-semibold uppercase tracking-[0.18em] text-white/35">Legend</p>
        <div className="flex flex-col gap-1.5">
          {LEGEND_ITEMS.map((item) => (
            <div key={item.label} className="flex items-center gap-2">
              <span
                className="h-2 w-2 shrink-0 rounded-full"
                style={{ backgroundColor: item.color, boxShadow: `0 0 6px ${item.color}` }}
              />
              <span className="text-[11px] text-white/60">{item.label}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Selected detail card */}
      {selected && (
        <div className="absolute bottom-4 left-4 z-[500] max-w-xs rounded-xl border border-white/[0.12] bg-[#0b1019]/92 p-3.5 backdrop-blur-md">
          <div className="flex items-start justify-between gap-2">
            <div className="min-w-0">
              <p className="text-[9px] font-semibold uppercase tracking-[0.16em] text-white/35">
                {selected.source === "eonet" ? "NASA EONET" : "Backend event"}
              </p>
              <h3 className="mt-0.5 truncate text-sm font-bold text-white">
                {CATEGORY_EMOJI[selected.incidentType] ?? "🌍"} {selected.incidentType}
              </h3>
              <p className="mt-0.5 text-xs text-white/55">{selected.summary}</p>
            </div>
          </div>
          <div className="mt-2.5 flex flex-wrap items-center gap-x-3 gap-y-1 border-t border-white/[0.06] pt-2.5">
            <StatusPill status={selected.status} />
            <span className="font-mono text-[10px] text-white/45">{selected.location}</span>
            {selected.source === "eonet" && selected.eonetLink && (
              <a
                href={selected.eonetLink}
                target="_blank"
                rel="noreferrer"
                className="text-[10px] text-cyan-400/80 hover:text-cyan-300"
              >
                NASA ↗
              </a>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
