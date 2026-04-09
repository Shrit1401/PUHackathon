import { DisasterEvent } from "../lib/types";
import { getWeatherSeverityLabel } from "../lib/disaster-utils";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Progress } from "./ui/progress";

type ConfidencePanelProps = {
  event?: DisasterEvent;
  weatherSeverity?: number | null;
};

export function EventDetailsPanel({ event, weatherSeverity }: ConfidencePanelProps) {
  if (!event) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Decision Confidence</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-slate-400">Select an event from the map.</p>
        </CardContent>
      </Card>
    );
  }

  const score =
    typeof weatherSeverity === "number" ? weatherSeverity : event.weatherSeverity;

  return (
    <Card>
      <CardHeader>
        <CardTitle>Decision Confidence</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <div>
          <p className="text-sm text-white/72">{event.name}</p>
          <p className="text-4xl font-semibold text-white/92">
            {event.confidenceScore}%
          </p>
        </div>
        <Progress value={event.confidenceScore} />
        <div className="flex items-center justify-between text-xs text-white/55">
          <span>Weather severity</span>
          <span className="font-mono text-white/82">
            {getWeatherSeverityLabel(score)} ({score.toFixed(1)}/10)
          </span>
        </div>
        <p className="text-xs text-white/58">
          Confidence blends field reports, media signals, and forecast stress so teams can prioritize help faster.
        </p>
      </CardContent>
    </Card>
  );
}
