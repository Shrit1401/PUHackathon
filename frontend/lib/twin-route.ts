import { getApiBaseUrl } from "./api";

/** Driving route for digital twin — prefers ResQNet `GET /routing/driving`, then OSRM, then straight line. */

export type RouteResult = {
  path: [number, number][];
  distanceMeters: number;
  source: "road" | "straight";
};

const OSRM_BASE = "https://router.project-osrm.org/route/v1/driving";

function haversineMeters(a: [number, number], b: [number, number]): number {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const [lat1, lng1] = a;
  const [lat2, lng2] = b;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const x =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(x)));
}

/** Great-circle distance in kilometres (for nearest-unit selection, etc.). */
export function distanceKmBetweenLatLng(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  return haversineMeters([lat1, lng1], [lat2, lng2]) / 1000;
}

/** Total path length in meters (sum of segment lengths). */
export function pathLengthMeters(path: [number, number][]): number {
  if (path.length < 2) return 0;
  let sum = 0;
  for (let i = 1; i < path.length; i++) {
    sum += haversineMeters(path[i - 1], path[i]);
  }
  return sum;
}

/** Position at normalized distance t in [0, 1] along the polyline. */
export function pointAlongPath(path: [number, number][], t: number): { lat: number; lng: number; bearing: number } {
  if (path.length === 0) return { lat: 0, lng: 0, bearing: 0 };
  if (path.length === 1) return { lat: path[0][0], lng: path[0][1], bearing: 0 };
  const clamped = Math.max(0, Math.min(1, t));
  const total = pathLengthMeters(path);
  if (total < 1) {
    return { lat: path[path.length - 1][0], lng: path[path.length - 1][1], bearing: 0 };
  }
  const target = clamped * total;
  let acc = 0;
  for (let i = 1; i < path.length; i++) {
    const a = path[i - 1];
    const b = path[i];
    const seg = haversineMeters(a, b);
    if (acc + seg >= target || i === path.length - 1) {
      const local = seg > 0 ? (target - acc) / seg : 0;
      const lat = a[0] + (b[0] - a[0]) * local;
      const lng = a[1] + (b[1] - a[1]) * local;
      const bearing = bearingDeg(a[0], a[1], b[0], b[1]);
      return { lat, lng, bearing };
    }
    acc += seg;
  }
  const last = path[path.length - 1];
  const prev = path[path.length - 2];
  return {
    lat: last[0],
    lng: last[1],
    bearing: bearingDeg(prev[0], prev[1], last[0], last[1]),
  };
}

