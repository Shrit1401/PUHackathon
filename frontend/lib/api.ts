const OPENWEATHER_BASE_URL = "https://api.openweathermap.org/data/2.5";

export type NewsArticle = {
  title: string;
  source: string;
  url: string;
  summary: string;
  published: string;
  disaster_type: string;
  query?: string;
};

export type NewsResponse = {
  articles: NewsArticle[];
  total: number;
  scraped_at: string;
};

export type ApiEvent = {
  id: string;
  type: string;
  source?: string;
  description?: string;
  latitude: number;
  longitude: number;
  confidence: number;
  severity: "low" | "medium" | "high";
  source_breakdown: {
    app: number;
    whatsapp: number;
    news: number;
    social: number;
  };
  weather_severity: number;
  active: boolean;
  created_at: string;
};

export type AuthSignupRequest = {
  email: string;
  password: string;
  name: string;
  role: "citizen" | "authority";
  phone: string;
  blood_group: string;
  allergies: string;
  emergency_contact: string;
};

export type AuthSignupResponse = {
  message: "Signup successful";
  user_id: string;
  role: string;
  access_token: string;
};

export type AuthLoginRequest = {
  email: string;
  password: string;
};

export type AuthLoginResponse = {
  access_token: string;
  user_id: string;
  email: string;
  role: string;
  profile: {
    id: string;
    name: string;
    phone: string;
    blood_group: string;
    allergies: string;
    emergency_contact: string;
    role: string;
  };
};

export type AuthLogoutResponse = {
  message: "Logged out";
};

export type SendOtpRequest = {
  phone: string;
};

export type SendOtpResponse = {
  message: string;
};

export type VerifyOtpRequest = {
  phone: string;
  otp: string;
  name?: string;
};

export type VerifyOtpResponse = {
  access_token: string;
  user_id: string;
  phone: string;
  role: "citizen";
};

/** Device / environment context when an NFC tag was read (profile GET or scan ingest). */
export type NfcReaderContext = {
  client?: string;
  heading?: number;
  injured?: boolean;
  client_ts?: string;
  speed_mps?: number;
  altitude_m?: number;
  app_language?: string;
  connectivity?: string;
  people_count?: number;
  battery_percent?: number;
  reader_latitude?: number;
  reader_longitude?: number;
  nearest_event_id?: string | null;
  nfc_user_id_recent?: string;
  description_summary?: string;
  location_accuracy_m?: number;
  nfc_linked_seconds_ago?: number;
};

export type NfcProfileResponse = {
  name: string;
  blood_group: string;
  allergies: string;
  emergency_contact: string;
  /** Present when the scanning client sends telemetry with the read. */
  reader_context?: NfcReaderContext;
};

export type NfcTagPayload = {
  user_id: string;
  display_name: string;
  age: number;
  health_conditions: string;
};

export type NfcProfileSnapshot = {
  age: number;
  name: string;
  allergies: string;
  blood_group: string;
  health_summary: string;
  emergency_contact: string;
};

export type NfcScanRecord = {
  id: string;
  card_user_id: string;
  scanner_user_id: string | null;
  scanned_at: string;
  tag_payload: NfcTagPayload;
  reader_context: NfcReaderContext;
  reader_context_error: string | null;
  profile_snapshot: NfcProfileSnapshot;
  profile_fetch_error: string | null;
};

export type NfcScanListResponse = {
  items: NfcScanRecord[];
  count: number;
};

export type NfcScanIngestRequest = {
  card_user_id: string;
  scanner_user_id?: string | null;
  tag_payload: NfcTagPayload;
  reader_context: NfcReaderContext;
};

export type SosRequest = {
  user_id: string;
  type: "medical" | "disaster" | "safety";
  latitude: number;
  longitude: number;
  source: "app" | "watch" | "whatsapp" | "nfc";
};

export type SosResponse = {
  incident_id: string;
  status: "assigned" | "pending";
  responder: {
    id: string;
    name: string;
    type: string;
    eta: string;
  } | null;
};

export type DashboardFeedReport = {
  id: string;
  source: string;
  disaster_type: string;
  description: string;
  latitude: number;
  longitude: number;
  created_at: string;
};

export type DashboardFeedEvent = {
  id: string;
  type: string;
  confidence: number;
  severity: "low" | "medium" | "high";
  active: boolean;
  created_at: string;
};

export type DashboardFeedResponse = {
  recent_reports: DashboardFeedReport[];
  recent_events: DashboardFeedEvent[];
};

export type DisasterPhoto = {
  id: string;
  url: string;
  label?: string;
};

export type DisasterPhotosResponse = {
  files: {
    name: string;
    url: string;
    size_bytes: number;
    created_at: string;
    disaster_type: string;
  }[];
  total: number;
};

export type ReportDetail = {
  id: string;
  source: string;
  event_id: string | null;
  latitude: number;
  longitude: number;
  description: string;
  disaster_type: string;
  people_count: number | null;
  injuries: boolean;
  weather_severity: number | null;
  created_at: string;
};

export type HealthAdviceRequest = {
  symptoms: string;
};

export type HealthAdviceResponse = {
  severity: "low" | "medium" | "high";
  steps: string[];
  medicines: string[];
};

