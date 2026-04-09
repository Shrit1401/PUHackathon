import { cn } from "@/lib/utils";

type StatusPillProps = {
  status: string;
};

type StatusConfig = {
  pill: string;
  dot?: string;
  live?: boolean;
};

const statusConfig: Record<string, StatusConfig> = {
  Pending:    { pill: "border-amber-300/28 bg-amber-300/8 text-amber-100/90",   dot: "bg-amber-300", live: true },
  Assigned:   { pill: "border-cyan-300/28 bg-cyan-300/8 text-cyan-100/90",     dot: "bg-cyan-300",  live: true },
  Resolved:   { pill: "border-emerald-300/28 bg-emerald-300/8 text-emerald-100/90", dot: "bg-emerald-300" },
  Escalated:  { pill: "border-red-300/32 bg-red-400/10 text-red-100/90",       dot: "bg-red-300",   live: true },
  Deployed:   { pill: "border-red-300/32 bg-red-400/10 text-red-100/90",       dot: "bg-red-300",   live: true },
  Ready:      { pill: "border-emerald-300/28 bg-emerald-300/8 text-emerald-100/90", dot: "bg-emerald-300" },
  Offline:    { pill: "border-slate-300/18 bg-slate-300/6 text-slate-200/70" },
  "En Route": { pill: "border-sky-300/32 bg-sky-300/8 text-sky-100/90",        dot: "bg-sky-300",   live: true },
  Immediate:  { pill: "border-red-300/32 bg-red-400/10 text-red-100/90",       dot: "bg-red-300",   live: true },
  "Near-Term":{ pill: "border-cyan-300/28 bg-cyan-300/8 text-cyan-100/90",     dot: "bg-cyan-300" },
  Monitor:    { pill: "border-slate-300/18 bg-slate-300/6 text-slate-200/70" },
};

export function StatusPill({ status }: StatusPillProps) {
  const config = statusConfig[status] ?? { pill: "border-white/18 bg-white/6 text-white/75" };
  return (
    <span
      className={cn(
        "mt-1 inline-flex items-center gap-1.5 rounded-full border px-2 py-0.5 text-[9.5px] font-semibold uppercase tracking-[0.13em] shadow-[inset_0_1px_0_rgba(255,255,255,0.05)]",
        config.pill,
      )}
    >
      {config.dot && (
        <span
          className={cn(
            "h-1.5 w-1.5 rounded-full shrink-0",
            config.dot,
            config.live && "status-dot-live",
          )}
        />
      )}
      {status}
    </span>
  );
}
