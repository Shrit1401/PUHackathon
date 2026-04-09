# Responder digital twin — backend integration & India-wide fleet

This doc is for **backend + data** work so the **Responders** UI (`/responders`) stays connected to real services and can show **units across India** (not one metro only).

---

## 1. What the UI does today (frontend)


| Piece                                 | Source                                                     | Notes                                                                                                                                            |
| ------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Unit list + map marker start position | `GET /responders`                                          | Mapped in `app/responders/page.tsx`                                                                                                              |
| Incident list + target coords         | `GET /events?active_only=true&limit=200`                   | Uses `latitude` / `longitude` on each event                                                                                                      |
| Route polyline (preview + twin)       | **Public OSRM** in `lib/twin-route.ts`                     | Browser calls `router.project-osrm.org`; no backend today                                                                                        |
| Twin animation                        | **Client-side**                                            | Interpolates along polyline; updates local React state (and `PATCH /responders/:id` only from **ResponderCard** “assign”, not from the twin run) |
| Live refresh                          | `GET /responders` + `GET /events` on `responders_live` SSE | `lib/realtime.ts` → `/api/backend/realtime/responders_live`                                                                                      |


**Gap:** Starting **Dispatch** on the twin does **not** persist route or live position to the backend. To make the twin “real,” the backend should accept assignments and optional location ticks.

---

## 2. Backend endpoints the UI already calls

Implement or keep these stable (see `BACKEND_API_REFERENCE.md` §9):

- `**GET /responders`** — query: `availability`, `type`, `limit`  
  - Each item **must** include: `id`, `name`, `type`, `latitude`, `longitude`, `availability`, `current_status`, `eta_minutes`, `updated_at`.
- `**GET /events`** — query: `active_only`, `limit`, `severity`  
  - Each event **must** include: `id`, `type`, `latitude`, `longitude`, `confidence`, `severity`, `active`, `created_at`.
- `**PATCH /responders/{id}`** — used by cards: `availability`, `current_status`, `eta_minutes`.
- **SSE:** `**GET /realtime/responders_live`** — emit on unit or assignment changes so the page refetches.

Optional today but useful for dispatch:

- `**POST /responders/{id}/location**` — `latitude`, `longitude`, `speed_kmph?` — for AVL / twin sync.

---

## 3. Recommended backend changes (twin + dispatch)

### 3.1 Persist “twin run” or real dispatch (pick one model)

**Option A — Lightweight (mirror UI state)**  

- On dispatch from console: `PATCH /responders/{id}` with `availability: en_route`, `current_status`, `eta_minutes` **and** link to target `event_id` (new field or separate table).  
- Optionally: `POST /responders/{id}/location` on a timer from **mobile/AVL** only (not from the browser twin).

**Option B — Full digital twin on server**  

- `POST /dispatch/twin` or `POST /incidents/{event_id}/assign` with `responder_id`.  
- Server stores route geometry (or recomputes with OSRM/GraphHopper), streams progress via SSE/WebSocket, and writes `POST /responders/{id}/location` from a **server job** (optional).

**Option C — Incident-native**  

- Reuse `**POST /incidents/{incident_id}/assign`** (already in API reference) when dispatch is “real”; twin UI only visualises until assign succeeds.

### 3.2 Route / OSRM

- **Today:** Frontend calls OSRM directly → may fail (CORS, rate limits, privacy).  
- **Backend:** Add `GET` or `POST /routing/driving` that proxies OSRM/GraphHopper and returns GeoJSON or `[[lat,lng],…]`. Frontend then replaces `fetchDrivingRoute` in `lib/twin-route.ts` to hit `**/api/backend/...`** instead of the public OSRM host.

### 3.3 Events list must carry coordinates

Twin **requires** `latitude` and `longitude` on `/events` items. If some events lack coords, either:

- filter them out server-side for this use case, or  
- enrich from linked reports.

### 3.4 Pagination / national fleet

- UI requests `**limit=200`**. For **all-India** coverage you likely need:
  - `**limit` increase** (e.g. 500–2000) with indexed DB queries, **or**
  - `**GET /responders?bbox=minLat,minLng,maxLat,maxLng`** when the map viewport changes (future UI), **or**
  - **cursor pagination** (`cursor`, `page_size`) and UI loads next pages.

Document max supported `limit` in OpenAPI so the frontend can page.

---

## 4. Responders “all over India” (data & API)

### 4.1 Geographic spread

India rough bounding box (decimal degrees):

- Latitude **~6.5–37.1**  
- Longitude **~68.2–97.4**

Seed or ingest units across **states / tiers**: e.g. north plains, western coast, central, NE, south — so maps and twins are not all in one cluster.

### 4.2 Seeding (example strategy)

- **Script** (admin): loop `POST /responders` with varied `(latitude, longitude)` inside the bbox, realistic `name` (e.g. `Unit Alpha - <city>`), `type: ambulance`, `availability: ready`.  
- **Bulk endpoint (optional):** `POST /responders/bulk` with array of rows — faster for large seeds.  
- **Idempotency:** use stable external IDs or upsert by `name`+`region` if re-running seeds.

### 4.3 Query performance

- Add **spatial index** on `(latitude, longitude)` (or PostGIS `geography`).  
- If using **bbox** or **nearby** filters, index accordingly.  
- Avoid returning **full national list** on every request without pagination once counts grow.

### 4.4 Optional metadata (future UI)

Fields the backend *could* add (non-breaking for current UI if optional):

- `region` / `state_code` / `district`  
- `base_station_name`  
- `callsign`

Frontend can then filter “India-wide” without changing core twin logic.

---

## 5. Frontend tweaks (after backend is ready)

When routing moves server-side:

1. `**lib/twin-route.ts`** — `fetchDrivingRoute` should call your backend proxy (same-origin via `/api/backend/...`).
2. `**limit**` — increase or implement infinite scroll / bbox if backend supports it.
3. **Dispatch button** — after successful `PATCH` or `POST .../assign`, keep twin animation or replace with positions from `**/responders/{id}`** poll/SSE.

---

## 6. Checklist for backend devs

- `GET /responders` returns **valid lat/lng** for every active row used in ops.  
- `GET /events?active_only=true` returns **lat/lng** for targets.  
- `limit` policy documented; pagination or bbox if fleet > 200.  
- `responders_live` fires when unit status or location changes.  
- (Recommended) Proxy **driving routes** on backend; point frontend to it.  
- (Recommended) On dispatch: persist assignment + optional `event_id` link.  
- Seed **distributed** responders across India for demos/load tests.  
- Spatial indexes and load test `GET /responders` at national scale.

---

## 7. Related files in this repo


| File                                        | Role                                                                           |
| ------------------------------------------- | ------------------------------------------------------------------------------ |
| `app/responders/page.tsx`                   | Twin UI, data load, animation                                                  |
| `lib/api.ts`                                | `fetchResponders`, `fetchEvents`, `updateResponder`, `updateResponderLocation` |
| `lib/twin-route.ts`                         | OSRM client + polyline math                                                    |
| `lib/realtime.ts`                           | SSE `responders_live`                                                          |
| `components/responder-digital-twin-map.tsx` | Leaflet map                                                                    |
| `app/api/backend/[...path]/route.ts`        | Next proxy to real API                                                         |


---

## 8. Open questions for product

- Should **twin animation** be **purely visual** or **drive** `POST /responders/{id}/location` (simulated telemetry)?  
- Should dispatch create an `**/incidents/.../assign`** record automatically?  
- Do we need **auth** on `/responders` and `/events` before production?

Document answers here as decisions are made.