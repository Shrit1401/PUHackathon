# Training Guide: Confidence Model for ResQNet+ Backend

This guide explains how to train and deploy a backend confidence model using:

- NASA EONET events as external hazard context
- Your ResQNet+ backend signals (`/reports`, `/events`, `/grid`, weather/news/social/app/whatsapp sources)
- A production-ready model stack: **LightGBM + Isotonic Calibration + Rule-Based Fallback**

The goal is to produce a trustworthy `confidence` score (0.0-1.0) for event validity/escalation.

---

## 1) What We Are Predicting

Use the model to answer:

> "Given current signals around a candidate incident, what is the probability this is a true high-priority event that should trigger active response/escalation?"

### Recommended target

Binary classification:

- `1` = incident confirmed/escalated/required responder action within a fixed horizon (for example 2h)
- `0` = false alarm, duplicate noise, or resolved without meaningful intervention

You can define this from your DB and workflow states:

- incident status transitions
- assignment records
- responder dispatch
- high severity confirmation

Keep this label definition frozen per model version.

---

## 2) Why This Model Stack

### Base model: LightGBM

- Fast training and inference
- Excellent on tabular/mixed features
- Handles nonlinear interactions well
- Easy feature importance inspection
- Low operational complexity for backend deployment

### Calibration: Isotonic Regression

- Raw boosting probabilities are often over/under-confident
- Isotonic calibration maps raw score -> calibrated probability
- Gives confidence values you can actually trust in production

### Fallback: deterministic rules

- Protects system during model outage, sparse data, or bad payloads
- Ensures emergency flow never blocks

---

## 3) Data Sources and Joins

Build one training row per candidate event snapshot.

### Core internal sources

- `reports` table / `GET /reports`
- `events` table / `GET /events`
- `grid` risk context / `GET /grid` or `/grid/nearby`
- weather severity (existing `weather_severity` and OpenWeather forecast)
- source breakdown (`app`, `whatsapp`, `news`, `social`)
- responder context (nearby availability, assignment lag)

### External context

- EONET API (`https://eonet.gsfc.nasa.gov/`) events/categories/geometry

### Join strategy

For each incident snapshot at timestamp `t`:

1. Find nearby EONET events in spatial radius (ex: 50-200 km depending on event type)
2. Filter EONET records to time windows around `t` (ex: previous 24h / 72h)
3. Aggregate EONET features into numeric fields (counts, closest distance, recency, category match)
4. Merge with internal signals and target label

Store joined data into a model dataset table/file with immutable `snapshot_time`.

---

## 4) Feature Engineering (Detailed)

Design features in blocks to keep maintenance clear.

## 4.1 Internal signal features

- `app_report_count_30m`
- `whatsapp_report_count_30m`
- `news_signal_count_1h`
- `social_signal_count_1h`
- `unique_source_count_1h`
- `report_velocity` (reports per 10 min)
- `source_entropy` (signal diversity proxy)

## 4.2 Geo-temporal features

- `lat`, `lng` (or geohash bucket)
- `hour_of_day_local`
- `day_of_week`
- `is_night`
- `distance_to_last_confirmed_event_km`
- `local_grid_risk_score`

## 4.3 Weather features

- `weather_severity`
- `rain_mm_3h`
- `wind_speed`
- `temp_anomaly`
- `forecast_risk_next_3h` (engineered)

## 4.4 EONET-derived features

- `eonet_event_count_24h_r50km`
- `eonet_event_count_72h_r100km`
- `nearest_eonet_distance_km`
- `nearest_eonet_age_hours`
- `eonet_category_match` (binary/categorical)
- `eonet_severity_proxy` (if inferred by category + persistence)

## 4.5 Operational features

- `nearby_ready_responders_5km`
- `eta_best_responder_min`
- `historical_false_alarm_rate_zone`
- `zone_confirmation_rate_30d`

### Practical rules for features

- Keep all training features numeric or one-hot categorical
- Avoid leakage (do not use future info)
- Freeze transformations in code
- Version your feature list (`feature_set_v1`)

---

## 5) Labeling Pipeline

Define labeling function clearly in code and docs.

Example label rules (adjust to your product truth):

