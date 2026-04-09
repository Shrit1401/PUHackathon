# ResQNet+ Backend API Reference

Base URL (staging/demo): `https://8301-182-71-109-122.ngrok-free.app`

This document is structured for admin panel and mobile integrations. Response shapes are written to be deterministic for parsing and UI rendering.

## Integration Basics

- JSON endpoints require `Content-Type: application/json`.
- WhatsApp webhook endpoint (`/webhook/whatsapp`) expects `application/x-www-form-urlencoded` and returns TwiML XML.
- Auth tokens are returned by `/auth/login` and `/auth/phone/verify-otp`.
- Current backend behavior: routes are not enforcing auth middleware yet, so clients can call listed routes directly.

---

## 1) Authentication

### `POST /auth/signup`

Request:

```json
{
  "email": "string",
  "password": "string",
  "name": "string",
  "role": "citizen|authority",
  "phone": "+91...",
  "blood_group": "O+",
  "allergies": "text",
  "emergency_contact": "+91..."
}
```

Response:

```json
{
  "message": "Signup successful",
  "user_id": "uuid",
  "role": "string",
  "access_token": "jwt"
}
```

### `POST /auth/login`

Request:

```json
{
  "email": "string",
  "password": "string"
}
```

Response:

```json
{
  "access_token": "jwt",
  "user_id": "uuid",
  "email": "string",
  "role": "string",
  "profile": {
    "id": "...",
    "name": "...",
    "phone": "...",
    "blood_group": "...",
    "allergies": "...",
    "emergency_contact": "...",
    "role": "..."
  }
}
```

### `POST /auth/logout`

Response:

```json
{ "message": "Logged out" }
```

### `POST /auth/phone/send-otp`

Request:

```json
{ "phone": "+91..." }
```

Response:

```json
{ "message": "OTP sent to +91..." }
```

### `POST /auth/phone/verify-otp`

Request:

```json
{
  "phone": "+91...",
  "otp": "222222",
  "name": "optional"
}
```

Response:

```json
{
  "access_token": "jwt",
  "user_id": "uuid",
  "phone": "+91...",
  "role": "citizen"
}
```

---

## 2) Profile / NFC

### `GET /nfc/profile/{user_id}`

Returns the card holder’s medical/contact fields plus **`reader_context`**: telemetry from the scanning device (location, battery, connectivity, etc.) as observed at read time.

Path parameter:

- `user_id` — UUID string for the NFC / emergency-card user.

Success response (shape matches OAS 3.1 / live backend):

```json
{
  "name": "string",
  "blood_group": "string",
  "allergies": "string",
  "emergency_contact": "+91...",
  "reader_context": {
    "client": "resqnet_flutter",
    "heading": 0,
    "injured": false,
    "client_ts": "2026-04-08T21:48:16.609177Z",
    "speed_mps": 0,
    "altitude_m": 834.9,
    "app_language": "en",
    "connectivity": "wifi",
    "people_count": 0,
    "battery_percent": 80,
    "reader_latitude": 13.1688756,
    "reader_longitude": 77.5335605,
    "nearest_event_id": null,
    "nfc_user_id_recent": "11111111-1111-1111-1111-111111111111",
    "description_summary": "nfc_emergency_card_scan",
    "location_accuracy_m": 16.02,
    "nfc_linked_seconds_ago": 7
  }
}
```

Notes:

- `reader_context` may be present or omitted depending on client; treat optional fields defensively in UI.
- `nearest_event_id` is UUID or `null`.

Not found / error:

```json
{ "detail": "Profile not found" }
```

(or FastAPI `422` validation body for malformed `user_id`).

---

### `POST /nfc/scans`

Ingest a single NFC read event (tag payload + reader context). Used by mobile clients after a successful tap.

Typical request body (align with `NFCScanRequest` in `/openapi.json`):

