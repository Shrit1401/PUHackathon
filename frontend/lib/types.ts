export type SeverityLevel = "high" | "medium" | "low";

export type ConfidenceTrend = {
  time: string;
  score: number;
};

export type DisasterEvent = {
  id: string;
  type: string;
  name: string;
  createdAt?: string;
  location: {
    label: string;
    lat: number;
    lng: number;
  };
  severity: SeverityLevel;
  confidenceScore: number;
  socialCount: number;
  newsCount: number;
  userReports: number;
  whatsappReports: number;
  weatherSeverity: number;
  confidenceTrend?: ConfidenceTrend[];
};

export type SourceBreakdown = {
  newsSignals: number;
  socialPosts: number;
  appReports: number;
  whatsappReports: number;
  weatherSeverity: number;
};

export type ActivityLogEntry = {
  id: string;
  timestamp: string;
  message: string;
  reportId?: string;
  eventId?: string;
};

export type SignalSource = "News" | "Social" | "App" | "WhatsApp";

export type SignalSheetRow = {
  id: string;
  timestamp: string;
  source: SignalSource;
  zone: string;
  detail: string;
  severity: SeverityLevel;
};

export type SourceTrendPoint = {
  time: string;
  news: number;
  social: number;
  app: number;
  whatsapp: number;
};