- `label=1` if event became `assigned` or `escalated` within 120 minutes
- OR if incident had `severity=high` plus >=N corroborating reports
- else `label=0`

Create an offline script:

1. Pull historical incidents and reports
2. Build feature snapshot at decision time
3. Compute label from future outcomes within horizon
4. Write training parquet/csv

Never change historical labels silently. If logic changes, bump dataset version.

---

## 6) Recommended Training Split

Use **time-based split** (not random) to mimic production.

- Train: oldest 70%
- Validation: next 15%
- Test: newest 15%

Also evaluate by geography segment:

- high-density zones
- low-signal/rural zones
- disaster-type slices (flood, fire, storm, etc.)

---

## 7) Training Implementation (Python)

Use a dedicated training service/repo folder.

### Dependencies

- `lightgbm`
- `scikit-learn`
- `pandas`
- `numpy`
- `joblib`

### Example training script

```python
import json
import joblib
import pandas as pd
from lightgbm import LGBMClassifier
from sklearn.isotonic import IsotonicRegression
from sklearn.metrics import roc_auc_score, brier_score_loss, precision_recall_curve

DATA_PATH = "data/train_dataset_v1.parquet"
MODEL_DIR = "artifacts/confidence_v1"

df = pd.read_parquet(DATA_PATH).sort_values("snapshot_time")

feature_cols = [
    "app_report_count_30m",
    "whatsapp_report_count_30m",
    "news_signal_count_1h",
    "social_signal_count_1h",
    "unique_source_count_1h",
    "report_velocity",
    "local_grid_risk_score",
    "weather_severity",
    "eonet_event_count_24h_r50km",
    "nearest_eonet_distance_km",
    "nearest_eonet_age_hours",
    "nearby_ready_responders_5km",
    "eta_best_responder_min",
]

X = df[feature_cols]
y = df["label"].astype(int)

n = len(df)
train_end = int(n * 0.70)
val_end = int(n * 0.85)

X_train, y_train = X.iloc[:train_end], y.iloc[:train_end]
X_val, y_val = X.iloc[train_end:val_end], y.iloc[train_end:val_end]
X_test, y_test = X.iloc[val_end:], y.iloc[val_end:]

model = LGBMClassifier(
    n_estimators=600,
    learning_rate=0.03,
    num_leaves=31,
    subsample=0.9,
    colsample_bytree=0.9,
    random_state=42
)
model.fit(X_train, y_train)

# Raw probabilities
val_raw = model.predict_proba(X_val)[:, 1]
test_raw = model.predict_proba(X_test)[:, 1]

# Isotonic calibration on validation split
calibrator = IsotonicRegression(out_of_bounds="clip")
calibrator.fit(val_raw, y_val)
test_cal = calibrator.transform(test_raw)

auc = roc_auc_score(y_test, test_cal)
brier = brier_score_loss(y_test, test_cal)

print("AUC:", round(auc, 4))
print("Brier:", round(brier, 4))

joblib.dump(model, f"{MODEL_DIR}/lightgbm.pkl")
joblib.dump(calibrator, f"{MODEL_DIR}/isotonic.pkl")

meta = {
    "model_version": "confidence_v1",
    "features": feature_cols,
    "target": "label",
    "calibration": "isotonic",
    "metrics": {"auc": float(auc), "brier": float(brier)},
}
with open(f"{MODEL_DIR}/meta.json", "w") as f:
    json.dump(meta, f, indent=2)
```

---

## 8) Confidence Scoring Function

Online confidence should be:

1. `raw = lightgbm.predict_proba(features)[1]`
2. `calibrated = isotonic.transform([raw])[0]`
3. `final = apply_uncertainty_penalties(calibrated, feature_quality)`

### Example penalty rules

- Missing critical features (`weather`, `source_count`) -> multiply by `0.85`
- Very sparse zone history -> multiply by `0.90`
- No corroborating source diversity -> cap at `0.70`
- Strong contradictory signals -> subtract `0.10`

Clamp to `[0.0, 1.0]`.

Return both:

- `confidence` (final)
- `base_confidence` (calibrated before penalty)
- `confidence_reasons[]` (auditable explanations)