function bearingDeg(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const y = Math.sin(toRad(lng2 - lng1)) * Math.cos(toRad(lat2));
  const x =
    Math.cos(toRad(lat1)) * Math.sin(toRad(lat2)) -
    Math.sin(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.cos(toRad(lng2 - lng1));
  return (Math.atan2(y, x) * 180) / Math.PI;
}

export function easeInOutCubic(t: number): number {
  return t < 0.5 ? 4 * t * t * t : 1 - (-2 * t + 2) ** 3 / 2;
}

export function straightLinePath(
  startLat: number,
  startLng: number,
  endLat: number,
  endLng: number,
  segments = 24,
): [number, number][] {
  const path: [number, number][] = [];
  for (let i = 0; i <= segments; i++) {
    const u = i / segments;
    path.push([startLat + (endLat - startLat) * u, startLng + (endLng - startLng) * u]);
  }
  return path;
}

function toFiniteNumber(value: unknown): number | null {
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

/** Parse ResQNet `/routing/driving` (or OSRM-shaped) JSON into lat/lng path. */
function parseBackendDrivingJson(data: unknown): { path: [number, number][]; distanceMeters: number } | null {
  if (!data || typeof data !== "object") return null;
  const o = data as Record<string, unknown>;

  const distanceFrom = (src: Record<string, unknown>): number => {
    const d =
      toFiniteNumber(src.distance) ??
      toFiniteNumber(src.distance_meters) ??
      toFiniteNumber(src.distanceMeters);
    return d ?? 0;
  };

  const routes = o.routes as unknown[] | undefined;
  if (Array.isArray(routes) && routes[0] && typeof routes[0] === "object") {
    const r0 = routes[0] as Record<string, unknown>;
    const geom = r0.geometry as { type?: string; coordinates?: [number, number][] } | undefined;
    const coords = geom?.coordinates;
    if (geom?.type === "LineString" && Array.isArray(coords) && coords.length >= 2) {
      const path: [number, number][] = coords.map(([lng, lat]) => [lat, lng]);
      const dm = distanceFrom(r0) || pathLengthMeters(path);
      return { path, distanceMeters: dm };
    }
  }

  const geometry = o.geometry as { type?: string; coordinates?: [number, number][] } | undefined;
  if (geometry?.type === "LineString" && Array.isArray(geometry.coordinates) && geometry.coordinates.length >= 2) {
    const path: [number, number][] = geometry.coordinates.map(([lng, lat]) => [lat, lng]);
    const dm = distanceFrom(o) || pathLengthMeters(path);
    return { path, distanceMeters: dm };
  }

  const pathRaw = o.path ?? o.route_path ?? o.coordinates;
  if (Array.isArray(pathRaw) && pathRaw.length >= 2) {
    const path: [number, number][] = [];
    for (const pt of pathRaw) {
      if (!Array.isArray(pt) || pt.length < 2) continue;
      const a = toFiniteNumber(pt[0]);
      const b = toFiniteNumber(pt[1]);
      if (a == null || b == null) continue;
      path.push([a, b]);
    }
    if (path.length >= 2) {
      const dm = distanceFrom(o) || pathLengthMeters(path);
      return { path, distanceMeters: dm };
    }
  }

  return null;
}

function drivingQueryVariants(
  startLat: number,
  startLng: number,
  endLat: number,
  endLng: number,
): URLSearchParams[] {
  const pairs: Record<string, string>[] = [
    {
      start_lat: String(startLat),
      start_lng: String(startLng),
      end_lat: String(endLat),
      end_lng: String(endLng),
    },
    {
      from_lat: String(startLat),
      from_lng: String(startLng),
      to_lat: String(endLat),
      to_lng: String(endLng),
    },
    {
      origin_lat: String(startLat),
      origin_lng: String(startLng),
      dest_lat: String(endLat),
      dest_lng: String(endLng),
    },
    {
      lat1: String(startLat),
      lon1: String(startLng),
      lat2: String(endLat),
      lon2: String(endLng),
    },
  ];
  return pairs.map((p) => new URLSearchParams(p));
}

async function fetchDrivingRouteFromBackend(
  startLat: number,
  startLng: number,
  endLat: number,
  endLng: number,
): Promise<RouteResult | null> {
  if (
    !Number.isFinite(startLat) ||
    !Number.isFinite(startLng) ||
    !Number.isFinite(endLat) ||
    !Number.isFinite(endLng)
  ) {
    return null;
  }
  if (haversineMeters([startLat, startLng], [endLat, endLng]) < 3) {
    return null;
  }

  const base = `${getApiBaseUrl()}/routing/driving`;
  const jsonBody = JSON.stringify({
    start_lat: startLat,
    start_lng: startLng,
    end_lat: endLat,
    end_lng: endLng,
  });

  const tryParse = async (res: Response): Promise<RouteResult | null> => {
    if (!res.ok) return null;
    const data: unknown = await res.json();
    const parsed = parseBackendDrivingJson(data);
    if (!parsed || parsed.path.length < 2) return null;
    return {
      path: parsed.path,
      distanceMeters: parsed.distanceMeters > 0 ? parsed.distanceMeters : pathLengthMeters(parsed.path),
      source: "road",
    };
  };

  try {
    const variants = drivingQueryVariants(startLat, startLng, endLat, endLng);
    const primary = await fetch(`${base}?${variants[0].toString()}`);
    const primaryOut = await tryParse(primary);
    if (primaryOut) return primaryOut;

    const postRes = await fetch(base, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: jsonBody,
    });
    const postOut = await tryParse(postRes);
    if (postOut) return postOut;

    for (let i = 1; i < variants.length; i++) {
      const res = await fetch(`${base}?${variants[i].toString()}`);
      const out = await tryParse(res);
      if (out) return out;
    }
    return null;
  } catch {
    return null;
  }
}

/**
 * Driving route: backend `/routing/driving` when available, else public OSRM, else straight line.
 */
export async function fetchDrivingRoute(
  startLat: number,
  startLng: number,
  endLat: number,
  endLng: number,
): Promise<RouteResult> {
  const fromBackend = await fetchDrivingRouteFromBackend(startLat, startLng, endLat, endLng);
  if (fromBackend) return fromBackend;

  const url = `${OSRM_BASE}/${startLng},${startLat};${endLng},${endLat}?overview=full&geometries=geojson`;
  try {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`OSRM ${res.status}`);
    const data = (await res.json()) as {
      routes?: Array<{ distance: number; geometry: { coordinates: [number, number][] } }>;
    };
    const route = data.routes?.[0];
    const coords = route?.geometry?.coordinates;
    if (!route || !coords?.length) throw new Error("no geometry");

    const path: [number, number][] = coords.map(([lng, lat]) => [lat, lng]);
    const distanceMeters = route.distance ?? pathLengthMeters(path);
    return { path, distanceMeters, source: "road" };
  } catch {
    const path = straightLinePath(startLat, startLng, endLat, endLng);
    return {
      path,
      distanceMeters: pathLengthMeters(path),
      source: "straight",
    };
  }
}
