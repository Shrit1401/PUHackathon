import { ArrowDownRight, ArrowRight, ArrowUpRight } from "lucide-react";

type StatsCardProps = {
  label: string;
  value: string | number;
  trend: "up" | "down" | "flat";
  delta: string;
};

export function StatsCard({ label, value, trend, delta }: StatsCardProps) {
  const Icon = trend === "up" ? ArrowUpRight : trend === "down" ? ArrowDownRight : ArrowRight;
  const tone =
    trend === "up"
      ? "text-emerald-200"
      : trend === "down"
        ? "text-red-200"
        : "text-cyan-100/80";

  return (
    <div className="motion-surface motion-pressable rounded-xl border border-white/[0.09] bg-white/[0.025] p-3 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)] hover:-translate-y-0.5 hover:border-white/[0.13]">
      <p className="text-[9.5px] uppercase tracking-[0.16em] text-white/42">{label}</p>
      <p className="mt-0.5 text-xl font-semibold tabular-nums tracking-tight text-white/90">{value}</p>
      <div className={`mt-1 inline-flex items-center gap-0.5 text-[10px] font-medium ${tone}`}>
        <Icon className="h-3 w-3" />
        <span>{delta}</span>
      </div>
    </div>
  );
}