export type ResponderApiRecord = {
  id: string;
  name: string;
  type: "ambulance" | "police" | "fire" | "volunteer";
  phone: string;
  latitude: number;
  longitude: number;
  availability: "ready" | "en_route" | "deployed" | "offline";
  current_status: string;
  eta_minutes: number;
  updated_at: string;
};

function toNumber(input: unknown, fallback = 0): number {
  const value = Number(input);
  return Number.isFinite(value) ? value : fallback;
}

function mapUnknownResponder(
  record: Record<string, unknown>,
): ResponderApiRecord {
  const id = String(
    record.id ?? record.responder_id ?? record.unit_id ?? "unknown",
  );
  const typeRaw = String(
    record.type ?? record.unit_type ?? "volunteer",
  ).toLowerCase();
  const type: ResponderApiRecord["type"] =
    typeRaw === "ambulance" ||
    typeRaw === "police" ||
    typeRaw === "fire" ||
    typeRaw === "volunteer"
      ? typeRaw
      : "volunteer";

  const availabilityRaw = String(
    record.availability ?? record.status ?? record.current_status ?? "ready",
  ).toLowerCase();
  const availability: ResponderApiRecord["availability"] =
    availabilityRaw === "deployed"
      ? "deployed"
      : availabilityRaw === "en_route" || availabilityRaw === "en route"
        ? "en_route"
        : availabilityRaw === "offline"
          ? "offline"
          : "ready";

  return {
    id,
    name: String(record.name ?? record.unit_name ?? `Unit ${id}`),
    type,
    phone: String(record.phone ?? record.contact ?? "N/A"),
    latitude: toNumber(record.latitude ?? record.lat),
    longitude: toNumber(record.longitude ?? record.lng),
    availability,
    current_status: String(
      record.current_status ?? record.status ?? "Available",
    ),
    eta_minutes: toNumber(record.eta_minutes ?? record.eta ?? 0),
    updated_at: String(record.updated_at ?? new Date().toISOString()),
  };
}

export type CreateResponderRequest = {
  name: string;
  type: "ambulance" | "police" | "fire" | "volunteer";
  phone: string;
  latitude: number;
  longitude: number;
  availability: "ready" | "en_route" | "deployed" | "offline";
};

export type UpdateResponderRequest = {
  availability?: "ready" | "en_route" | "deployed" | "offline";
  current_status?: string;
  eta_minutes?: number;
};

export type UpdateResponderLocationRequest = {
  latitude: number;
  longitude: number;
  speed_kmph?: number;
};

export type NearbyResponderRecord = {
  id: string;
  name: string;
  type: "ambulance" | "police" | "fire" | "volunteer";
  distance_km: number;
  eta_minutes: number;
  availability: "ready" | "en_route" | "deployed" | "offline";
};

export type IncidentLiveRecord = {
  incident_id: string;
  type: string;
  status: "pending" | "assigned" | "resolved" | "escalated";
  priority: "low" | "medium" | "high" | "critical";
  latitude: number;
  longitude: number;
  created_at: string;
};

export type UpdateIncidentStatusRequest = {
  status: "pending" | "assigned" | "resolved" | "escalated";
};

export type AssignIncidentRequest = {
  responder_id: string;
  assigned_by: string;
  note?: string;
};

export type AssignIncidentResponse = {
  message: string;
  incident_id: string;
  responder_id: string;
  status: "assigned" | "pending" | "resolved" | "escalated";
  distance_km: number;
  eta_minutes: number;
};

export type DispatchOptimizeRequest = {
  incident_id: string;
  latitude: number;
  longitude: number;
  required_unit: "ambulance" | "police" | "fire";
};

export type DispatchOptimizeResponse = {
  selected_responder: {
    id: string;
    name: string;
    distance_km: number;
    eta_minutes: number;
  };
  alternates: Array<{
    id: string;
    eta_minutes: number;
    distance_km: number;
  }>;
  hospital_recommendation: {
    name: string;
    distance_km: number;
    capacity_status: string;
  };
};

export type AiInsightsSummaryResponse = {
  top_prediction: string;
  high_risk_zones: number;
  recommended_actions: string[];
  model_version: string;
};

export type AiInsightsAction = {
  id: string;
  urgency: "Immediate" | "Watch" | "Monitor";
  owner: string;
  action: string;
};

export type ReportCreateRequest = {
  source: string;
  latitude: number;
  longitude: number;
  disaster_type: string;
  description?: string;
  people_count: number;
  injuries: boolean;
  weather_severity: number;
};

export type ReportCreateResponse = {
  report_id: string;
  event_id: string;
  confidence: number;
};

export type EventDetailResponse = {
  id: string;
  type: string;
  confidence: number;
  severity: "low" | "medium" | "high";
  active: boolean;
  latitude: number;
  longitude: number;
  created_at?: string;
  reports: ReportDetail[];
  report_count: number;
};

export type GridCell = {
  grid_lat: number;
  grid_lng: number;
  risk_score: number;
  distance_km?: number;
  [key: string]: unknown;
};

export type Prediction = {
  event_id: string;
  warning: string;
  triggers: string[];
  confidence: number;
  severity: "low" | "medium" | "high";
  latitude: number;
  longitude: number;
  generated_at: string;
};

