# ResQNet+

> **A unified emergency and disaster-intelligence platform: web command dashboard, wearable trigger (demo), NFC, and WhatsApp — with real-time signals, incidents, and responder coordination.**

---

## 1) Executive Summary

**ResQNet+** gives response teams a live command surface and helps everyone involved coordinate faster.

Signals and requests can arrive through the web dashboard, wearable demo, NFC, or WhatsApp; incident data, location, medical context, and updates stay in one shared real-time system.

---

## 2) Problem Statement

Current emergency workflows are often:

- Slow to initiate under stress
- Fragmented across disconnected channels
- Missing important medical context
- Difficult to track in real time

This leads to delayed decisions, slower response, and poor visibility for both users and responders.

---

## 3) Our Solution

ResQNet+ connects the full emergency journey end-to-end:

- **Primary surface:** Web dashboard for live risk signals, incident validation, maps, and orchestration
- **Trigger & access channels:** Smartwatch trigger (demo simulation), NFC emergency card, WhatsApp assistant
- **Core flow:** Incident creation, profile lookup, responder assignment, live updates
- **Guidance layer:** Immediate first-aid support and AI-assisted suggestions
- **Intelligence feed:** Situation updates scraped from news portals and channels

---

## 4) Product Modules

### 4.1 Web Command Dashboard

- Live disaster-intelligence and risk signals
- Incident feed, status workflow, and responder assignment
- Map and situational monitoring
- Real-time updates via Supabase subscriptions
- Analytics and source breakdown for reports and external signals

### 4.2 Smartwatch Trigger (Demo Simulation)

- Fall alert simulation
- Abnormal heart-rate simulation
- Quick SOS initiation for hands-free or wearable-first scenarios

### 4.3 NFC Emergency Card

- Quick profile access
- Blood group, allergies, and emergency contacts
- QR fallback for compatibility

### 4.4 WhatsApp Assistant

- Emergency guidance
- Health-related support prompts
- Shelter/helpline oriented responses

### 4.5 Intelligence & ingestion

- News and channel scraping for situation context
- External signals, events, and grid risk modeling (where enabled)

---

## 5) Why It Matters

| Existing Gap                | ResQNet+ Response                                   |
| --------------------------- | --------------------------------------------------- |
| Slow reporting              | Triggers via NFC, WhatsApp, watch demo, or dashboard |
| Missing medical info        | Profile with blood group, allergies, contacts       |
| No shared visibility        | Real-time incident and assignment updates           |
| Platform dependency         | Web-first ops plus wearable demo, NFC, and WhatsApp |
| Weak responder coordination | Dashboard-based orchestration                       |

---

## 6) High-Level Workflow

```mermaid
flowchart TD
    A[Event or request] --> B{Channel}
    B --> C[Web Dashboard]
    B --> D[Smartwatch demo]
    B --> E[NFC]
    B --> F[WhatsApp]

    C --> G[API Layer]
    D --> G
    E --> G
    F --> G

    G --> H[Supabase Database]
    G --> I[Supabase Realtime Events]
    G --> J[Guidance + AI Layer]
    G --> O[News/Channel Intelligence Feed]

    H --> K[Incident / report created]
    I --> L[Dashboard updated]
    I --> M[Responder assigned]
    O --> L
    M --> N[Live status for operators]
```

---

## 7) System Architecture

```mermaid
flowchart LR
    U[Channels: Web, Watch demo, NFC, WhatsApp] --> A[Next.js / API Layer]
    A --> B[Supabase Auth]
    A --> C[Supabase Database]
    A --> D[Supabase Realtime]
    A --> E[OpenAI]
    A --> F[OpenWeather Map & Weather Data]
    A --> G[Twilio WhatsApp]

    D --> H[Admin Dashboard]
    C --> H
```

---

## 8) Database Model (API-Aligned Core)

```mermaid
erDiagram
    USERS {
        uuid id
        string email
        string phone
        string role
        string name
        string blood_group
        string allergies
        string emergency_contact
        datetime created_at
    }

    INCIDENTS {
        uuid id
        uuid user_id
        string type
        string status
        string source
        float latitude
        float longitude
        uuid responder_id
        datetime created_at
    }

    RESPONDERS {
        uuid id
        string name
        string type
        float latitude
        float longitude
        string availability
    }

    REPORTS {
        uuid id
        uuid event_id
        uuid user_id
        string source
        string disaster_type
        float latitude
        float longitude
        int people_count
        bool injuries
        float weather_severity
        datetime created_at
    }

    EVENTS {
        uuid id
        string type
        float confidence
        string severity
        bool active
        float latitude
        float longitude
        datetime created_at
    }

    GRID_RISK {
        uuid id
        float grid_lat
        float grid_lng
        float risk_score
        datetime updated_at
    }

    PREDICTIONS {
        uuid id
        uuid event_id
        string warning
        float confidence
        string severity
        float latitude
        float longitude
        datetime generated_at
    }

    EXTERNAL_SIGNALS {
        uuid id
        string source
        string disaster_type
        float severity_score
        float latitude
        float longitude
        datetime ingested_at
    }

    MEDIA_FILES {
        uuid id
        uuid report_id
        uuid user_id
        string disaster_type
        string file_name
        string file_url
        float latitude
        float longitude
        datetime created_at
    }

    NEWS_ARTICLES {
        uuid id
        string title
        string source
        string url
        string disaster_type
        datetime published_at
        datetime scraped_at
    }

    USERS ||--o{ INCIDENTS : creates
    USERS ||--o{ REPORTS : submits
    USERS ||--o{ MEDIA_FILES : uploads
    RESPONDERS ||--o{ INCIDENTS : assigned_to
    EVENTS ||--o{ REPORTS : aggregates
    EVENTS ||--o{ PREDICTIONS : drives
    REPORTS ||--o{ MEDIA_FILES : evidence
    EXTERNAL_SIGNALS o{--o| EVENTS : contributes_to
```

---

## 9) API Snapshot

### Create SOS

```http
POST /sos
Content-Type: application/json

{
  "userId": "uuid",
  "location": "lat,lng",
  "type": "medical"
}
```

### Nearby Responders

```http
GET /responders/nearby
```

### Update Incident Status

```http
PATCH /incident/:id
Content-Type: application/json

{
  "status": "in-progress"
}
```

### Chat Support

```http
POST /chat
Content-Type: application/json

{
  "message": "I have chest pain"
}
```

---

## 10) Technology Stack

| Layer                  | Technology             |
| ---------------------- | ---------------------- |
| Frontend               | Next.js                |
| Backend                | Next.js API / Express  |
| Database               | Supabase               |
| Authentication         | Supabase Auth          |
| Realtime               | Supabase Subscriptions |
| AI                     | OpenAI                 |
| Messaging              | Twilio WhatsApp        |
| Maps & Weather Context | OpenWeather            |
| Hosting                | Vercel / Render        |

---

## 11) Demo Flow

```mermaid
flowchart TD
    A[Open web dashboard / trigger via NFC, WhatsApp, or watch demo] --> B[Signal or incident recorded]
    B --> C[Operators review type and context]
    C --> D[Incident in system]
    D --> E[Dashboard alert and map update]
    E --> F[Responder assigned]
    F --> G[Live status and updates]
    G --> H[Incident resolved]
```

---

## 12) Future Scope

- Hospital-side responder dashboard
- Government disaster-management integrations
- Voice-enabled SOS
- Multilingual AI emergency assistance
- SMS fallback for low-connectivity areas
- Smart-campus / smart-city deployment

---

## 14) Closing

In an emergency, help should be one action away, and the system behind that action should already know what to do next.
