# SOS API — POST (create) and GET (read)

SOS is intentionally minimal: **POST** persists an emergency signal to the database; **GET** reads stored SOS records for dashboards, apps, or ops.

---

## `POST /sos`

Creates an SOS incident and returns assignment metadata.

**Request** (`Content-Type: application/json`)


| Field       | Type   | Required | Notes                                      |
| ----------- | ------ | -------- | ------------------------------------------ |
| `user_id`   | string | yes      | Caller identity (UUID or stable id).       |
| `type`      | string | yes      | One of: `medical`, `disaster`, `safety`.   |
| `latitude`  | number | yes      | WGS-84 latitude.                           |
| `longitude` | number | yes      | WGS-84 longitude.                          |
| `source`    | string | yes      | One of: `app`, `watch`, `whatsapp`, `nfc`. |


**Example**

```http
POST /sos
Content-Type: application/json

{
  "user_id": "33a111d5-80af-4995-9394-d3005b23399b",
  "type": "medical",
  "latitude": 12.93,
  "longitude": 77.62,
  "source": "app"
}
```

**Response** (`200`)


| Field            | Type   | Notes                             |
| ---------------- | ------ | --------------------------------- |
| `incident_id`    | string | Created incident / SOS record id. |
| `status`         | string | `assigned` or `pending`.          |
| `responder`      | object | null                              |
| `responder.id`   | string |                                   |
| `responder.name` | string |                                   |
| `responder.type` | string |                                   |
| `responder.eta`  | string |                                   |


Backend should insert the row (and enqueue assignment logic) on successful POST.

---

## `GET /sos`

Returns SOS records from the database (read path). Use this for listing, polling, or hydrating the client after creation.

**Suggested query parameters** (implement as needed)


| Parameter | Type    | Description                                |
| --------- | ------- | ------------------------------------------ |
| `limit`   | number  | Max rows (default e.g. 50, cap e.g. 500).  |
| `user_id` | string  | Filter by reporter.                        |
| `status`  | string  | If you store status on SOS rows.           |
| `since`   | ISO8601 | Records with `created_at` after this time. |


**Example**

```http
GET /sos?limit=100
```

**Response** (`200`)

Return an array of SOS / incident summaries. Shape should align with what you persist on POST (e.g. ids, location, type, timestamps, status).

---

## Client usage in this repo

- **Create only:** `createSos()` in `lib/api.ts` calls `POST /sos` with `SosRequest` and expects `SosResponse`.
- **Read:** add a `fetchSos(...)` (or similar) when the backend exposes `GET /sos`, then call it from pages that need history or detail.

---

## Summary


| Method          | Role                                         |
| --------------- | -------------------------------------------- |
| **POST** `/sos` | Write to DB — new SOS + assignment response. |
| **GET** `/sos`  | Read from DB — list or filter SOS records.   |


No other HTTP verb is required for the basic “create and fetch” SOS loop; use PATCH on incidents if you update status separately (e.g. `/incidents/:id/status`).