---

## 9) Backend API Integration

Add an internal ML scoring endpoint in backend.

### Suggested endpoint

- `POST /ml/confidence/score`

Request body should include all required features or references (`event_id`) that backend can expand.

### Suggested response

```json
{
  "model_version": "confidence_v1",
  "base_confidence": 0.86,
  "confidence": 0.78,
  "reasons": [
    "Multi-source corroboration in last 30m",
    "Nearby EONET hazard in last 24h",
    "Penalty: sparse historical signal in zone"
  ],
  "fallback_used": false
}
```

Then wire this into:

- event creation flow (`/reports`, `/external/ingest`)
- prediction generation (`/predictions`)
- AI insights summary (`/ai/insights/summary`)

Persist scores in DB with model version for observability.

---

## 10) Training/Serving Architecture

Recommended layout:

- `ml/training/` -> notebooks/scripts for dataset + fit
- `ml/artifacts/` -> model binaries and meta
- `ml/service/` -> lightweight inference microservice or in-backend module
- `ml/evaluation/` -> reports and drift monitors

### Minimal MLOps loop

1. Daily/weekly dataset refresh
2. Retrain candidate model
3. Compare against current production metrics
4. Promote only if better and stable
5. Roll out with canary traffic
6. Monitor drift + calibration degradation

---

## 11) Evaluation Metrics You Must Track

For binary confidence in emergency domain:

- ROC-AUC (ranking quality)
- PR-AUC (important if positives are rare)
- Brier score (probability quality)
- Calibration curve / ECE (confidence honesty)
- Recall at operational threshold (safety-critical)
- False alarm rate by zone/disaster type

Also track fairness/coverage slices:

- urban vs rural
- high-signal vs low-signal zones
- disaster category segments

---

## 12) Thresholding Strategy (Ops-Friendly)

Convert probability to action bands:

- `>= 0.85`: Immediate escalation
- `0.65 - 0.84`: Priority watch + human review
- `0.45 - 0.64`: Monitor + collect more signals
- `< 0.45`: Low confidence, no automatic escalation

Tune thresholds with real ops feedback, not only offline metrics.

---

## 13) Data Quality and Leakage Checklist

Before every training run:

- No future fields in features
- No duplicate incidents across train/test
- Timestamp normalization to UTC
- Coordinate sanity checks (lat/lng bounds)
- Missing value strategy documented
- Label generation reproducible from code

If any check fails, block model release.

---

## 14) Fallback Mode (When Model Is Unavailable)

Implement a deterministic confidence function:

- weighted source agreement
- weather severity contribution
- grid risk contribution
- EONET proximity boost
- penalty for single-source reports

This keeps API responsive and safe.

Return:

- `fallback_used: true`
- `model_version: "rules_v1"`

---

## 15) Versioning and Audit

For each inference, store:

- `event_id`
- `model_version`
- `feature_set_version`
- `base_confidence`
- `final_confidence`
- `reasons`
- `fallback_used`
- `timestamp`

For each training run, store:

- dataset version/hash
- code commit hash
- hyperparameters
- metrics
- release decision

This is mandatory for post-incident analysis.

---

## 16) Suggested 7-Day Execution Plan

### Day 1-2

- Freeze target label definition
- Build dataset extraction + EONET join
- Generate `train_dataset_v1`

### Day 3

- Train LightGBM baseline
- Run time-split and geo-slice evaluation

### Day 4

- Add isotonic calibration
- Define threshold bands with team

### Day 5

- Build `/ml/confidence/score` API integration
- Add fallback rules and logging

### Day 6

- Shadow mode: score live traffic without acting
- Compare predicted confidence vs outcomes

### Day 7

- Enable production actioning with conservative thresholds
- Start monitoring dashboard for drift/calibration

---

## 17) Final Recommendation

For ResQNet+ backend using EONET + internal incident signals:

- Train **LightGBM** as primary classifier
- Calibrate with **Isotonic Regression**
- Serve confidence via backend scoring API
- Keep **rule-based fallback** active at all times
- Re-train on rolling schedule with strict evaluation gates

This gives you fast delivery, strong performance, explainable confidence, and production safety.