"use client";

import Image from "next/image";
import { Sparkles, Telescope, Zap } from "lucide-react";
import { EngageReveal } from "@/components/engage-reveal";
import type { ConfidenceScoreResponse } from "@/lib/api";

// Props kept for backward compatibility — liveScore/liveScoreError/probeLoading no longer rendered
type AiConfidenceModelPanelProps = {
  liveScore?: ConfidenceScoreResponse | null;
  liveScoreError?: string | null;
  probeLoading?: boolean;
};

const API_WIRING: { method: string; path: string; note: string }[] = [
  { method: "POST", path: "/ml/confidence/score",  note: "Core scorer: LightGBM → isotonic → penalty layer" },
  { method: "GET",  path: "/ai/insights/summary",  note: "Dashboard narrative + model_version hook" },
  { method: "GET",  path: "/ai/insights/actions",  note: "Ranked playbooks for operators" },
  { method: "GET",  path: "/predictions",          note: "Nowcasts consume calibrated confidence" },
  { method: "GET",  path: "/grid",                 note: "Per-cell risk context for features" },
  { method: "GET",  path: "/grid/nearby",          note: "Localized risk without full map sweep" },
  { method: "GET",  path: "/events",               note: "Active signals for corroboration counts" },
  { method: "GET",  path: "/reports",              note: "Citizen + channel reports for velocity features" },
  { method: "POST", path: "/external/ingest",      note: "NASA EONET / partner feeds enter the same feature fabric" },
  { method: "GET",  path: "/responders/nearby",    note: "Responder density & ETA proxies" },
];

const FEATURE_BLOCKS = [
  "Internal: app_report_count_30m, whatsapp_report_count_30m, news/social counts, unique_source_count_1h, report_velocity, source_entropy",
  "Geo-temporal: lat/lng (or geohash), hour_of_day_local, day_of_week, is_night, distance_to_last_confirmed_event_km, local_grid_risk_score",
  "Weather: weather_severity, rain_mm_3h, wind_speed, temp_anomaly, forecast_risk_next_3h",
  "EONET: eonet_event_count_24h_r50km, eonet_event_count_72h_r100km, nearest_eonet_distance_km, nearest_eonet_age_hours, category match & severity proxy",
  "Operational: nearby_ready_responders_5km, eta_best_responder_min, historical_false_alarm_rate_zone, zone_confirmation_rate_30d",
];

const THRESHOLDS = [
  { band: "≥ 0.85", action: "Immediate escalation",           color: "text-red-300",    bar: "bg-red-400" },
  { band: "0.65 – 0.84", action: "Priority watch + human review", color: "text-amber-300",  bar: "bg-amber-400" },
  { band: "0.45 – 0.64", action: "Monitor + collect more signals", color: "text-cyan-300",   bar: "bg-cyan-400" },
  { band: "< 0.45",  action: "Low confidence — no auto escalation", color: "text-slate-400",  bar: "bg-slate-500" },
];

const STORY_BEATS = [
  {
    icon: Telescope,
    step: "01",
    title: "Listen everywhere",
    body: "WhatsApp pings, app reports, news, social posts, and NASA EONET become one timeline — no signal fights for attention alone.",
    accent: "from-violet-500/10 border-violet-400/20",
    iconColor: "text-violet-300/80 bg-violet-400/10",
  },
  {
    icon: Zap,
    step: "02",
    title: "Score with receipts",
    body: "LightGBM ranks patterns; isotonic calibration turns raw scores into probabilities you can defend in a briefing.",
    accent: "from-cyan-500/10 border-cyan-400/20",
    iconColor: "text-cyan-300/80 bg-cyan-400/10",
  },
  {
    icon: Sparkles,
    step: "03",
    title: "Never go blind",
    body: "If the model hiccups, weighted rules still produce a score — SOS flows stay open, reasons stay visible.",
    accent: "from-emerald-500/10 border-emerald-400/20",
    iconColor: "text-emerald-300/80 bg-emerald-400/10",
  },
];

const MODEL_STATS = [
  { label: "Time-ordered snapshots", value: "~2,200",      sub: "Reproducible stochastic labels" },
  { label: "Chronological split",    value: "70/15/15",    sub: "Train · val · test" },
  { label: "Test ROC-AUC",           value: "0.5208",      sub: "Synthetic task; live labels will sharpen" },
  { label: "Brier score",            value: "0.2511",      sub: "Lower is better · post-isotonic" },
  { label: "Boosting config",        value: "600 trees",   sub: "LR 0.03 · subsample 0.9" },
  { label: "Artifacts",              value: "LGBM + ISO",  sub: "lightgbm.pkl · isotonic.pkl · meta.json" },
];

