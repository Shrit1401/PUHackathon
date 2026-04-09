import {
  ActivityLogEntry,
  DisasterEvent,
  SeverityLevel,
  SourceBreakdown,
} from "./types";

export const INDIA_CENTER: [number, number] = [22.5937, 78.9629];

export function getSourceBreakdown(event: DisasterEvent): SourceBreakdown {
  return {
    newsSignals: event.newsCount,
    socialPosts: event.socialCount,
    appReports: event.userReports,
    whatsappReports: event.whatsappReports,
    weatherSeverity: event.weatherSeverity,
  };
}

export function getSeverityColor(severity: SeverityLevel): string {
  if (severity === "high") return "#ef4444";
  if (severity === "medium") return "#f59e0b";
  return "#22c55e";
}

export function getSeverityLabel(severity: SeverityLevel): string {
  if (severity === "high") return "High";
  if (severity === "medium") return "Medium";
  return "Low";
}

export function getWeatherSeverityLabel(score: number): string {
  if (score >= 7.5) return "High";
  if (score >= 4) return "Moderate";
  return "Low";
}

