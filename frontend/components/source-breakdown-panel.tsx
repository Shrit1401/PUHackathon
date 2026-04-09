import {
  Newspaper,
  Smartphone,
  MessageSquareText,
  CloudRain,
} from "lucide-react";
import { SourceBreakdown } from "../lib/types";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Progress } from "./ui/progress";

type SourceBreakdownPanelProps = {
  breakdown: SourceBreakdown;
};

export function SourceBreakdownPanel({ breakdown }: SourceBreakdownPanelProps) {
  const total =
    breakdown.newsSignals + breakdown.appReports + breakdown.whatsappReports;

  const rows = [
    { label: "News Signals", value: breakdown.newsSignals, icon: Newspaper },
    { label: "App Reports", value: breakdown.appReports, icon: Smartphone },
    {
      label: "WhatsApp Reports",
      value: breakdown.whatsappReports,
      icon: MessageSquareText,
    },
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle>Source Breakdown</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {rows.map((row) => {
          const share = total > 0 ? Math.round((row.value / total) * 100) : 0;
          return (
            <div
              key={row.label}
              className="rounded-md border border-white/5 bg-[radial-gradient(circle_at_top,rgba(15,23,42,0.9),transparent_55%),linear-gradient(to_right,rgba(15,23,42,0.95),rgba(15,23,42,0.8))] p-3"
            >
              <div className="mb-2 flex items-center justify-between text-xs">
                <div className="flex items-center gap-2 text-slate-300">
                  <row.icon className="h-3.5 w-3.5" />
                  <span>{row.label}</span>
                </div>
                <span className="font-mono text-slate-400">{row.value}</span>
              </div>
              <Progress value={share} />
            </div>
          );
        })}

        <div className="rounded-md border border-white/5 bg-[radial-gradient(circle_at_top,rgba(59,130,246,0.32),transparent_55%),#020617] p-3">
          <div className="mb-2 flex items-center justify-between text-xs text-slate-300">
            <div className="flex items-center gap-2">
              <CloudRain className="h-3.5 w-3.5" />
              <span>Weather Severity</span>
            </div>
            <span className="font-mono text-slate-400">
              {breakdown.weatherSeverity.toFixed(1)}/10
            </span>
          </div>
          <Progress value={(breakdown.weatherSeverity / 10) * 100} />
        </div>
      </CardContent>
    </Card>
  );
}