function DetailBlock({ step, title, children }: { step: string; title: string; children: React.ReactNode }) {
  return (
    <details className="group overflow-hidden rounded-xl border border-white/[0.08] bg-black/20 transition-[border-color,background-color] duration-200 open:border-white/[0.12] open:bg-black/30">
      <summary className="flex cursor-pointer list-none items-center justify-between gap-3 px-5 py-4 marker:hidden hover:bg-white/[0.02] [&::-webkit-details-marker]:hidden">
        <div className="flex items-center gap-3">
          <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-md border border-white/[0.1] bg-white/[0.04] font-mono text-[9px] font-bold text-white/40">
            {step}
          </span>
          <span className="text-sm font-medium text-white/75 group-open:text-white/95">{title}</span>
        </div>
        <span className="text-xs text-white/20 transition-transform duration-200 group-open:rotate-90">›</span>
      </summary>
      <div className="border-t border-white/[0.06] px-5 pb-5 pt-4 text-sm leading-relaxed text-white/55">
        {children}
      </div>
    </details>
  );
}

function PlotFigure({ src, alt, caption }: { src: string; alt: string; caption: string }) {
  return (
    <figure className="overflow-hidden rounded-xl border border-white/[0.08] bg-black/40 transition-[border-color] duration-200 hover:border-white/[0.14]">
      <div className="relative aspect-[4/3] w-full bg-gradient-to-b from-slate-900/60 to-black/80">
        <Image
          src={src}
          alt={alt}
          fill
          className="object-contain p-3"
          sizes="(max-width: 768px) 100vw, 33vw"
          unoptimized
        />
      </div>
      <figcaption className="border-t border-white/[0.06] px-4 py-3 text-[11px] leading-snug text-white/45">
        {caption}
      </figcaption>
    </figure>
  );
}