export type SimulationSpreadResponse = {
  event_id: string;
  cells_affected: number;
  spread_data: Array<{
    grid_lat: number;
    grid_lng: number;
    risk_score: number;
  }>;
};

export type SimulationCompareResponse = {
  resqnet: { unit: string; distance_km: number; eta_minutes: number };
  naive: { unit: string; distance_km: number; eta_minutes: number };
  time_saved_minutes: number;
  projected_casualties_avoided: number;
  impact_summary: string;
};

export type DashboardStatsResponse = {
  events: {
    total: number;
    active: number;
    high_severity: number;
    [key: string]: unknown;
  };
  reports: {
    total: number;
    last_24h: number;
    by_source: Record<string, number>;
    [key: string]: unknown;
  };
  rescue_units: {
    total: number;
    available: number;
    busy: number;
    [key: string]: unknown;
  };
};

export type ExternalIngestRequest = {
  source: "news" | "social" | "weather";
  latitude: number;
  longitude: number;
  disaster_type: string;
  severity_score: number;
  description?: string;
};

export type ExternalIngestResponse = {
  message: string;
  event_id: string;
};

export type ExternalBulkIngestResponse = {
  ingested: number;
  results: ExternalIngestResponse[];
};

export type UploadMediaResponse = {
  url: string;
  file_name: string;
  latitude: number;
  longitude: number;
  disaster_type: string;
  size_mb?: number;
  report_id?: string;
  message: string;
};

export type SocialConfirmEventRequest = {
  latitude: number;
  longitude: number;
  user_id?: string;
};

export type SocialConfirmEventResponse = {
  message: string;
  event_id: string;
  new_confidence: number;
};

export type SocialObserveRequest = {
  latitude: number;
  longitude: number;
  disaster_type: string;
  observation: string;
  user_id?: string;
};

export type SocialObserveResponse = {
  message: string;
  report_id: string;
  event_id: string;
  confidence: number;
};

export type SocialFeedEvent = {
  id: string;
  type: string;
  confidence: number;
  severity: "low" | "medium" | "high";
  active: boolean;
  latitude: number;
  longitude: number;
  distance_km: number;
  confirmations: number;
  [key: string]: unknown;
};

export type SocialEventConfirmationsResponse = {
  event_id: string;
  confirmation_count: number;
  confirmations: Array<{
    id: string;
    latitude: number;
    longitude: number;
    created_at: string;
  }>;
};

export type RescueUnitRecord = {
  id: string;
  name: string;
  status: "available" | "busy";
  assigned_event_id?: string | null;
  [key: string]: unknown;
};

export type RescueAllocateRequest = {
  event_id: string;
};

export type RescueAllocateResponse = {
  unit_id: string;
  unit_name: string;
  event_id: string;
  distance_km: number;
  eta_minutes: number;
  message: string;
};

export type RescueUnitStatusResponse = {
  message: string;
};

export type WhatsAppStatusResponse = {
  configured: boolean;
  whatsapp_number: string;
  broadcast_reach: number;
};

export type WhatsappTriageRequest = {
  phone: string;
  message: string;
  latitude?: number;
  longitude?: number;
  language?: string;
};

export type WhatsappTriageResponse = {
  phone: string;
  latitude?: number;
  longitude?: number;
  triage: {
    severity: "low" | "medium" | "high";
    steps: string[];
    medicines: string[];
    dispatch_recommended: boolean;
    confidence: number;
    language: string;
  };
};

export type WhatsappTriageEscalateRequest = {
  phone: string;
  triage_result: Record<string, unknown>;
  latitude: number;
  longitude: number;
};

export type WhatsappTriageEscalateResponse = {
  incident_id: string;
  status: "assigned" | "pending";
  reply_text: string;
  responder: Record<string, unknown> | null;
};

export type RegisterDeviceRequest = {
  user_id: string;
  device_type: "phone" | "watch" | "nfc_tag";
  device_id: string;
  platform: "android" | "ios" | "wearos" | "watchos";
  push_token?: string;
};

export type RegisterDeviceResponse = {
  message: string;
  device_record_id: string;
};

export type FallDetectedRequest = {
  user_id: string;
  device_id: string;
  event_time: string;
  latitude: number;
  longitude: number;
  impact_score: number;
  heart_rate: number;
};

export type HeartAlertRequest = {
  user_id: string;
  device_id: string;
  heart_rate: number;
  latitude: number;
  longitude: number;
  event_time?: string;
};

export type WearableAlertResponse = {
  message: string;
  incident_id: string;
  status: "assigned" | "pending";
};

export type ConfidenceScoreRequest = {
  event_id?: string;
  report_counts?: Record<string, number>;
  source_entropy?: number;
  local_grid_risk_score?: number;
  weather_severity?: number;
  nearby_ready_responders?: number;
  eonet_event_count_24h?: number;
};

export type ConfidenceScoreResponse = {
  model_version: string;
  base_confidence: number;
  confidence: number;
  reasons: string[];
  fallback_used: boolean;
};

import {
  isNgrokHostname,
  NGROK_SKIP_BROWSER_WARNING_HEADER,
  NGROK_SKIP_BROWSER_WARNING_VALUE,
  normalizeBackendBaseUrlFromEnv,
} from "@/lib/backend-origin";

