import {
  Bar,
  BarChart,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
  TooltipProps,
} from "recharts";
import { DisasterEvent } from "../lib/types";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";

type RiskDistributionPanelProps = {
  events: DisasterEvent[];
};

function PieTooltipContent({ active, payload }: TooltipProps<number, string>) {
  if (!active || !payload || payload.length === 0) return null;

  const item = payload[0];
  const name = (item.payload as { name: string }).name;
  const value = item.value;

  return (
    <div className="rounded-md border border-slate-700 bg-slate-950/95 px-3 py-2 text-xs text-slate-100 shadow-xl">
      <p className="font-medium">{name}</p>
      <p className="text-slate-400">Events: {value}</p>
    </div>
  );
}

function BarTooltipContent({ active, payload }: TooltipProps<number, string>) {
  if (!active || !payload || payload.length === 0) return null;

  const item = payload[0];
  const data = item.payload as { name: string; count: number };

  return (
    <div className="rounded-md border border-slate-700 bg-slate-950/95 px-3 py-2 text-xs text-slate-100 shadow-xl">
      <p className="font-medium">{data.name}</p>
      <p className="text-slate-400">Signals: {data.count}</p>
    </div>
  );
}

export function RiskDistributionPanel({ events }: RiskDistributionPanelProps) {
  const severityCounts = {
    high: events.filter((e) => e.severity === "high").length,
    medium: events.filter((e) => e.severity === "medium").length,
    low: events.filter((e) => e.severity === "low").length,
  };

  const pieData = [
    { name: "High", value: severityCounts.high, color: "#ef4444" },
    { name: "Medium", value: severityCounts.medium, color: "#f59e0b" },
    { name: "Low", value: severityCounts.low, color: "#22c55e" },
  ];

  const sourceData = [
    { name: "News", count: events.reduce((sum, e) => sum + e.newsCount, 0) },
    { name: "Social", count: events.reduce((sum, e) => sum + e.socialCount, 0) },
    { name: "App", count: events.reduce((sum, e) => sum + e.userReports, 0) },
    { name: "WhatsApp", count: events.reduce((sum, e) => sum + e.whatsappReports, 0) },
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle>Risk And Source Snapshot</CardTitle>
      </CardHeader>
      <CardContent className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div className="h-44 rounded-md border border-white/5 bg-[radial-gradient(circle_at_top,rgba(248,113,113,0.32),transparent_55%),#020617] p-2">
          <ResponsiveContainer width="100%" height="100%">
            <PieChart>
              <defs>
                <filter id="shadowPie" x="-50%" y="-50%" width="200%" height="200%">
                  <feDropShadow dx="0" dy="6" stdDeviation="10" floodColor="rgba(15,23,42,0.9)" />
                </filter>
              </defs>
              <Pie
                data={pieData}
                dataKey="value"
                nameKey="name"
                innerRadius={36}
                outerRadius={58}
                strokeWidth={2}
                style={{ filter: "url(#shadowPie)" }}
              >
                {pieData.map((entry) => (
                  <Cell key={entry.name} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip
                wrapperStyle={{ zIndex: 50 }}
                cursor={{ fill: "rgba(148, 163, 184, 0.12)" }}
                content={<PieTooltipContent />}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>

        <div className="h-44 rounded-md border border-white/5 bg-[radial-gradient(circle_at_top,rgba(56,189,248,0.32),transparent_55%),#020617] p-2">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={sourceData} margin={{ top: 8, right: 8, left: -20, bottom: 0 }}>
              <XAxis dataKey="name" tickLine={false} axisLine={false} tick={{ fill: "#94a3b8", fontSize: 11 }} />
              <YAxis tickLine={false} axisLine={false} tick={{ fill: "#94a3b8", fontSize: 11 }} />
              <Tooltip
                wrapperStyle={{ zIndex: 50 }}
                cursor={{ fill: "rgba(148, 163, 184, 0.12)" }}
                content={<BarTooltipContent />}
              />
              <defs>
                <linearGradient id="sourceBars" x1="0" x2="1" y1="0" y2="0">
                  <stop offset="0%" stopColor="#22c55e" />
                  <stop offset="50%" stopColor="#22d3ee" />
                  <stop offset="100%" stopColor="#8b5cf6" />
                </linearGradient>
              </defs>
              <Bar dataKey="count" radius={[6, 6, 0, 0]} fill="url(#sourceBars)" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}