export function AiConfidenceModelPanel({ liveScore, liveScoreError, probeLoading }: AiConfidenceModelPanelProps) {
  return (
    <section id="trust-engine" className="scroll-anchor space-y-4">

      {/* Hero narrative banner */}
      <EngageReveal>
        <div className="relative overflow-hidden rounded-2xl border border-white/[0.08] bg-black/40 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)]">
          {/* Background glow */}
          <div className="pointer-events-none absolute inset-0">
            <div className="absolute -right-16 -top-16 h-64 w-64 rounded-full bg-violet-500/8 blur-3xl" />
            <div className="absolute -bottom-16 left-1/3 h-48 w-48 rounded-full bg-cyan-500/8 blur-3xl" />
          </div>

          <div className="relative p-6 sm:p-8">
            <div className="mb-5 flex items-center gap-2">
              <div className="flex h-7 w-7 items-center justify-center rounded-lg border border-violet-400/25 bg-violet-400/10">
                <Sparkles className="h-3.5 w-3.5 text-violet-300/90" />
              </div>
              <p className="text-[10px] font-semibold uppercase tracking-[0.22em] text-white/35">
                Confidence intelligence
              </p>
            </div>

            <h2 className="max-w-2xl text-2xl font-bold tracking-tight text-white sm:text-3xl">
              The story of how ResQNet+ decides what to trust
            </h2>

            <div className="mt-4 h-px w-16 bg-gradient-to-r from-cyan-400/60 to-transparent" />

            <p className="mt-5 max-w-3xl text-sm leading-relaxed text-white/50">
              In an emergency stack, the hardest question isn't "what happened?" — it's{" "}
              <em className="not-italic text-white/80">should we move people and assets right now?</em>{" "}
              Every escalation spends minutes, fuel, and focus. The model learns from the same evidence your operators see —
              app, WhatsApp, news, social, grid risk, weather, NASA EONET, and responder readiness — then returns a
              calibrated probability. LightGBM handles messy interactions, isotonic regression keeps probabilities
              honest, and deterministic rules keep the API warm when ML pauses.
            </p>
          </div>
        </div>
      </EngageReveal>

      {/* Three beats */}
      <EngageReveal delay={0.06}>
        <div className="grid gap-3 md:grid-cols-3">
          {STORY_BEATS.map(({ icon: Icon, step, title, body, accent, iconColor }) => (
            <div
              key={title}
              className={`overflow-hidden rounded-2xl border bg-gradient-to-br ${accent} to-transparent p-5 transition-[border-color] duration-200 hover:border-white/[0.16]`}
            >
              <div className="mb-4 flex items-center gap-2.5">
                <div className={`flex h-8 w-8 items-center justify-center rounded-lg ${iconColor}`}>
                  <Icon className="h-4 w-4" />
                </div>
                <span className="font-mono text-[10px] font-bold text-white/20">{step}</span>
              </div>
              <p className="text-sm font-semibold text-white/85">{title}</p>
              <p className="mt-2 text-xs leading-relaxed text-white/45">{body}</p>
            </div>
          ))}
        </div>
      </EngageReveal>

      {/* Model metrics */}
      <EngageReveal delay={0.08}>
        <div className="overflow-hidden rounded-2xl border border-white/[0.08] bg-black/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)]">
          <div className="border-b border-white/[0.06] px-5 py-4">
            <p className="text-[10px] uppercase tracking-[0.2em] text-white/35">Lab run</p>
            <p className="mt-0.5 text-base font-bold tracking-tight text-white">Synthetic ResQNet+ signals</p>
            <p className="mt-1 max-w-xl text-xs text-white/35">
              Fake-but-plausible traffic so you can see training, metrics, and plots before production labels arrive.
            </p>
          </div>
          <div className="grid gap-px bg-white/[0.04] sm:grid-cols-2 xl:grid-cols-3">
            {MODEL_STATS.map((stat) => (
              <div key={stat.label} className="bg-[#040507] px-5 py-4">
                <p className="text-[9.5px] uppercase tracking-[0.16em] text-white/30">{stat.label}</p>
                <p className="mt-1 font-mono text-lg font-bold tabular-nums text-white/85">{stat.value}</p>
                <p className="mt-0.5 text-[10px] text-white/30">{stat.sub}</p>
              </div>
            ))}
          </div>
        </div>
      </EngageReveal>

      {/* Plot gallery */}
      <EngageReveal delay={0.1}>
        <div id="model-plots" className="scroll-anchor overflow-hidden rounded-2xl border border-white/[0.08] bg-black/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)]">
          <div className="border-b border-white/[0.06] px-5 py-4">
            <p className="text-[10px] uppercase tracking-[0.2em] text-white/35">Evidence you can show on a slide</p>
            <p className="mt-0.5 text-base font-bold tracking-tight text-white">Plot gallery</p>
            <p className="mt-1 text-xs text-white/35">
              Drop your exports into{" "}
              <code className="rounded-md bg-white/[0.06] px-1.5 py-0.5 font-mono text-[10px] text-white/55">public/1.png</code>,{" "}
              <code className="rounded-md bg-white/[0.06] px-1.5 py-0.5 font-mono text-[10px] text-white/55">2.png</code>,{" "}
              <code className="rounded-md bg-white/[0.06] px-1.5 py-0.5 font-mono text-[10px] text-white/55">3.png</code> to light up the gallery.
            </p>
          </div>
          <div className="grid gap-4 p-5 md:grid-cols-3">
            <PlotFigure
              src="/1.png"
              alt="Polar calibration curve"
              caption="Polar calibration — each spoke is a prediction bucket; radius tracks observed accuracy."
            />
            <PlotFigure
              src="/2.png"
              alt="LightGBM feature importance"
              caption="Feature importance — taller bars steered more splits."
            />
            <PlotFigure
              src="/3.png"
              alt="Confidence score distribution"
              caption="Confidence distribution — KDE shows where incidents cluster."
            />
          </div>
        </div>
      </EngageReveal>


      {/* Threshold table */}
      <EngageReveal delay={0.06}>
        <div className="overflow-hidden rounded-2xl border border-white/[0.08] bg-black/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)]">
          <div className="border-b border-white/[0.06] px-5 py-4">
            <p className="text-[10px] uppercase tracking-[0.2em] text-white/35">Operational thresholds</p>
            <p className="mt-0.5 text-base font-bold tracking-tight text-white">When to act</p>
          </div>
          <div className="divide-y divide-white/[0.04]">
            {THRESHOLDS.map((row) => (
              <div key={row.band} className="flex items-center gap-4 px-5 py-3.5">
                <div className={`h-1.5 w-1.5 shrink-0 rounded-full ${row.bar}`} />
                <p className={`w-28 shrink-0 font-mono text-sm font-bold ${row.color}`}>{row.band}</p>
                <p className="text-sm text-white/50">{row.action}</p>
              </div>
            ))}
          </div>
        </div>
      </EngageReveal>

      {/* Engineering playbook */}
      <EngageReveal delay={0.06}>
        <div id="playbook" className="scroll-anchor overflow-hidden rounded-2xl border border-white/[0.08] bg-black/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)]">
          <div className="border-b border-white/[0.06] px-5 py-4">
            <p className="text-[10px] uppercase tracking-[0.2em] text-white/35">Engineering playbook</p>
            <p className="mt-0.5 text-base font-bold tracking-tight text-white">Deep dives for builders</p>
            <p className="mt-1 text-xs text-white/30">Open only what you need.</p>
          </div>
          <div className="space-y-px p-4">
            <DetailBlock step="01" title="What the model predicts">
              <p>
                Binary probability that a candidate incident is a{" "}
                <strong className="text-white/80">true high-priority event</strong> warranting escalation within a
                fixed horizon (for example 2h). Production labels freeze to your DB: status transitions, assignments,
                dispatch, and severity confirmations.
              </p>
            </DetailBlock>
            <DetailBlock step="02" title="Stack: speed, honesty, resilience">
              <ul className="space-y-2">
                <li className="flex gap-2"><span className="text-white/25">—</span><span><strong className="text-white/75">LightGBM</strong> — tabular workhorse for mixed internal + EONET features.</span></li>
                <li className="flex gap-2"><span className="text-white/25">—</span><span><strong className="text-white/75">Isotonic calibration</strong> — maps raw scores to probabilities operators can trust.</span></li>
                <li className="flex gap-2"><span className="text-white/25">—</span><span><strong className="text-white/75">Rule-based fallback</strong> — weighted sources, weather, grid, EONET proximity; never blocks SOS flow.</span></li>
              </ul>
            </DetailBlock>
            <DetailBlock step="03" title="Data fusion & NASA EONET">
              <p>
                Each training row is a snapshot at decision time <code className="rounded bg-white/[0.06] px-1 py-0.5 font-mono text-[11px] text-cyan-200/70">t</code>.
                We spatially join EONET hazards (50–200 km radius by type), window them (24h / 72h), aggregate
                counts/distances/recency, then merge with ResQNet+ internal signals.
              </p>
            </DetailBlock>
            <DetailBlock step="04" title="Feature blocks (feature_set_v1)">
              <ul className="space-y-2">
                {FEATURE_BLOCKS.map((line) => (
                  <li key={line} className="flex gap-2">
                    <span className="text-white/25">—</span>
                    <span>{line}</span>
                  </li>
                ))}
              </ul>
            </DetailBlock>
            <DetailBlock step="05" title="Online scoring & penalties">
              <ol className="space-y-2">
                {[
                  "Raw positive class probability from LightGBM.",
                  "Calibrate through the fitted isotonic regressor.",
                  "Apply uncertainty penalties (missing weather/sources, sparse zones, low diversity caps, contradictory signals), clamp to [0, 1].",
                  "Return confidence, base_confidence, and auditable reasons[].",
                ].map((step, i) => (
                  <li key={i} className="flex gap-2.5">
                    <span className="shrink-0 font-mono text-[10px] text-white/25">{String(i + 1).padStart(2, "0")}</span>
                    <span>{step}</span>
                  </li>
                ))}
              </ol>
            </DetailBlock>
            <DetailBlock step="06" title="Metrics we watch in production">
              <p>
                ROC-AUC, PR-AUC (rare positives), Brier score, calibration / ECE, recall at the chosen threshold,
                false-alarm rate by zone and disaster type, plus fairness slices (urban vs rural, high-signal vs low-signal).
              </p>
            </DetailBlock>
            <DetailBlock step="07" title="MLOps, audit, and API map">
              <p className="mb-4">
                Persist every inference with event_id, model_version, feature_set_version, base/final confidence,
                reasons, fallback flag, and timestamp.
              </p>
              <div className="overflow-x-auto rounded-xl border border-white/[0.07]">
                <table className="w-full min-w-[520px] text-left text-xs">
                  <thead>
                    <tr className="border-b border-white/[0.07] bg-white/[0.03]">
                      <th className="px-4 py-2.5 font-semibold uppercase tracking-[0.12em] text-white/30">Method</th>
                      <th className="px-4 py-2.5 font-semibold uppercase tracking-[0.12em] text-white/30">Path</th>
                      <th className="px-4 py-2.5 font-semibold uppercase tracking-[0.12em] text-white/30">Role</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/[0.04]">
                    {API_WIRING.map((row) => (
                      <tr key={`${row.method}-${row.path}`} className="hover:bg-white/[0.02]">
                        <td className="px-4 py-2.5">
                          <span className={`font-mono font-semibold ${row.method === "POST" ? "text-amber-300/80" : "text-emerald-300/80"}`}>
                            {row.method}
                          </span>
                        </td>
                        <td className="px-4 py-2.5 font-mono text-cyan-200/70">{row.path}</td>
                        <td className="px-4 py-2.5 text-white/45">{row.note}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </DetailBlock>
          </div>
        </div>
      </EngageReveal>

    </section>
  );
}
