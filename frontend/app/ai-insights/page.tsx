"use client";

import { useEffect, useState } from "react";
import { OpsShell } from "@/components/ops-shell";
import {
  type ConfidenceScoreResponse,
  fetchAiInsightsActions,
  fetchAiInsightsSummary,
  fetchEvents,
  fetchGrid,
  fetchPredictions,
  scoreConfidence,
} from "@/lib/api";
import { AiConfidenceModelPanel } from "@/components/ai-confidence-model-panel";
import { ReaderRail } from "@/components/reader-rail";

export default function AIInsightsPage() {
  const [loading, setLoading] = useState(true);
  const [liveConfidence, setLiveConfidence] = useState<ConfidenceScoreResponse | null>(null);
  const [liveConfidenceError, setLiveConfidenceError] = useState<string | null>(null);

  useEffect(() => {
    async function loadInsights() {
      try {
        await Promise.all([
          fetchGrid(),
          fetchPredictions(),
          fetchEvents(),
          fetchAiInsightsActions(10),
          fetchAiInsightsSummary(),
        ]);

        try {
          const scored = await scoreConfidence({
            local_grid_risk_score: 0.55,
            weather_severity: 0.42,
            nearby_ready_responders: 3,
            eonet_event_count_24h: 2,
            source_entropy: 0.68,
            report_counts: { app: 4, whatsapp: 2, news: 1, social: 1 },
          });
          setLiveConfidence(scored);
          setLiveConfidenceError(null);
        } catch (scoreErr) {
          setLiveConfidence(null);
          setLiveConfidenceError(
            scoreErr instanceof Error ? scoreErr.message : "Confidence probe failed",
          );
        }
      } catch (error) {
        console.error(error);
        setLiveConfidence(null);
        setLiveConfidenceError(null);
      } finally {
        setLoading(false);
      }
    }
    void loadInsights();
  }, []);

  const readerLinks = [
    { id: "trust-engine", label: "Trust engine", hint: "Why the model believes what it believes" },
    { id: "model-plots", label: "Plot gallery", hint: "Calibration & feature story" },
    { id: "playbook", label: "Playbook", hint: "Expandable specs for builders" },
  ];

  return (
    <OpsShell
      title="AI Decision Support"
      subtitle="Live grid, predictions, and the calibrated confidence model that powers escalation."
      lede="Skim the pulse, then scroll into the trust narrative — numbers, NASA context, and the exact API paths that keep humans and models aligned."
      tag="Model + live inference"
    >
      <ReaderRail links={readerLinks} title="Jump to" />

      {/* ── CONFIDENCE MODEL ─────────────────────────────────────────────── */}
      <AiConfidenceModelPanel
        liveScore={liveConfidence}
        liveScoreError={liveConfidenceError}
        probeLoading={loading}
      />
    </OpsShell>
  );
}
