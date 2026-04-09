"use client";

import { useEffect, useRef, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";

type Metric = {
  label: string;
  value: number;
  suffix?: string;
};

type MetricsBarProps = {
  activeDisasters: number;
  avgConfidence: number;
  totalReports: number;
  highRiskZones: number;
};

function CountValue({ value, suffix }: { value: number; suffix?: string }) {
  const [display, setDisplay] = useState(0);
  const previousValue = useRef(0);

  useEffect(() => {
    const reduceMotion =
      typeof window !== "undefined" &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduceMotion) {
      setDisplay(value);
      return;
    }

    const from = previousValue.current;
    const delta = value - from;
    if (delta === 0) {
      return;
    }

    const duration = 240;
    let frameId = 0;
    const start = performance.now();

    const tick = (now: number) => {
      const t = Math.min(1, (now - start) / duration);
      const eased = 1 - Math.pow(1 - t, 3);
      setDisplay(Math.round(from + delta * eased));
      if (t < 1) {
        frameId = window.requestAnimationFrame(tick);
      }
    };

    frameId = window.requestAnimationFrame(tick);
    return () => window.cancelAnimationFrame(frameId);
  }, [value]);

  useEffect(() => {
    previousValue.current = display;
  }, [display]);

  return (
    <p className="mt-0.5 text-xl font-semibold tabular-nums tracking-tight text-white/90">
      {display}
      {suffix ? (
        <span className="ml-0.5 text-xs text-white/48">{suffix}</span>
      ) : null}
    </p>
  );
}

export function MetricsBar({
  activeDisasters,
  avgConfidence,
  totalReports,
  highRiskZones,
}: MetricsBarProps) {
  const metrics: Metric[] = [
    { label: "Open Incidents", value: activeDisasters },
    { label: "Confidence Avg", value: avgConfidence, suffix: "%" },
    { label: "Reports Today", value: totalReports },
    { label: "Priority Zones", value: highRiskZones },
  ];

  return (
    <Card motion="surface">
      <CardHeader>
        <CardTitle className="text-white/85">At A Glance</CardTitle>
      </CardHeader>
      <CardContent className="grid grid-cols-2 gap-2.5">
        {metrics.map((metric) => (
          <div
            key={metric.label}
            className="motion-surface motion-pressable rounded-xl border border-white/[0.09] bg-white/[0.025] p-3 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)] hover:-translate-y-0.5 hover:border-white/[0.13] hover:bg-white/[0.04]"
          >
            <p className="text-[9.5px] uppercase tracking-[0.16em] text-white/42">
              {metric.label}
            </p>
            <CountValue value={metric.value} suffix={metric.suffix} />
          </div>
        ))}
      </CardContent>
    </Card>
  );
}
