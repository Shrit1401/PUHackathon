import { useEffect, useMemo, useState } from "react";
import { DisasterEvent } from "../lib/types";
import {
  fetchWeatherForecast,
  WeatherForecastPoint,
  WeatherForecastResponse,
} from "../lib/api";
import { getWeatherSeverityLabel } from "../lib/disaster-utils";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Progress } from "./ui/progress";
import { Skeleton } from "./ui/skeleton";

type WeatherForecastPanelProps = {
  event?: DisasterEvent;
  onSeverityChange?: (value: number | null) => void;
};

type SimplifiedForecast = {
  time: string;
  description: string;
  temp: number;
  severityScore: number;
};

function computeSeverityScore(point: WeatherForecastPoint): number {
  const rainValues = point.rain ? Object.values(point.rain) : [];
  const rain = rainValues.length > 0 ? rainValues[0] : 0;
  const wind = point.wind?.speed ?? 0;
  const main = point.weather[0]?.main ?? "";

  let base = 0;
  if (main === "Clear") base = 1;
  else if (main === "Clouds") base = 2;
  else if (main === "Drizzle") base = 3;
  else if (main === "Snow") base = 4;
  else if (main === "Rain") base = 5;
  else if (main === "Thunderstorm") base = 7;
  else if (main === "Extreme" || main === "Tornado") base = 9;

  const rainComponent = Math.min(3, rain / 3);
  const windComponent = Math.min(3, wind / 5);

  let score = base + rainComponent + windComponent;

  if (main === "Thunderstorm") {
    score = Math.max(score, 8);
  }

  if (main === "Extreme" || main === "Tornado") {
    score = 10;
  }

  return Math.max(0, Math.min(10, Number(score.toFixed(1))));
}

export function WeatherForecastPanel({
  event,
  onSeverityChange,
}: WeatherForecastPanelProps) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [forecast, setForecast] = useState<WeatherForecastResponse | null>(
    null,
  );

  useEffect(() => {
    if (!event) {
      setForecast(null);
      setError(null);
      return;
    }

    let cancelled = false;

    async function load() {
      try {
        setLoading(true);
        setError(null);
        const data = await fetchWeatherForecast(
          event?.location.lat ?? 0,
          event?.location.lng ?? 0,
        );
        if (!cancelled) {
          setForecast(data);
        }
      } catch (err) {
        if (!cancelled) {
          setError("Unable to load forecast");
          setForecast(null);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    load();

    return () => {
      cancelled = true;
    };
  }, [event]);

  const simplified = useMemo<SimplifiedForecast[]>(() => {
    if (!forecast) return [];
    return forecast.list.slice(0, 4).map((point) => {
      const score = computeSeverityScore(point);
      const time = new Date(point.dt * 1000).toLocaleTimeString("en-IN", {
        hour12: false,
        hour: "2-digit",
        minute: "2-digit",
      });

      return {
        time,
        description: point.weather[0]?.description ?? "Unknown",
        temp: point.main.temp,
        severityScore: score,
      };
    });
  }, [forecast]);

  const maxSeverity = useMemo(() => {
    if (!simplified.length) return null;
    return simplified.reduce(
      (max, point) => (point.severityScore > max ? point.severityScore : max),
      simplified[0].severityScore,
    );
  }, [simplified]);

  useEffect(() => {
    if (!onSeverityChange) return;
    onSeverityChange(maxSeverity);
  }, [maxSeverity, onSeverityChange]);

  if (!event) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Weather Forecast</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-slate-400">
            Select an event to see the forecast for that zone.
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Weather Forecast</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {loading ? (
          <div className="space-y-3">
            <div className="flex items-center justify-between text-xs text-slate-400">
              <Skeleton className="h-4 w-32" />
              <Skeleton className="h-4 w-40" />
            </div>
            <Skeleton className="h-2 w-full rounded-full" />
            <div className="space-y-2">
              {Array.from({ length: 3 }).map((_, index) => (
                <div
                  key={index}
                  className="flex items-center justify-between rounded-md border border-white/5 bg-slate-950/70 px-2 py-1.5"
                >
                  <div className="flex flex-col gap-1">
                    <Skeleton className="h-3 w-20" />
                    <Skeleton className="h-3 w-32" />
                  </div>
                  <div className="flex flex-col items-end gap-1">
                    <Skeleton className="h-3 w-16" />
                    <Skeleton className="h-3 w-16" />
                  </div>
                </div>
              ))}
            </div>
          </div>
        ) : error ? (
          <p className="text-sm text-red-400">{error}</p>
        ) : simplified.length === 0 || maxSeverity == null ? (
          <p className="text-sm text-slate-400">
            No forecast data available for this location.
          </p>
        ) : (
          <>
            <div className="flex items-center justify-between text-xs text-slate-400">
              <span>Next 12–24h severity</span>
              <span className="font-mono text-slate-200">
                {getWeatherSeverityLabel(maxSeverity)} ({maxSeverity.toFixed(1)}
                /10)
              </span>
            </div>
            <Progress value={(maxSeverity / 10) * 100} />
            <div className="space-y-2 text-xs">
              {simplified.map((point) => (
                <div
                  key={point.time}
                  className="flex items-center justify-between rounded-md border border-white/5 bg-slate-950/70 px-2 py-1.5"
                >
                  <div className="flex flex-col gap-0.5">
                    <span className="font-mono text-[11px] text-slate-400">
                      {point.time}
                    </span>
                    <span className="text-[11px] capitalize text-slate-200">
                      {point.description}
                    </span>
                  </div>
                  <div className="flex flex-col items-end gap-0.5">
                    <span className="font-mono text-[11px] text-slate-300">
                      {point.temp.toFixed(1)}°C
                    </span>
                    <span className="font-mono text-[11px] text-slate-400">
                      {point.severityScore.toFixed(1)}/10
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