function getBaseUrl(): string {
  if (typeof window !== "undefined") {
    return "/api/backend";
  }
  return normalizeBackendBaseUrlFromEnv(
    process.env.NEXT_PUBLIC_RESQNET_API_BASE_URL,
  );
}

export function getApiBaseUrl(): string {
  return getBaseUrl();
}

async function apiJson<T>(
  path: string,
  init?: RequestInit,
  contentType: "application/json" | "none" = "application/json",
): Promise<T> {
  const headers: Record<string, string> = {};
  const inputHeaders = init?.headers;

  if (inputHeaders instanceof Headers) {
    inputHeaders.forEach((value, key) => {
      headers[key] = value;
    });
  } else if (Array.isArray(inputHeaders)) {
    for (const [key, value] of inputHeaders) {
      headers[key] = String(value);
    }
  } else if (inputHeaders && typeof inputHeaders === "object") {
    Object.entries(inputHeaders).forEach(([key, value]) => {
      if (typeof value !== "undefined") {
        headers[key] = String(value);
      }
    });
  }

  const hasContentType = Object.keys(headers).some(
    (key) => key.toLowerCase() === "content-type",
  );
  if (contentType === "application/json" && !hasContentType) {
    headers["Content-Type"] = "application/json";
  }

  let response: Response;
  try {
    response = await fetch(`${getBaseUrl()}${path}`, {
      ...init,
      headers,
    });
  } catch (error) {
    throw new Error(
      `Network error calling ${path}: ${(error as Error).message}`,
    );
  }

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(
      `API ${path} failed (${response.status}): ${errorText || response.statusText}`,
    );
  }

  return response.json() as Promise<T>;
}

function coalesceArrayPayload(raw: unknown): unknown[] {
  if (Array.isArray(raw)) return raw;
  if (raw && typeof raw === "object") {
    const o = raw as Record<string, unknown>;
    for (const key of [
      "incidents",
      "data",
      "results",
      "items",
      "records",
      "sos",
      "rows",
    ]) {
      const v = o[key];
      if (Array.isArray(v)) return v;
    }
  }
  return [];
}

function normalizeIncidentLiveStatus(
  raw: unknown,
): IncidentLiveRecord["status"] {
  const v = String(raw ?? "pending").toLowerCase();
  if (
    v === "resolved" ||
    v === "escalated" ||
    v === "assigned" ||
    v === "pending"
  )
    return v;
  return "pending";
}

function normalizeIncidentLivePriority(
  raw: unknown,
): IncidentLiveRecord["priority"] {
  const v = String(raw ?? "medium").toLowerCase();
  if (v === "low" || v === "medium" || v === "high" || v === "critical")
    return v;
  return "medium";
}

function normalizeIncidentLiveRow(
  row: Record<string, unknown>,
): IncidentLiveRecord | null {
  const incident_id = String(
    row.incident_id ?? row.id ?? row.incidentId ?? row.event_id ?? "",
  ).trim();
  if (!incident_id || incident_id === "undefined") return null;

  const type = String(row.type ?? row.incident_type ?? "sos").toLowerCase();

  return {
    incident_id,
    type,
    status: normalizeIncidentLiveStatus(row.status),
    priority: normalizeIncidentLivePriority(row.priority),
    latitude: toNumber(row.latitude ?? row.lat),
    longitude: toNumber(row.longitude ?? row.lng),
    created_at: String(
      row.created_at ?? row.createdAt ?? new Date().toISOString(),
    ),
  };
}

function mergeIncidentLiveFeeds(
  fromLive: IncidentLiveRecord[],
  fromSos: IncidentLiveRecord[],
): IncidentLiveRecord[] {
  const map = new Map<string, IncidentLiveRecord>();
  for (const row of fromSos) {
    map.set(row.incident_id, row);
  }
  for (const row of fromLive) {
    const prev = map.get(row.incident_id);
    map.set(row.incident_id, prev ? { ...prev, ...row } : row);
  }
  return Array.from(map.values());
}

async function fetchIncidentsLiveEndpoint(): Promise<IncidentLiveRecord[]> {
  try {
    const raw = await apiJson<unknown>("/incidents/live");
    return coalesceArrayPayload(raw)
      .map((item) => normalizeIncidentLiveRow(item as Record<string, unknown>))
      .filter((x): x is IncidentLiveRecord => x != null);
  } catch {
    return [];
  }
}

/** After GET /sos returns 405/404, skip further list fetches (backend is POST-only or missing list route). */
let sosListGetSupported: boolean | null = null;

// GET /sos is not in the backend spec (only POST /sos exists)
async function fetchSosIncidentRows(): Promise<IncidentLiveRecord[]> {
  return [];
}