```json
{
  "card_user_id": "11111111-1111-1111-1111-111111111111",
  "scanner_user_id": null,
  "tag_payload": {
    "user_id": "11111111-1111-1111-1111-111111111111",
    "display_name": "string",
    "age": 21,
    "health_conditions": "string"
  },
  "reader_context": {
    "client": "resqnet_flutter",
    "heading": 0,
    "injured": false,
    "client_ts": "2026-04-08T21:48:16.609177Z",
    "speed_mps": 0,
    "altitude_m": 834.9,
    "app_language": "en",
    "connectivity": "wifi",
    "people_count": 0,
    "battery_percent": 80,
    "reader_latitude": 13.1688756,
    "reader_longitude": 77.5335605,
    "nearest_event_id": null,
    "nfc_user_id_recent": "11111111-1111-1111-1111-111111111111",
    "description_summary": "nfc_emergency_card_scan",
    "location_accuracy_m": 16.02,
    "nfc_linked_seconds_ago": 7
  }
}
```

Success: returns the created scan record (same shape as one element of `items` under `GET /nfc/scans`, including `id` and `scanned_at`). Confirm exact response in `/openapi.json` if you rely on fields for idempotency.

---

### `GET /nfc/scans`

List stored NFC scan events (admin / ops / dashboard).

Query parameters:

| Name           | Type    | Description                          |
|----------------|---------|--------------------------------------|
| `limit`        | integer | Max rows (e.g. `50`)                 |
| `card_user_id` | string  | Filter to scans for that card user   |

Success response:

```json
{
  "items": [
    {
      "id": "1e6ae97b-76f3-4974-a479-d50c53a61f98",
      "card_user_id": "11111111-1111-1111-1111-111111111111",
      "scanner_user_id": null,
      "scanned_at": "2026-04-08T21:48:18.009445+00:00",
      "tag_payload": {
        "age": 21,
        "user_id": "11111111-1111-1111-1111-111111111111",
        "display_name": "string",
        "health_conditions": "string"
      },
      "reader_context": { },
      "reader_context_error": null,
      "profile_snapshot": {
        "age": 21,
        "name": "string",
        "allergies": "string",
        "blood_group": "O+",
        "health_summary": "string",
        "emergency_contact": "+91..."
      },
      "profile_fetch_error": null
    }
  ],
  "count": 1
}
```

- `reader_context_error` / `profile_fetch_error`: string or `null` if the server could not parse context or fetch profile at ingest time.

---

## 3) SOS and Dispatch

### `POST /sos`

Request:

```json
{
  "user_id": "uuid",
  "type": "medical|disaster|safety",
  "latitude": 12.93,
  "longitude": 77.62,
  "source": "app|watch|whatsapp|nfc"
}
```

Success response:

```json
{
  "incident_id": "uuid",
  "status": "assigned",
  "responder": {
    "id": "uuid",
    "name": "string",
    "type": "ambulance",
    "eta": "N mins"
  }
}
```

No-responder response:

```json
{
  "incident_id": "uuid",
  "status": "pending",
  "responder": null
}
```

---

## 4) WhatsApp Bot

### `POST /webhook/whatsapp`

- Form params: `From`, `Body`, optional `Latitude`, `Longitude`
- Response format: TwiML XML

Example:

```xml
<Response>
  <Message>...</Message>
</Response>
```

Behavior by message intent:
- Help keywords: SOS acknowledgment (`Incident ID`, `Status`, `Responder`, `ETA`)
- Medical keywords: symptom guidance (`severity`, steps, medicines)
- `flood`: mock shelter list
- Other reports: default disaster confirmation/broadcast message

### `GET /whatsapp/status`

Response:

```json
{
  "configured": true,
  "whatsapp_number": "whatsapp:+14155238886",
  "broadcast_reach": 120
}
```

---

## 5) Health Advice AI

### `POST /health/advice`

Request:

```json
{ "symptoms": "text" }
```

Response:

```json
{
  "severity": "low|medium|high",
  "steps": ["..."],
  "medicines": ["Paracetamol 500mg", "Amoxicillin 500mg", "Dolo 650"]
}
```

Notes:
- `steps` always present
- `medicines` always present
- medicine suggestions are India-oriented

---

## 6) Reports & Events

### `POST /reports`

Request:

```json
{
  "source": "string",
  "latitude": 12.93,
  "longitude": 77.62,
  "disaster_type": "flood|fire|earthquake|...",
  "description": "optional",
  "people_count": 10,
  "injuries": true,
  "weather_severity": 6
}
```

Response:

```json
{
  "report_id": "uuid",
  "event_id": "uuid",
  "confidence": 0.82
}
```

### `GET /reports`

