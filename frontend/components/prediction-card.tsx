import { Prediction } from "@/lib/ops-types";

type PredictionCardProps = {
  item: Prediction;
};

export function PredictionCard({ item }: PredictionCardProps) {
  return (
    <article className="motion-surface rounded-xl border border-white/10 bg-white/[0.03] p-3">
      <div className="flex items-center justify-between gap-2">
        <p className="text-[10px] uppercase tracking-[0.12em] text-white/45">{item.horizon}</p>
        <span className="rounded-full border border-white/15 bg-black/25 px-2 py-0.5 text-[10px] text-white/70">
          Priority {item.priority}
        </span>
      </div>
      <p className="mt-2 text-sm text-white/82">{item.statement}</p>
      <p className="mt-2 text-xs text-cyan-100/80">Model confidence: {item.confidence}%</p>
    </article>
  );
}
