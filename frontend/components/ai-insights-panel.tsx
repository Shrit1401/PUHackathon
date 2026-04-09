import { Prediction, RiskZone, SuggestedAction } from "@/lib/ops-types";
import { PredictionCard } from "./prediction-card";
import { RiskZoneCard } from "./risk-zone-card";
import { StatusPill } from "./status-pill";

type AIInsightsPanelProps = {
  zones: RiskZone[];
  predictions: Prediction[];
  actions: SuggestedAction[];
};

export function AIInsightsPanel({ zones, predictions, actions }: AIInsightsPanelProps) {
  return (
    <section className="grid gap-4 xl:grid-cols-12">
      <div className="space-y-4 xl:col-span-7">
        {zones.map((zone) => (
          <RiskZoneCard key={zone.id} zone={zone} />
        ))}
      </div>
      <div className="space-y-4 xl:col-span-5">
        <article className="rounded-2xl border border-white/10 bg-black/25 p-4">
          <p className="text-[11px] uppercase tracking-[0.16em] text-white/45">Predictions</p>
          <div className="mt-3 space-y-2">
            {predictions.map((prediction) => (
              <PredictionCard key={prediction.id} item={prediction} />
            ))}
          </div>
        </article>
        <article className="rounded-2xl border border-white/10 bg-black/25 p-4">
          <p className="text-[11px] uppercase tracking-[0.16em] text-white/45">Suggested Actions</p>
          <div className="mt-3 space-y-2">
            {actions.map((action) => (
              <div
                key={action.id}
                className="rounded-xl border border-white/10 bg-white/[0.03] p-3 text-sm text-white/82"
              >
                <div className="flex items-center justify-between gap-2">
                  <p className="font-medium">{action.owner}</p>
                  <StatusPill status={action.urgency} />
                </div>
                <p className="mt-1.5 text-white/72">{action.action}</p>
              </div>
            ))}
          </div>
          <p className="mt-4 rounded-lg border border-cyan-200/20 bg-cyan-300/10 p-3 text-xs text-cyan-100/85">
            Data source: `GET /ai/analyze` aggregated from field telemetry, weather bands, and responder
            assignment channels.
          </p>
        </article>
      </div>
    </section>
  );
}