Query params: `limit`, `source`, `event_id`

Response:

```json
[
  {
    "id": "...",
    "event_id": "...",
    "source": "app|whatsapp|news",
    "disaster_type": "flood",
    "description": "string",
    "latitude": 12.93,
    "longitude": 77.62,
    "people_count": 4,
    "injuries": true,
    "weather_severity": 5.0,
    "created_at": "iso"
  }
]
```

### `GET /reports/{report_id}`

Response:

```json
{
  "id": "...",
  "event_id": "...",
  "source": "app|whatsapp|news",
  "disaster_type": "...",
  "description": "...",
  "latitude": 12.93,
  "longitude": 77.62,
  "people_count": 3,
  "injuries": false,
  "weather_severity": 4.0,
  "created_at": "iso"
}
```

### `GET /events`

Query params: `active_only`, `limit`, `severity`

Response:

```json
[
  {
    "id": "...",
    "type": "...",
    "confidence": 0.8,
    "severity": "high",
    "active": true
  }
]
```

### `GET /events/nearby?lat=...&lng=...&radius_km=3`

Response:

```json
[
  {
    "id": "...",
    "distance_km": 1.7
  }
]
```

### `GET /events/{event_id}`

Response:

```json
{
  "id": "...",
  "type": "...",
  "severity": "medium",
  "reports": [],
  "report_count": 0
}
```

### `PATCH /events/{event_id}/resolve`

Response:

```json
{ "message": "Event resolved" }
```

---

## 7) AI Insights

### `GET /ai/insights/summary`

Response:

```json
{
  "top_prediction": "Likely flood escalation near 12.93,77.60 in ~40 min",
  "high_risk_zones": 3,
  "recommended_actions": ["Monitor flood near 12.93,77.60 — HIGH"],
  "model_version": "triage-v1.0"
}
```

### `GET /ai/insights/actions?limit=10`

Response:

```json
[
  {
    "id": "uuid",
    "urgency": "Immediate|Watch|Monitor",
    "owner": "Urban Response Cell",
    "action": "Dispatch responders to flood near 12.93,77.60."
  }
]
```

---

## 8) Device & Wearable Ingestion

### `POST /devices/register`

Request:

```json
{
  "user_id": "uuid",
  "device_type": "phone|watch|nfc_tag",
  "device_id": "vendor-id",
  "platform": "android|ios|wearos|watchos",
  "push_token": "optional"
}
```

Response:

```json
{
  "message": "Device registered",
  "device_record_id": "uuid"
}
```

### `POST /wearables/fall-detected`

Request:

```json
{
  "user_id": "uuid",
  "device_id": "string",
  "event_time": "iso",
  "latitude": 12.93,
  "longitude": 77.62,
  "impact_score": 0.92,
  "heart_rate": 118
}
```

Response:

```json
{
  "message": "Fall detected and SOS triggered",
  "incident_id": "uuid",
  "status": "assigned|pending"
}
```

### `POST /wearables/heart-alert`

Request:

```json
{
  "user_id": "uuid",
  "device_id": "string",
  "heart_rate": 145,
  "latitude": 12.93,
  "longitude": 77.62,
  "event_time": "iso?"
}
```

Response:

```json
{
  "message": "Heart alert recorded and SOS dispatched",
  "incident_id": "uuid",
  "status": "assigned|pending"
}
```

---

## 9) Admin/Controller APIs

### `GET /responders`

Query params:
- `availability=ready|en_route|deployed|offline`
- `type=ambulance|police|fire|volunteer`
- `limit=number`

Response:

```json
[
  {
    "id": "uuid",
    "name": "Unit Falcon-2",
    "type": "ambulance",
    "phone": "+91...",
    "latitude": 12.93,
    "longitude": 77.62,
    "availability": "ready",
    "current_status": "Ready",
    "eta_minutes": 0,
    "updated_at": "iso"
  }
]
```

### `POST /responders`

Request:

```json
{
  "name": "string",
  "type": "ambulance|police|fire|volunteer",
  "phone": "+91...",
  "latitude": 12.93,
  "longitude": 77.62,
  "availability": "ready"
}
```

Response:

```json
{
  "message": "Responder created",
  "responder_id": "uuid"
}
```

### `PATCH /responders/{responder_id}`

Request:

