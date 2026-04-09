# ResQNet+ Backend Changes To Be Made

This document is the backend execution plan to support:

- Mobile SOS
- Smartwatch-triggered emergencies
- WhatsApp AI triage
- NFC medical lookup
- Admin dashboard operations
- Real-time responder coordination

It is based on the current API contract plus the new product direction.

---

## Admin Panel Only (use this section first)

If your immediate goal is only the Next.js admin dashboard (`/dashboard`, `/incidents`, `/map`, `/responders`, `/ai-insights`), implement these backend changes in this exact order:

### 1) Incidents feed for `/incidents` and `/dashboard`

- `GET /incidents/live`
  - returns compact list for incident table and top metrics
- `PATCH /incidents/{incident_id}/status`
  - supports `pending|assigned|resolved|escalated`
- `POST /incidents/{incident_id}/assign`
  - links responder to incident

Why admin needs this:

- incident table actions must persist to backend (not local UI state)
- dashboard counts must come from real records

### 2) Responder management for `/responders` page

- `GET /responders`
- `POST /responders`
- `PATCH /responders/{responder_id}`
- `POST /responders/{responder_id}/location`
- `GET /responders/nearby`

Why admin needs this:

- responders page currently has no live backend feed
- map needs responder coordinates + availability state

### 3) Map + command-center data for `/map` and `/dashboard`

- Keep using `GET /events`
- Add/ensure responder live stream (via `GET /responders` + realtime updates)
- Supabase realtime channels:
  - `incidents_live`
  - `responders_live`
  - `assignments_live`

Why admin needs this:

- map must auto-refresh without manual reload
- command center should reflect assignment changes in seconds

### 4) AI insights page backend for `/ai-insights`

- Keep `GET /predictions`
- Keep `GET /grid`
- Add `GET /ai/insights/summary`
- Add `GET /ai/insights/actions?limit=10`

Why admin needs this:

- `ai-insights` page currently derives data; backend should provide decision-ready cards/actions

### 5) Dashboard aggregate endpoints

- Keep `GET /dashboard/stats`
- Keep `GET /dashboard/feed`
- Ensure these are computed from actual incidents/responders/events, not static data

Why admin needs this:

- top cards and feed should always match operational truth

---

## OpenAI Key Requirement (Admin Panel)

Short answer: **OpenAI key is optional for basic admin operations, required for AI-insights quality features.**

### OpenAI key NOT required for:

- `/incidents`, `/responders`, `/map`, assignment flows, resolver flows, live telemetry
- basic metrics on `/dashboard` from DB aggregations

### OpenAI key required for:

- intelligent action recommendations on `/ai-insights`
- natural-language triage summaries shown in command center
- any “why this is high risk” generated explanations

### Suggested env vars

- `OPENAI_API_KEY=...`
- `OPENAI_MODEL_TRIAGE=...` (fast/cheap model)
- `OPENAI_MODEL_REASONING=...` (better model for insights text)

If you share the key, I can wire production-safe AI endpoints with:

- strict JSON schema output,
- timeout fallback to deterministic rules,
- logging and cost guardrails.

---

## 0) Priority Order

### P0 (must work first)

- Stable auth + user profile
- SOS creation + responder assignment
- Incidents/events read APIs for dashboard
- WhatsApp webhook (TwiML output)
- Health advice API (safe, deterministic JSON)
- Realtime subscriptions from incidents/events

### P1 (win layer)

- Responder CRUD + location updates
- Dispatch optimizer endpoint
- Device registration (phone/watch/NFC token)
- Analytics endpoints for command center

### P2 (advanced)

- Fall detection ingestion
- Voice-note triage (WhatsApp audio)
- Predictive risk and proactive alerts

---

## 1) Gaps vs Current State

Current backend has many core endpoints, but these are missing/insufficient for the product story:

- No responder management APIs for `/responders` admin page
- No live responder telemetry endpoint (position/status heartbeat)
- No dispatch optimization endpoint that includes traffic/hospital context
- No dedicated wearable/fall event ingestion endpoint
- No explicit OpenAI orchestration endpoints for:
  - structured emergency triage
  - multilingual conversational guidance
  - escalation confidence scoring
- No strict auth enforcement yet on write/admin routes
- No audit trail endpoints for authority actions

---

## 2) Endpoints To Keep (already aligned)

Keep and harden these existing routes:

- `POST /auth/signup`
- `POST /auth/login`
- `POST /auth/logout`
- `POST /auth/phone/send-otp`
- `POST /auth/phone/verify-otp`
- `GET /nfc/profile/{user_id}`
- `POST /sos`
- `POST /webhook/whatsapp`
- `GET /whatsapp/status`
- `POST /health/advice`
- `POST /reports`
- `GET /reports`
- `GET /reports/{report_id}`
- `GET /events`
- `GET /events/{event_id}`
- `GET /events/nearby`
- `PATCH /events/{event_id}/resolve`
- `GET /grid`
- `GET /grid/nearby`
- `GET /predictions`
- `POST /simulation/spread`
- `POST /simulation/compare`
- `GET /dashboard/stats`
- `GET /dashboard/feed`
- `POST /external/ingest`
- `POST /external/ingest/bulk`
- `POST /media/upload`
- `GET /media/list`
- `GET /news`

---

## 3) New Endpoints To Add (Detailed)

## 3.1 Responder Management (required for admin)

### `GET /responders`

Query:

- `availability=ready|en_route|deployed|offline` (optional)
- `type=ambulance|police|fire|volunteer` (optional)
- `limit=number` (optional)

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
    "current_status": "Awaiting assignment",
    "eta_minutes": 0,
    "updated_at": "iso"
  }
]
```

### `POST /responders`

Request:

```json
{
  "name": "Unit Falcon-2",
  "type": "ambulance",
  "phone": "+91...",
  "latitude": 12.93,
  "longitude": 77.62,
  "availability": "ready"
}
```

Response:

```json
{ "message": "Responder created", "responder_id": "uuid" }
```

### `PATCH /responders/{responder_id}`

Request (partial update):

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
{ "latitude": 12.94, "longitude": 77.63, "speed_kmph": 42.5 }
```

Response:

```json
{ "message": "Location updated", "updated_at": "iso" }
```

### `GET /responders/nearby?lat=...&lng=...&radius_km=...`

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

---

## 3.2 Incident Assignment + Command Actions

### `POST /incidents/{incident_id}/assign`

Request:

```json
{
  "responder_id": "uuid",
  "assigned_by": "authority_user_id"
}
```

Response:

```json
{
  "message": "Responder assigned",
  "incident_id": "uuid",
  "responder_id": "uuid",
  "status": "assigned"
}
```

### `PATCH /incidents/{incident_id}/status`

Request:

```json
{ "status": "pending|assigned|resolved|escalated", "note": "optional" }
```

Response:

```json
{ "message": "Incident status updated" }
```

### `GET /incidents/live`

Purpose:

- Fast stream feed for dashboard list (minimal fields)

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

---

## 3.3 Wearable / Auto Detection

### `POST /devices/register`

Request:

```json
{
  "user_id": "uuid",
  "device_type": "phone|watch|nfc_tag",
  "device_id": "vendor-serial-or-token",
  "platform": "android|ios|wearos|watchos",
  "push_token": "optional"
}
```

Response:

```json
{ "message": "Device registered", "device_record_id": "uuid" }
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
  "impact_score": 0.93,
  "heart_rate": 128
}
```

Response:

```json
{
  "incident_id": "uuid",
  "status": "pending|assigned",
  "auto_triggered": true
}
```

### `POST /wearables/heart-alert`

Request:

```json
{
  "user_id": "uuid",
  "device_id": "string",
  "heart_rate": 172,
  "latitude": 12.93,
  "longitude": 77.62
}
```

Response:

```json
{ "message": "Alert received", "incident_id": "uuid" }
```

---

## 3.4 WhatsApp Advanced Conversation APIs

### `POST /whatsapp/triage`

Purpose:

- Structured triage from text/voice transcript

Request:

```json
{
  "phone": "+91...",
  "message": "My father fell and is not responding",
  "latitude": 12.93,
  "longitude": 77.62,
  "language": "en"
}
```

Response:

```json
{
  "intent": "medical_emergency",
  "severity": "high",
  "recommended_actions": ["Check breathing", "Start CPR if no pulse"],
  "dispatch_recommended": true,
  "confidence": 0.92
}
```

### `POST /whatsapp/escalate`

Request:

```json
{
  "phone": "+91...",
  "triage_result": { "severity": "high", "dispatch_recommended": true },
  "latitude": 12.93,
  "longitude": 77.62
}
```

Response:

```json
{
  "incident_id": "uuid",
  "status": "assigned|pending",
  "reply_text": "Emergency dispatched. Keep patient on side position..."
}
```

---

## 3.5 Dispatch Optimization

### `POST /dispatch/optimize`

Request:

```json
{
  "incident_id": "uuid",
  "latitude": 12.93,
  "longitude": 77.62,
  "required_unit": "ambulance"
}
```

Response:

```json
{
  "selected_responder": {
    "id": "uuid",
    "name": "Unit Falcon-2",
    "distance_km": 2.1,
    "eta_minutes": 6
  },
  "alternates": [
    { "id": "uuid", "eta_minutes": 8 }
  ],
  "hospital_recommendation": {
    "name": "City Trauma Center",
    "distance_km": 4.3,
    "capacity_status": "available"
  }
}
```

