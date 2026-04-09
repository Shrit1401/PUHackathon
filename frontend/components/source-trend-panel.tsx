import {
  Area,
  AreaChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { SourceTrendPoint } from "../lib/types";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";

type SourceTrendPanelProps = {
  data: SourceTrendPoint[];
};

export function SourceTrendPanel({ data }: SourceTrendPanelProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Source Signal Trend</CardTitle>
      </CardHeader>
      <CardContent className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={data} margin={{ top: 8, right: 8, left: -20, bottom: 0 }}>
            <XAxis dataKey="time" tickLine={false} axisLine={false} tick={{ fill: "#94a3b8", fontSize: 11 }} />
            <YAxis tickLine={false} axisLine={false} tick={{ fill: "#94a3b8", fontSize: 11 }} />
            <Tooltip
              contentStyle={{
                backgroundColor: "#020617",
                border: "1px solid #334155",
                borderRadius: 8,
                color: "#e2e8f0",
              }}
            />
            <defs>
              <linearGradient id="newsArea" x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stopColor="#64748b" stopOpacity="0.9" />
                <stop offset="100%" stopColor="#020617" stopOpacity="0" />
              </linearGradient>
              <linearGradient id="socialArea" x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stopColor="#0ea5e9" stopOpacity="0.95" />
                <stop offset="100%" stopColor="#020617" stopOpacity="0" />
              </linearGradient>
              <linearGradient id="appArea" x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stopColor="#22c55e" stopOpacity="0.95" />
                <stop offset="100%" stopColor="#020617" stopOpacity="0" />
              </linearGradient>
              <linearGradient id="whatsappArea" x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stopColor="#4ade80" stopOpacity="0.9" />
                <stop offset="100%" stopColor="#020617" stopOpacity="0" />
              </linearGradient>
            </defs>
            <Area type="monotone" dataKey="news" stackId="1" stroke="#64748b" strokeWidth={2} fill="url(#newsArea)" />
            <Area
              type="monotone"
              dataKey="social"
              stackId="1"
              stroke="#0ea5e9"
              strokeWidth={2}
              fill="url(#socialArea)"
            />
            <Area type="monotone" dataKey="app" stackId="1" stroke="#22c55e" strokeWidth={2} fill="url(#appArea)" />
            <Area
              type="monotone"
              dataKey="whatsapp"
              stackId="1"
              stroke="#4ade80"
              strokeWidth={2}
              fill="url(#whatsappArea)"
            />
          </AreaChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