export function authSignup(
  payload: AuthSignupRequest,
): Promise<AuthSignupResponse> {
  return apiJson<AuthSignupResponse>("/auth/signup", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function authLogin(
  payload: AuthLoginRequest,
): Promise<AuthLoginResponse> {
  return apiJson<AuthLoginResponse>("/auth/login", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function authLogout(): Promise<AuthLogoutResponse> {
  return apiJson<AuthLogoutResponse>("/auth/logout", { method: "POST" });
}

export function sendOtp(payload: SendOtpRequest): Promise<SendOtpResponse> {
  return apiJson<SendOtpResponse>("/auth/phone/send-otp", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function verifyOtp(
  payload: VerifyOtpRequest,
): Promise<VerifyOtpResponse> {
  return apiJson<VerifyOtpResponse>("/auth/phone/verify-otp", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function fetchNfcProfile(userId: string): Promise<NfcProfileResponse> {
  return apiJson<NfcProfileResponse>(
    `/nfc/profile/${encodeURIComponent(userId)}`,
  );
}

/** Server-friendly: returns `null` on 404; throws on other HTTP or network errors. */
export async function fetchNfcProfileOrNull(
  userId: string,
): Promise<NfcProfileResponse | null> {
  const path = `/nfc/profile/${encodeURIComponent(userId)}`;
  let response: Response;
  try {
    response = await fetch(`${getBaseUrl()}${path}`, {
      headers: { accept: "application/json" },
      next: { revalidate: 0 },
    });
  } catch (error) {
    throw new Error(
      `Network error calling ${path}: ${(error as Error).message}`,
    );
  }
  if (response.status === 404) return null;
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(
      `API ${path} failed (${response.status}): ${errorText || response.statusText}`,
    );
  }
  return response.json() as Promise<NfcProfileResponse>;
}

export function listNfcScans(params?: {
  limit?: number;
  card_user_id?: string;
}): Promise<NfcScanListResponse> {
  const query = new URLSearchParams();
  if (params?.limit != null) query.set("limit", String(params.limit));
  if (params?.card_user_id) query.set("card_user_id", params.card_user_id);
  const suffix = query.toString() ? `?${query.toString()}` : "";
  return apiJson<NfcScanListResponse>(`/nfc/scans${suffix}`);
}

export function ingestNfcScan(
  payload: NfcScanIngestRequest,
): Promise<NfcScanRecord> {
  return apiJson<NfcScanRecord>("/nfc/scans", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function createSos(payload: SosRequest): Promise<SosResponse> {
  return apiJson<SosResponse>("/sos", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export async function fetchEvents(params?: {
  active_only?: boolean;
  limit?: number;
  severity?: string;
}): Promise<ApiEvent[]> {
  const query = new URLSearchParams();
  if (params?.active_only != null)
    query.set("active_only", String(params.active_only));
  if (params?.limit != null) query.set("limit", String(params.limit));
  if (params?.severity) query.set("severity", params.severity);
  const suffix = query.toString() ? `?${query.toString()}` : "";

  const events = await apiJson<Array<Record<string, unknown>>>(
    `/events${suffix}`,
  );

  return events.map((event) => ({
    id: String(event.id),
    type: String(event.type ?? "unknown"),
    source: typeof event.source === "string" ? event.source : undefined,
    description:
      typeof event.description === "string" ? event.description : undefined,
    latitude: Number(event.latitude ?? 0),
    longitude: Number(event.longitude ?? 0),
    confidence: Number(event.confidence ?? 0),
    severity: (event.severity as "low" | "medium" | "high") ?? "low",
    source_breakdown: {
      app: Number(
        (event.source_breakdown as Record<string, unknown>)?.app ?? 0,
      ),
      whatsapp: Number(
        (event.source_breakdown as Record<string, unknown>)?.whatsapp ?? 0,
      ),
      news: Number(
        (event.source_breakdown as Record<string, unknown>)?.news ?? 0,
      ),
      social: Number(
        (event.source_breakdown as Record<string, unknown>)?.social ?? 0,
      ),
    },
    weather_severity: Number(event.weather_severity ?? 0),
    active: Boolean(event.active),
    created_at: String(event.created_at ?? new Date().toISOString()),
  }));
}

export function createReport(
  payload: ReportCreateRequest,
): Promise<ReportCreateResponse> {
  return apiJson<ReportCreateResponse>("/reports", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function fetchReports(params?: {
  limit?: number;
  source?: string;
  event_id?: string;
}): Promise<ReportDetail[]> {
  const query = new URLSearchParams();
  if (params?.limit != null) query.set("limit", String(params.limit));
  if (params?.source) query.set("source", params.source);
  if (params?.event_id) query.set("event_id", params.event_id);
  const suffix = query.toString() ? `?${query.toString()}` : "";
  return apiJson<ReportDetail[]>(`/reports${suffix}`);
}

export function fetchReport(reportId: string): Promise<ReportDetail> {
  return apiJson<ReportDetail>(`/reports/${reportId}`);
}

export function fetchEventById(eventId: string): Promise<EventDetailResponse> {
  return apiJson<EventDetailResponse>(`/events/${eventId}`);
}

export function resolveEvent(
  eventId: string,
): Promise<{ message: "Event resolved" }> {
  return apiJson<{ message: "Event resolved" }>(`/events/${eventId}/resolve`, {
    method: "PATCH",
  });
}

export function fetchNearbyEvents(
  lat: number,
  lng: number,
  radius_km = 3,
): Promise<Array<Record<string, unknown>>> {
  const query = new URLSearchParams({
    lat: String(lat),
    lng: String(lng),
    radius_km: String(radius_km),
  });
  return apiJson<Array<Record<string, unknown>>>(
    `/events/nearby?${query.toString()}`,
  );
}

export function fetchGrid(min_risk?: number): Promise<GridCell[]> {
  const query = new URLSearchParams();
  if (min_risk != null) query.set("min_risk", String(min_risk));
  const suffix = query.toString() ? `?${query.toString()}` : "";
  return apiJson<GridCell[]>(`/grid${suffix}`);
}

export function fetchNearbyGrid(
  lat: number,
  lng: number,
  radius_km: number,
): Promise<GridCell[]> {
  const query = new URLSearchParams({
    lat: String(lat),
    lng: String(lng),
    radius_km: String(radius_km),
  });
  return apiJson<GridCell[]>(`/grid/nearby?${query.toString()}`);
}

export function fetchPredictions(): Promise<Prediction[]> {
  return apiJson<Prediction[]>("/predictions");
}

export function simulateSpread(
  event_id: string,
): Promise<SimulationSpreadResponse> {
  return apiJson<SimulationSpreadResponse>("/simulation/spread", {
    method: "POST",
    body: JSON.stringify({ event_id }),
  });
}

export function compareSimulation(
  event_id: string,
): Promise<SimulationCompareResponse> {
  return apiJson<SimulationCompareResponse>("/simulation/compare", {
    method: "POST",
    body: JSON.stringify({ event_id }),
  });
}

export function fetchDashboardStats(): Promise<DashboardStatsResponse> {
  return apiJson<DashboardStatsResponse>("/dashboard/stats");
}

export function fetchDashboardFeed(limit = 20): Promise<DashboardFeedResponse> {
  const query = new URLSearchParams({ limit: String(limit) });
  return apiJson<DashboardFeedResponse>(`/dashboard/feed?${query.toString()}`);
}

export function ingestExternal(
  payload: ExternalIngestRequest,
): Promise<ExternalIngestResponse> {
  return apiJson<ExternalIngestResponse>("/external/ingest", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function ingestExternalBulk(
  payload: ExternalIngestRequest[],
): Promise<ExternalBulkIngestResponse> {
  return apiJson<ExternalBulkIngestResponse>("/external/ingest/bulk", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export async function uploadMedia(payload: {
  file: File;
  latitude: number;
  longitude: number;
  disaster_type: string;
  report_id?: string;
  user_id?: string;
}): Promise<UploadMediaResponse> {
  const formData = new FormData();
  formData.append("file", payload.file);
  formData.append("latitude", String(payload.latitude));
  formData.append("longitude", String(payload.longitude));
  formData.append("disaster_type", payload.disaster_type);
  if (payload.report_id) formData.append("report_id", payload.report_id);
  if (payload.user_id) formData.append("user_id", payload.user_id);

  return apiJson<UploadMediaResponse>(
    "/media/upload",
    { method: "POST", body: formData },
    "none",
  );
}

export async function fetchDisasterPhotos(params?: {
  disaster_type?: string;
  limit?: number;
}): Promise<DisasterPhoto[]> {
  const query = new URLSearchParams();
  if (params?.disaster_type) query.set("disaster_type", params.disaster_type);
  if (params?.limit != null) query.set("limit", String(params.limit));
  const suffix = query.toString() ? `?${query.toString()}` : "";

  const result = await apiJson<DisasterPhotosResponse>(`/media/list${suffix}`);
  return result.files.map((file) => ({
    id: file.name,
    url: file.url,
    label: file.disaster_type,
  }));
}

export type WeatherForecastPoint = {
  dt: number;
  dt_txt: string;
  main: {
    temp: number;
    feels_like: number;
  };
  weather: {
    id: number;
    main: string;
    description: string;
    icon: string;
  }[];
  wind: {
    speed: number;
  };
  rain?: {
    [key: string]: number;
  };
};

export type WeatherForecastResponse = {
  list: WeatherForecastPoint[];
};

export async function fetchWeatherForecast(
  lat: number,
  lon: number,
): Promise<WeatherForecastResponse> {
  const apiKey = process.env.NEXT_PUBLIC_OPENWEATHER_API;
  if (!apiKey) {
    throw new Error("OpenWeather API key not configured");
  }

  const params = new URLSearchParams({
    lat: String(lat),
    lon: String(lon),
    units: "metric",
    appid: apiKey,
  });

  const response = await fetch(
    `${OPENWEATHER_BASE_URL}/forecast?${params.toString()}`,
  );

  if (!response.ok) {
    throw new Error(`OpenWeather forecast failed with ${response.status}`);
  }

  return response.json() as Promise<WeatherForecastResponse>;
}

export function fetchNews(): Promise<NewsResponse> {
  return apiJson<NewsResponse>("/news").then((data) => ({
    ...data,
    articles: data.articles.map((article) => ({
      ...article,
      query: article.query ?? article.disaster_type ?? "signal",
    })),
  }));
}

export function fetchHealthAdvice(
  payload: HealthAdviceRequest,
): Promise<HealthAdviceResponse> {
  return apiJson<HealthAdviceResponse>("/health/advice", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function fetchWhatsappStatus(): Promise<WhatsAppStatusResponse> {
  return apiJson<WhatsAppStatusResponse>("/whatsapp/status");
}

export function whatsappTriage(
  payload: WhatsappTriageRequest,
): Promise<WhatsappTriageResponse> {
  return apiJson<WhatsappTriageResponse>("/whatsapp/triage", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function whatsappTriageEscalate(
  payload: WhatsappTriageEscalateRequest,
): Promise<WhatsappTriageEscalateResponse> {
  return apiJson<WhatsappTriageEscalateResponse>("/whatsapp/triage/escalate", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function registerDevice(
  payload: RegisterDeviceRequest,
): Promise<RegisterDeviceResponse> {
  return apiJson<RegisterDeviceResponse>("/devices/register", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function reportFallDetected(
  payload: FallDetectedRequest,
): Promise<WearableAlertResponse> {
  return apiJson<WearableAlertResponse>("/wearables/wearables/fall-detected", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function reportHeartAlert(
  payload: HeartAlertRequest,
): Promise<WearableAlertResponse> {
  return apiJson<WearableAlertResponse>("/wearables/wearables/heart-alert", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function fetchResponders(params?: {
  availability?: "ready" | "en_route" | "deployed" | "offline";
  type?: "ambulance" | "police" | "fire" | "volunteer";
  limit?: number;
}): Promise<ResponderApiRecord[]> {
  const buildPath = (input?: {
    availability?: "ready" | "en_route" | "deployed" | "offline";
    type?: "ambulance" | "police" | "fire" | "volunteer";
    limit?: number;
  }) => {
    const query = new URLSearchParams();
    if (input?.availability) query.set("availability", input.availability);
    if (input?.type) query.set("type", input.type);
    if (input?.limit != null) query.set("limit", String(input.limit));
    const suffix = query.toString() ? `?${query.toString()}` : "";
    return `/responders${suffix}`;
  };

  const requestedPath = buildPath(params);
  const canRetryWithLowerLimit =
    typeof params?.limit === "number" && params.limit > 100;

  const parseList = (raw: unknown): ResponderApiRecord[] =>
    coalesceArrayPayload(raw).map((item) =>
      mapUnknownResponder(item as Record<string, unknown>),
    );

  const run = async (): Promise<ResponderApiRecord[]> => {
    try {
      const raw = await apiJson<unknown>(requestedPath);
      return parseList(raw);
    } catch (error) {
      try {
        if (canRetryWithLowerLimit) {
          const raw = await apiJson<unknown>(
            buildPath({ ...params, limit: 100 }),
          );
          return parseList(raw);
        }
      } catch {
        // Continue to retry without limit.
      }

      try {
        const raw = await apiJson<unknown>(
          buildPath({ availability: params?.availability, type: params?.type }),
        );
        return parseList(raw);
      } catch {
        console.error("Responder APIs unavailable", error);
        return [];
      }
    }
  };

  return run();
}

export function createResponder(
  payload: CreateResponderRequest,
): Promise<{ message: string; responder_id: string }> {
  return apiJson<{ message: string; responder_id: string }>("/responders", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function updateResponder(
  responderId: string,
  payload: UpdateResponderRequest,
): Promise<{ message: string }> {
  return apiJson<{ message: string }>(`/responders/${responderId}`, {
    method: "PATCH",
    body: JSON.stringify(payload),
  });
}

export function updateResponderLocation(
  responderId: string,
  payload: UpdateResponderLocationRequest,
): Promise<{ message: string; updated_at: string }> {
  return apiJson<{ message: string; updated_at: string }>(
    `/responders/${responderId}/location`,
    {
      method: "POST",
      body: JSON.stringify(payload),
    },
  );
}

export function fetchNearbyResponders(
  lat: number,
  lng: number,
  radius_km = 5,
): Promise<NearbyResponderRecord[]> {
  const query = new URLSearchParams({
    lat: String(lat),
    lng: String(lng),
    radius_km: String(radius_km),
  });
  return apiJson<NearbyResponderRecord[]>(
    `/responders/nearby?${query.toString()}`,
  );
}

export async function fetchLiveIncidents(options?: {
  /** When false, only `GET /incidents/live` is used (no merged SOS history). */
  includeSos?: boolean;
}): Promise<IncidentLiveRecord[]> {
  const includeSos = options?.includeSos !== false;
  const [fromLive, fromSos] = await Promise.all([
    fetchIncidentsLiveEndpoint(),
    includeSos ? fetchSosIncidentRows() : Promise.resolve([]),
  ]);
  return mergeIncidentLiveFeeds(fromLive, fromSos);
}

export function updateIncidentStatus(
  incidentId: string,
  payload: UpdateIncidentStatusRequest,
): Promise<{ message: string }> {
  return apiJson<{ message: string }>(`/incidents/${incidentId}/status`, {
    method: "PATCH",
    body: JSON.stringify(payload),
  });
}

export function assignIncident(
  incidentId: string,
  payload: AssignIncidentRequest,
): Promise<AssignIncidentResponse> {
  return apiJson<AssignIncidentResponse>(`/incidents/${incidentId}/assign`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function optimizeDispatch(
  payload: DispatchOptimizeRequest,
): Promise<DispatchOptimizeResponse> {
  return apiJson<DispatchOptimizeResponse>("/dispatch/optimize", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function fetchAiInsightsSummary(): Promise<AiInsightsSummaryResponse> {
  return apiJson<AiInsightsSummaryResponse>("/ai/insights/summary");
}

export function fetchAiInsightsActions(
  limit = 10,
): Promise<AiInsightsAction[]> {
  const query = new URLSearchParams({ limit: String(limit) });
  return apiJson<AiInsightsAction[]>(
    `/ai/insights/actions?${query.toString()}`,
  );
}

export function scoreConfidence(
  payload: ConfidenceScoreRequest,
): Promise<ConfidenceScoreResponse> {
  const query = new URLSearchParams();
  if (payload.event_id) query.set("event_id", payload.event_id);
  if (payload.local_grid_risk_score != null) query.set("local_grid_risk_score", String(payload.local_grid_risk_score));
  if (payload.weather_severity != null) query.set("weather_severity", String(payload.weather_severity));
  if (payload.nearby_ready_responders != null) query.set("nearby_ready_responders", String(payload.nearby_ready_responders));
  if (payload.eonet_event_count_24h != null) query.set("eonet_event_count_24h", String(payload.eonet_event_count_24h));
  if (payload.source_entropy != null) query.set("source_entropy", String(payload.source_entropy));
  const suffix = query.toString() ? `?${query.toString()}` : "";
  return apiJson<ConfidenceScoreResponse>(`/ml/confidence/score${suffix}`);
}

export function confirmSocialEvent(
  eventId: string,
  payload: SocialConfirmEventRequest,
): Promise<SocialConfirmEventResponse> {
  return apiJson<SocialConfirmEventResponse>(
    `/social/events/${eventId}/confirm`,
    {
      method: "POST",
      body: JSON.stringify(payload),
    },
  );
}

export function postSocialObservation(
  payload: SocialObserveRequest,
): Promise<SocialObserveResponse> {
  return apiJson<SocialObserveResponse>("/social/observe", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function fetchSocialFeed(
  lat: number,
  lng: number,
  radius_km = 10,
): Promise<SocialFeedEvent[]> {
  const query = new URLSearchParams({
    lat: String(lat),
    lng: String(lng),
    radius_km: String(radius_km),
  });
  return apiJson<SocialFeedEvent[]>(`/social/feed?${query.toString()}`);
}

export function fetchSocialEventConfirmations(
  eventId: string,
): Promise<SocialEventConfirmationsResponse> {
  return apiJson<SocialEventConfirmationsResponse>(
    `/social/events/${eventId}/confirmations`,
  );
}

export function fetchRescueUnits(
  status?: "available" | "busy",
): Promise<RescueUnitRecord[]> {
  const query = new URLSearchParams();
  if (status) query.set("status", status);
  const suffix = query.toString() ? `?${query.toString()}` : "";
  return apiJson<RescueUnitRecord[]>(`/rescue/units${suffix}`);
}

export function allocateRescueUnit(
  payload: RescueAllocateRequest,
): Promise<RescueAllocateResponse> {
  return apiJson<RescueAllocateResponse>("/rescue/allocate", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function updateRescueUnitStatus(
  unitId: string,
  status: "available" | "busy",
): Promise<RescueUnitStatusResponse> {
  const query = new URLSearchParams({ status });
  return apiJson<RescueUnitStatusResponse>(
    `/rescue/units/${unitId}/status?${query.toString()}`,
    {
      method: "PATCH",
    },
  );
}

/* ── NASA EONET ────────────────────────────────────────────────────────────── */

export type EonetCategory = {
  id: string;
  title: string;
};

export type EonetGeometry = {
  date: string;
  type: "Point" | "Polygon";
  coordinates: number[] | number[][][];
};

export type EonetEvent = {
  id: string;
  title: string;
  description: string | null;
  link: string;
  closed: string | null;
  categories: EonetCategory[];
  sources: { id: string; url: string }[];
  geometry: EonetGeometry[];
};

export type EonetResponse = {
  title: string;
  description: string;
  link: string;
  events: EonetEvent[];
};

export async function fetchEonetEvents(params?: {
  days?: number;
  limit?: number;
  status?: "open" | "closed" | "all";
}): Promise<EonetEvent[]> {
  const query = new URLSearchParams();
  query.set("days", String(params?.days ?? 365));
  query.set("limit", String(params?.limit ?? 1000));
  if (params?.status && params.status !== "all")
    query.set("status", params.status);

  const res = await fetch(
    `https://eonet.gsfc.nasa.gov/api/v3/events?${query.toString()}`,
    { next: { revalidate: 300 } },
  );
  if (!res.ok) throw new Error(`EONET ${res.status}`);
  const data = (await res.json()) as EonetResponse;
  return data.events;
}

/** Fetch both open + recently closed EONET events merged and deduplicated */
export async function fetchAllEonetEvents(): Promise<EonetEvent[]> {
  const [openRes, closedRes] = await Promise.allSettled([
    fetchEonetEvents({ status: "open", limit: 1000, days: 365 }),
    fetchEonetEvents({ status: "closed", limit: 1000, days: 180 }),
  ]);

  const open = openRes.status === "fulfilled" ? openRes.value : [];
  const closed = closedRes.status === "fulfilled" ? closedRes.value : [];

  const seen = new Set<string>();
  const merged: EonetEvent[] = [];
  for (const ev of [...open, ...closed]) {
    if (!seen.has(ev.id)) {
      seen.add(ev.id);
      merged.push(ev);
    }
  }
  return merged;
}