```json
{
  "availability": "en_route",
  "current_status": "Heading to incident",
  "eta_minutes": 12
}
```

Response:

```json
{ "message": "Responder updated" }
```

### `POST /responders/{responder_id}/location`

Request:

```json
{
  "latitude": 12.93,
  "longitude": 77.62,
  "speed_kmph": 45
}
```

Response:

```json
{
  "message": "Location updated",
  "updated_at": "iso"
}
```

### `GET /responders/nearby?lat=...&lng=...&radius_km=5`

Response:

```json
[
  {
    "id": "uuid",
    "name": "Unit Falcon-2",
    "type": "ambulance",
    "distance_km": 1.6,
    "eta_minutes": 5,
    "availability": "ready"
  }
]
```

### `GET /incidents/live`

Response:

```json
[
  {
    "incident_id": "uuid",
    "type": "medical",
    "status": "assigned",
    "priority": "high",
    "latitude": 12.93,
    "longitude": 77.62,
    "created_at": "iso"
  }
]
```

### `PATCH /incidents/{incident_id}/status`

Request:

```json
{ "status": "pending|assigned|resolved|escalated" }
```

Response:

```json
{ "message": "Incident status updated" }
```

### `POST /incidents/{incident_id}/assign`

Request:

```json
{
  "responder_id": "uuid",
  "assigned_by": "authority_user_id",
  "note": "optional"
}
```

Response:

```json
{
  "message": "Responder assigned|Responder already assigned",
  "incident_id": "uuid",
  "responder_id": "uuid",
  "status": "assigned",
  "distance_km": 2.1,
  "eta_minutes": 6
}
```

Note: every call refreshes returned `distance_km` and `eta_minutes`.

### `POST /dispatch/optimize`

Request:

```json
{
  "incident_id": "uuid",
  "latitude": 12.93,
  "longitude": 77.62,
  "required_unit": "ambulance|police|fire"
}
```

Response:

```json
{
  "selected_responder": {}
}
```

Error:

```json
{ "detail": "No eligible responders available" }
```

Status code: `409`

### `GET /realtime/{channel}`

Channels:
- `incidents_live`
- `responders_live`
- `assignments_live`

Response: Server-Sent Events stream with:
- initial `snapshot` event
- subsequent `data` events (changed records)

---

## 10) WhatsApp AI Triage Helpers

### `POST /whatsapp/triage`

Request:

```json
{
  "phone": "whatsapp:+91...",
  "message": "text",
  "latitude": 12.93,
  "longitude": 77.62,
  "language": "en|hi|..."
}
```

Response:

```json
{
  "phone": "whatsapp:+91...",
  "latitude": 12.93,
  "longitude": 77.62,
  "triage": {
    "severity": "medium",
    "steps": ["..."],
    "medicines": ["Paracetamol"],
    "dispatch_recommended": true,
    "confidence": 0.92,
    "language": "en"
  }
}
```

### `POST /whatsapp/triage/escalate`

Request:

```json
{
  "phone": "whatsapp:+91...",
  "triage_result": {},
  "latitude": 12.93,
  "longitude": 77.62
}
```

Response:

```json
{
  "incident_id": "uuid",
  "status": "assigned|pending",
  "reply_text": "Emergency escalated...",
  "responder": {}
}
```

---

## 11) Grid Risk

### `GET /grid`

Query param:
- `min_risk`: filters rows where `risk_score >= min_risk`

Response:

```json
[
  {
    "grid_lat": 12.93,
    "grid_lng": 77.62,
    "risk_score": 68.0
  }
]
```

### `GET /grid/nearby?lat=&lng=&radius_km=`

Response:

```json
[
  {
    "grid_lat": 12.93,
    "grid_lng": 77.62,
    "risk_score": 68.0,
    "distance_km": 1.2
  }
]
```

---

## 12) Predictions

### `GET /predictions`

Response:

```json
[
  {
    "event_id": "uuid",
    "warning": "string",
    "triggers": ["..."],
    "confidence": 0.75,
    "severity": "low|medium|high",
    "latitude": 12.93,
    "longitude": 77.62,
    "generated_at": "iso"
  }
]
```

---

## 13) Simulation

### `POST /simulation/spread`

Request:

```json
{ "event_id": "uuid" }
```

Response:

```json
{
  "event_id": "uuid",
  "cells_affected": 12,
  "spread_data": [
    {
      "grid_lat": 12.93,
      "grid_lng": 77.62,
      "risk_score": 68.0
    }
  ]
}
```

### `POST /simulation/compare`

Request:

```json
{ "event_id": "uuid" }
```

Response:

```json
{
  "resqnet": { "unit": "string", "distance_km": 2.4, "eta_minutes": 6 },
  "naive": { "unit": "string", "distance_km": 4.2, "eta_minutes": 10 },
  "time_saved_minutes": 4,
  "projected_casualties_avoided": 1.2,
  "impact_summary": "string"
}
```

---

## 14) Dashboard

### `GET /dashboard/stats`

Response:

```json
{
  "events": { "total": 0, "active": 0, "high_severity": 0 },
  "reports": { "total": 0, "last_24h": 0, "by_source": {} },
  "rescue_units": { "total": 0, "available": 0, "busy": 0 }
}
```

### `GET /dashboard/feed`

Response:

```json
{
  "recent_reports": [],
  "recent_events": []
}
```

---

## 15) External Ingestion

### `POST /external/ingest`

Request:

```json
{
  "source": "news|social|weather",
  "latitude": 12.93,
  "longitude": 77.62,
  "disaster_type": "string",
  "severity_score": 7.4,
  "description": "optional"
}
```

Response:

```json
{
  "message": "...",
  "event_id": "uuid"
}
```

### `POST /external/ingest/bulk`

Request:

```json
[{ "...": "..." }]
```

Response:

```json
{
  "ingested": 5,
  "results": [{ "message": "...", "event_id": "uuid" }]
}
```

---

## 16) Media Uploads

### `POST /media/upload`

Multipart form fields:
- `file` (image)
- `latitude`
- `longitude`
- `disaster_type`
- optional `report_id`
- optional `user_id`

Response:

```json
{
  "url": "https://.../bucket/path",
  "file_name": "disaster/uuid.ext",
  "latitude": 12.93,
  "longitude": 77.62,
  "disaster_type": "flood",
  "report_id": "uuid?",
  "message": "Image uploaded successfully."
}
```

### `GET /media/list?disaster_type=flood&limit=10`

Response:

```json
{
  "files": [
    {
      "name": "flood/uuid.jpg",
      "url": "...",
      "size_bytes": 12345,
      "created_at": "iso",
      "disaster_type": "flood"
    }
  ],
  "total": 1
}
```

---

## 17) News

### `GET /news`

Optional query param:
- `disaster_type`

Response:

```json
{
  "articles": [
    {
      "title": "string",
      "source": "string",
      "url": "string",
      "summary": "string",
      "published": "string",
      "disaster_type": "string"
    }
  ],
  "total": 1,
  "scraped_at": "iso"
}
```

---

## 18) Minimal Confidence Scoring (Rule-Based Fallback)

### `POST /ml/confidence/score`

Request (all fields optional, recommended):

```json
{
  "event_id": "uuid",
  "report_counts": { "app": 1, "whatsapp": 2 },
  "source_entropy": 0.75,
  "local_grid_risk_score": 68,
  "weather_severity": 6,
  "nearby_ready_responders": 2,
  "eonet_event_count_24h": 1
}
```

Response:

```json
{
  "model_version": "confidence_rule_v1",
  "base_confidence": 0.75,
  "confidence": 0.68,
  "reasons": ["Multiple sources in last 30m", "Penalty: low source entropy"],
  "fallback_used": true
}
```

Use cases:
- stopgap confidence scoring for `/reports`
- stopgap confidence scoring for `/predictions`
- stopgap confidence scoring for `/ai/insights`

---

## Admin Panel Endpoint Map

For fastest admin integration, prioritize these:
- Live operations: `/incidents/live`, `/responders`, `/responders/{id}`, `/incidents/{id}/assign`, `/incidents/{id}/status`
- Dispatch support: `/responders/nearby`, `/dispatch/optimize`
- Monitoring: `/events`, `/events/{id}`, `/reports`, `/reports/{id}`, `/dashboard/stats`, `/dashboard/feed`
- Realtime stream: `/realtime/{channel}` with channels `incidents_live`, `responders_live`, `assignments_live`

