type ConfidenceMeterProps = {
  value: number;
};

export function ConfidenceMeter({ value }: ConfidenceMeterProps) {
  return (
    <div className="rounded-xl border border-white/10 bg-white/[0.03] p-3">
      <div className="flex items-end justify-between">
        <p className="text-[11px] uppercase tracking-[0.14em] text-white/55">Confidence</p>
        <p className="text-2xl font-semibold text-white">{value}%</p>
      </div>
      <div className="mt-3 h-2 overflow-hidden rounded-full bg-white/10">
        <div
          className="h-full rounded-full bg-gradient-to-r from-cyan-300 to-sky-400 transition-[width] duration-300 ease-[var(--ease-out-strong)]"
          style={{ width: `${Math.max(4, Math.min(value, 100))}%` }}
        />
      </div>
    </div>
  );
}
