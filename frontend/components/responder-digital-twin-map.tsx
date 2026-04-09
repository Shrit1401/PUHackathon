"use client";

import "leaflet/dist/leaflet.css";

import { useEffect, useMemo } from "react";
import { CircleMarker, MapContainer, Marker, Polyline, TileLayer, useMap } from "react-leaflet";
import L from "leaflet";

/** Fixed view — no pan/zoom animation; only the ambulance marker moves along the route. */
const INDIA_CENTER: [number, number] = [22.5937, 78.9629];
const INDIA_ZOOM = 5;

type ResponderDigitalTwinMapProps = {
  routePath: [number, number][] | null;
  livePosition: { lat: number; lng: number } | null;
  targetLat: number;
  targetLng: number;
  idlePosition: { lat: number; lng: number } | null;
  pathSource: "road" | "straight" | null;
};

function MapInvalidateSize() {
  const map = useMap();
  useEffect(() => {
    const el = map.getContainer();
    const bump = () => map.invalidateSize({ animate: false });
    bump();
    const raf = requestAnimationFrame(bump);
    const t1 = window.setTimeout(bump, 0);
    const t2 = window.setTimeout(bump, 100);
    const t3 = window.setTimeout(bump, 350);
    const ro = new ResizeObserver(() => bump());
    ro.observe(el);
    if (el.parentElement) ro.observe(el.parentElement);
    window.addEventListener("resize", bump);
    return () => {
      cancelAnimationFrame(raf);
      window.clearTimeout(t1);
      window.clearTimeout(t2);
      window.clearTimeout(t3);
      ro.disconnect();
      window.removeEventListener("resize", bump);
    };
  }, [map]);
  return null;
}

function makeAmbulanceIcon(): L.DivIcon {
  return L.divIcon({
    className: "twin-ambulance-marker",
    html: `
      <div class="twin-ambulance-inner">
        <svg width="32" height="32" viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
          <circle cx="18" cy="18" r="15" fill="#0f172a" stroke="#34d399" stroke-width="2"/>
          <path d="M10 18h16M18 10v16" stroke="#f87171" stroke-width="2.2" stroke-linecap="round"/>
          <circle cx="18" cy="18" r="3" fill="#34d399"/>
        </svg>
      </div>
    `,
    iconSize: [32, 32],
    iconAnchor: [16, 16],
  });
}

export function ResponderDigitalTwinMap({
  routePath,
  livePosition,
  targetLat,
  targetLng,
  idlePosition,
  pathSource,
}: ResponderDigitalTwinMapProps) {
  const polyPositions = routePath && routePath.length >= 2 ? routePath : null;
  const ambulanceIcon = useMemo(() => makeAmbulanceIcon(), []);

  const markerPosition: [number, number] | null = livePosition
    ? [livePosition.lat, livePosition.lng]
    : idlePosition
      ? [idlePosition.lat, idlePosition.lng]
      : null;

  return (
    <div className="relative h-full w-full overflow-hidden rounded-b-xl bg-[#ececec] [&_.leaflet-container]:!h-full [&_.leaflet-container]:!w-full [&_.leaflet-container]:!bg-[#ececec]">
      <MapContainer
        center={INDIA_CENTER}
        zoom={INDIA_ZOOM}
        minZoom={4}
        maxZoom={14}
        className="block h-full w-full"
        style={{ height: "100%", width: "100%" }}
        zoomControl={false}
        dragging
        scrollWheelZoom
        doubleClickZoom
        touchZoom
        boxZoom
        keyboard
      >
        <MapInvalidateSize />
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/attributions">CARTO</a>'
          url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
          subdomains="abcd"
        />
        {polyPositions ? (
          <Polyline
            positions={polyPositions}
            pathOptions={{
              color: pathSource === "road" ? "#059669" : "#2563eb",
              weight: 4,
              lineCap: "round",
              lineJoin: "round",
              opacity: 0.9,
            }}
          />
        ) : null}
        <CircleMarker
          center={[targetLat, targetLng]}
          radius={7}
          pathOptions={{
            color: "#fca5a5",
            fillColor: "#ef4444",
            fillOpacity: 0.8,
            weight: 2,
          }}
        />
        {markerPosition ? <Marker position={markerPosition} icon={ambulanceIcon} /> : null}
      </MapContainer>
    </div>
  );
}