---

## 3.6 AI Insight Endpoints for Dashboard

### `GET /ai/insights/summary`

Response:

```json
{
  "top_prediction": "Likely flood escalation near river belt in 40 min",
  "high_risk_zones": 3,
  "recommended_actions": ["Pre-position pumps", "Push area alert"],
  "model_version": "triage-v1.2"
}
```

### `GET /ai/insights/actions?limit=10`

Response:

```json
[
  {
    "id": "uuid",
    "urgency": "Immediate",
    "owner": "Urban Flood Cell",
    "action": "Deploy barricades in Sector 4"
  }
]
```

---

## 4) OpenAI Work Items (Yes, must be done)

You asked if there are OpenAI things pending. Yes, these are the concrete backend tasks:

1. Structured triage model call

- Used by: `/health/advice`, `/whatsapp/triage`
- Enforce JSON schema output:
  - `severity`
  - `steps[]`
  - `medicines[]`
  - `dispatch_recommended` (for WhatsApp triage)
  - `confidence`

1. Prompt safety + medical guardrails

- Add system prompt rules:
  - no definitive diagnosis
  - always emergency escalation for red flags
  - short actionable first-aid steps
  - India-friendly OTC naming (as already required)

1. Multilingual support

- Auto detect language from WhatsApp text
- Return response in same language when possible

1. Voice-note support

- Twilio media URL -> transcription -> triage
- Endpoint impact: `/webhook/whatsapp` and `/whatsapp/triage`

1. Fallback behavior

- If model fails/timeouts:
  - return deterministic safe default JSON
  - still allow SOS escalation

1. Observability for AI

- Store:
  - prompt version
  - latency
  - confidence
  - escalation decision
  - anonymized transcript hash

1. Cost control

- Use compact model for classification
- Use stronger model only for complex medical guidance
- Cache repeated symptom patterns where possible

---

## 5) Database Changes Required

Add or harden these tables:

- `responders`
  - id, name, type, phone, availability, lat, lng, current_status, eta_minutes, updated_at
- `responder_locations`
  - id, responder_id, lat, lng, speed_kmph, captured_at
- `incidents`
  - id, user_id, type, status, priority, lat, lng, source, created_at, resolved_at
- `incident_assignments`
  - id, incident_id, responder_id, assigned_by, assigned_at, note
- `devices`
  - id, user_id, device_type, device_id, platform, push_token, last_seen_at
- `wearable_events`
  - id, user_id, device_id, event_type, payload_json, created_at
- `whatsapp_sessions`
  - phone, last_intent, last_severity, last_interaction_at
- `ai_logs`
  - id, feature, model, prompt_version, latency_ms, confidence, escalation, created_at
- `audit_logs`
  - id, actor_user_id, action, resource_type, resource_id, metadata, created_at

Indexes:

- incidents: `(status, created_at desc)`, `(lat, lng)` spatial
- responders: `(availability, type)`, `(lat, lng)` spatial
- wearable_events: `(user_id, created_at desc)`

---

## 6) Security + Reliability Changes

1. Enforce auth now

- Protect all admin write routes (`/responders`, assignments, resolves, external ingest)
- Role check: `authority` only for command actions

1. Rate limits

- Strong limits on:
  - `/auth/phone/send-otp`
  - `/webhook/whatsapp`
  - `/health/advice`

1. Idempotency

- Add `Idempotency-Key` support for:
  - `/sos`
  - `/wearables/fall-detected`
  - `/external/ingest`

1. Realtime broadcasting

- Push incident/responder updates via Supabase realtime channels:
  - `incidents_live`
  - `responders_live`
  - `assignments_live`

1. SLA targets

- P95 latency target:
  - critical routes under 500ms excluding AI calls
  - AI triage under 2.5s with timeout fallback

---

## 7) Acceptance Checklist (Definition of Done)

- Mobile SOS can create incident and get assignment result
- Dashboard sees incident in realtime within 2 seconds
- Authority can assign responder and mark resolve
- Map shows live responder positions from backend data
- WhatsApp keyword and triage flows return correct TwiML
- Health advice always returns strict JSON shape
- Fall detection endpoint creates incident without user interaction
- Auth + role checks enabled on all privileged routes
- Audit logs captured for all command actions
- API docs exported (OpenAPI/Postman) with examples

---

## 8) Recommended Immediate Sprint (next 48 hours)

1. Build responder CRUD + nearby + location heartbeat
2. Build incident assignment/status endpoints
3. Add auth/role middleware to admin routes
4. Ship OpenAI-backed `/whatsapp/triage` with safe fallback
5. Add Supabase realtime events for incidents/responders

If these five are done, the full ResQNet+ demo becomes consistent across app, WhatsApp, wearable simulation, NFC, and command center.