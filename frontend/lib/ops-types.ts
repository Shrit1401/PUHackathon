export type OpsStatus = "Pending" | "Assigned" | "Resolved" | "Escalated";

export type IncidentPriority = "Critical" | "High" | "Medium" | "Low";

export type IncidentRecord = {
  id: string;
  user: string;
  incidentType: string;
  isSos?: boolean;
  isLiveIncident?: boolean;
  status: OpsStatus;
  location: string;
  createdAt: string;
  createdAtRaw?: string;
  priority: IncidentPriority;
  confidence: number;
  lat: number;
  lng: number;
  summary: string;
  description?: string;
  assignedResponderId?: string;
  source?: "backend" | "eonet";
  eonetLink?: string;
};

export type ResponderAvailability = "Deployed" | "Ready" | "Offline" | "En Route";

export type ResponderRecord = {
  id: string;
  name: string;
  unit: string;
  specialization: string;
  availability: ResponderAvailability;
  currentStatus: string;
  eta: string;
  lat: number;
  lng: number;
};

export type DashboardTrend = "up" | "down" | "flat";

export type LiveSummary = {
  id: string;
  title: string;
  detail: string;
  level: "info" | "warning" | "critical";
  updatedAt: string;
};

export type RiskZone = {
  id: string;
  zone: string;
  riskScore: number;
  confidence: number;
  activeIncidents: number;
  recommendation: string;
};

export type Prediction = {
  id: string;
  horizon: string;
  statement: string;
  confidence: number;
  priority: 1 | 2 | 3 | 4 | 5;
};

export type SuggestedAction = {
  id: string;
  action: string;
  owner: string;
  urgency: "Immediate" | "Near-Term" | "Monitor";
};
