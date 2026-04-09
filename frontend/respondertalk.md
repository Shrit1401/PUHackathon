# Responder Dispatch Frontend <-> Backend Contract

This document defines the API flow used by the responder orchestration frontend for "book highest-confidence incident with ETA".

## Goal

- Pick the active incident with highest confidence.
- Request optimized dispatch (best responder + ETA + alternates + hospital).
- Book that responder to the incident.
- Update responder live status to `en_route`.

## Frontend Sequence

1. `GET /events?active_only=true&limit=200`
   - Build incident queue sorted by `confidence DESC`.
2. `POST /dispatch/optimize`
   - Send selected incident coordinates and required unit type.
   - Receive recommended responder and ETA.
3. `POST /incidents/{incident_id}/assign`
   - Assign selected responder to incident.
4. `PATCH /responders/{responder_id}`
   - Mark responder as en route with calculated ETA.

## Request/Response Shapes

### 1) Active incidents

- **Request**: `GET /events?active_only=true&limit=200`
- **Used fields in response item**:
  - `id`
  - `type`
  - `confidence`
  - `severity`
  - `latitude`
  - `longitude`
  - `created_at`

### 2) Optimize dispatch

- **Request**: `POST /dispatch/optimize`

```json
{
  "incident_id": "evt_123",
  "latitude": 28.6139,
  "longitude": 77.209,
  "required_unit": "ambulance"
}
```

- **Response**:

```json
{
  "selected_responder": {
    "id": "resp_01",
    "name": "Unit Alpha",
    "distance_km": 2.8,
    "eta_minutes": 9
  },
  "alternates": [
    { "id": "resp_02", "eta_minutes": 12 },
    { "id": "resp_03", "eta_minutes": 14 }
  ],
  "hospital_recommendation": {
    "name": "City Trauma Center",
    "distance_km": 3.2,
    "capacity_status": "moderate"
  }
}
```

### 3) Assign incident

- **Request**: `POST /incidents/{incident_id}/assign`

```json
{
  "responder_id": "resp_01",
  "assigned_by": "responder-ops-ui",
  "note": "Auto-booked from highest-confidence queue with ETA 9 min"
}
```

- **Response (minimum needed)**:
  - `status`
  - `incident_id`
  - `responder_id`
  - `distance_km`
  - `eta_minutes`

### 4) Update responder status

- **Request**: `PATCH /responders/{responder_id}`

```json
{
  "availability": "en_route",
  "current_status": "Heading to incident evt_123",
  "eta_minutes": 9
}
```

- **Response**:
  - `message`

## Required Backend Behavior

- `dispatch/optimize` must return `selected_responder` or a clear error if no eligible responder exists.
- `incidents/{id}/assign` should be idempotent for repeated assignment attempts (same responder).
- `responders/{id}` update should reflect quickly so dashboard can refresh live state.
- All errors should return meaningful text for operator UI (for example: no responders available, incident not found).

## Frontend Fallback Rules

- If optimizer fails, operator can still assign manually from responder cards.
- If assignment fails, keep recommendation visible and allow retry.
- If status patch fails after assign, show warning but keep incident assigned.
