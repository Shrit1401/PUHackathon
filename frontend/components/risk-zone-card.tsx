import { RiskZone } from "@/lib/ops-types";
import { ConfidenceMeter } from "./confidence-meter";

type RiskZoneCardProps = {
  zone: RiskZone;
};

export function RiskZoneCard({ zone }: RiskZoneCardProps) {
  return (
    <article className="motion-surface rounded-2xl border border-white/10 bg-black/25 p-4">
      <p className="text-[11px] uppercase tracking-[0.14em] text-white/45">High Risk Zone</p>
      <h3 className="mt-1 text-lg font-semibold text-white">{zone.zone}</h3>
      <div className="mt-3 grid grid-cols-2 gap-2 text-sm text-white/75">
        <div className="rounded-lg border border-white/10 bg-white/[0.02] p-2">
          <p className="text-[10px] uppercase tracking-[0.12em] text-white/45">Risk Score</p>
          <p className="text-xl font-semibold text-red-200">{zone.riskScore}</p>
        </div>
        <div className="rounded-lg border border-white/10 bg-white/[0.02] p-2">
          <p className="text-[10px] uppercase tracking-[0.12em] text-white/45">Active</p>
          <p className="text-xl font-semibold text-white">{zone.activeIncidents}</p>
        </div>
      </div>
      <div className="mt-3">
        <ConfidenceMeter value={zone.confidence} />
      </div>
      <p className="mt-3 text-sm text-white/70">{zone.recommendation}</p>
    </article>
  );
}
