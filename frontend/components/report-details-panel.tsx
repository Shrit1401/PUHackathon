import { MapPin, X } from "lucide-react";
import type { ReportDetail } from "../lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";

type ReportDetailsPanelProps = {
  report?: ReportDetail | null;
  loading: boolean;
  onClose: () => void;
};

export function ReportDetailsPanel({ report, loading, onClose }: ReportDetailsPanelProps) {
  if (!report && !loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Report Details</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-slate-400">Select a report from the activity feed to inspect it.</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0">
        <CardTitle>Report Details</CardTitle>
        <Button size="icon" variant="ghost" onClick={onClose}>
          <X className="h-4 w-4" />
        </Button>
      </CardHeader>
      <CardContent className="space-y-3">
        {loading ? (
          <p className="text-sm text-slate-400">Loading report...</p>
        ) : report ? (
          <>
            <div>
              <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Source</p>
              <p className="text-sm font-medium text-slate-100">{report.source}</p>
            </div>
            <div>
              <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Disaster Type</p>
              <p className="text-sm font-medium text-slate-100">{report.disaster_type}</p>
            </div>
            <div>
              <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Description</p>
              <p className="text-sm text-slate-200">{report.description}</p>
            </div>
            <div className="flex items-center gap-2">
              <MapPin className="h-3.5 w-3.5 text-sky-400" />
              <p className="text-xs font-mono text-slate-300">
                {report.latitude.toFixed(4)}, {report.longitude.toFixed(4)}
              </p>
            </div>
            <div className="grid grid-cols-2 gap-3 text-sm">
              <div>
                <p className="text-xs uppercase tracking-[0.16em] text-slate-500">People Count</p>
                <p className="font-mono text-slate-100">
                  {report.people_count != null ? report.people_count : "Unknown"}
                </p>
              </div>
              <div>
                <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Injuries</p>
                <p className="font-mono text-slate-100">{report.injuries ? "Reported" : "Not Reported"}</p>
              </div>
            </div>
            <div>
              <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Linked Event</p>
              <p className="text-xs font-mono text-slate-300">{report.event_id ?? "Not linked"}</p>
            </div>
            <div>
              <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Reported At</p>
              <p className="text-xs font-mono text-slate-300">
                {new Date(report.created_at).toLocaleString("en-IN", {
                  hour12: false,
                  day: "2-digit",
                  month: "short",
                  year: "numeric",
                  hour: "2-digit",
                  minute: "2-digit",
                  second: "2-digit",
                })}
              </p>
            </div>
          </>
        ) : null}
      </CardContent>
    </Card>
  );
}

