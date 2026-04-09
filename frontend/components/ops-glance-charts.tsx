import {
  Area,
  AreaChart,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
} from "recharts";
import { IncidentRecord } from "@/lib/ops-types";

type OpsGlanceChartsProps = {
  incidents: IncidentRecord[];
};

type TrendPoint = {
  slot: string;
  incidents: number;
};

const statusColors: Record<string, string> = {
  Pending: "#f59e0b",
  Assigned: "#22d3ee",
  Resolved: "#22c55e",
  Escalated: "#ef4444",
};

function buildTrend(incidents: IncidentRecord[]): TrendPoint[] {
  const base = Math.max(2, incidents.length);
  return [
    { slot: "T-30", incidents: Math.max(1, base - 2) },
    { slot: "T-20", incidents: Math.max(1, base - 1) },
    { slot: "T-10", incidents: base },
    { slot: "Now", incidents: base + 1 },
  ];
}

export function OpsGlanceCharts({ incidents }: OpsGlanceChartsProps) {
  const trend = buildTrend(incidents);
  const statusData = [
    { name: "Pending", value: incidents.filter((i) => i.status === "Pending").length },
    { name: "Assigned", value: incidents.filter((i) => i.status === "Assigned").length },
    { name: "Resolved", value: incidents.filter((i) => i.status === "Resolved").length },
    { name: "Escalated", value: incidents.filter((i) => i.status === "Escalated").length },
  ];

  return (
    <div className="grid gap-2">
      <div className="rounded-xl border border-white/10 bg-white/[0.03] p-2.5">
        <p className="text-[10px] uppercase tracking-[0.12em] text-white/45">Incident Trend</p>
        <div className="mt-1.5 h-24">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={trend}>
              <defs>
                <linearGradient id="opsTrend" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#22d3ee" stopOpacity={0.7} />
                  <stop offset="100%" stopColor="#22d3ee" stopOpacity={0.03} />
                </linearGradient>
              </defs>
              <Tooltip
                contentStyle={{
                  border: "1px solid rgba(255,255,255,0.12)",
                  background: "rgba(2,6,23,0.94)",
                  borderRadius: "10px",
                  color: "#e2e8f0",
                  fontSize: "11px",
                }}
                labelStyle={{ color: "#94a3b8" }}
              />
              <Area
                type="monotone"
                dataKey="incidents"
                stroke="#22d3ee"
                strokeWidth={2}
                fill="url(#opsTrend)"
                dot={{ r: 2, fill: "#67e8f9" }}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>
      <div className="rounded-xl border border-white/10 bg-white/[0.03] p-2.5">
        <p className="text-[10px] uppercase tracking-[0.12em] text-white/45">Status Mix</p>
        <div className="mt-1.5 flex items-center gap-2">
          <div className="h-20 w-20">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={statusData} dataKey="value" nameKey="name" innerRadius={20} outerRadius={32} paddingAngle={3}>
                  {statusData.map((entry) => (
                    <Cell key={entry.name} fill={statusColors[entry.name]} />
                  ))}
                </Pie>
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="grid gap-1 text-[11px] text-white/70">
            {statusData.map((entry) => (
              <div key={entry.name} className="flex items-center justify-between gap-4">
                <span className="inline-flex items-center gap-1.5">
                  <span className="h-2 w-2 rounded-full" style={{ backgroundColor: statusColors[entry.name] }} />
                  {entry.name}
                </span>
                <span className="font-mono text-white/85">{entry.value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
