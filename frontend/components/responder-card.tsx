import { ResponderRecord } from "@/lib/ops-types";
import { Button } from "./ui/button";
import { StatusPill } from "./status-pill";
import { Clock, MapPin, User } from "lucide-react";

type ResponderCardProps = {
  responder: ResponderRecord;
  onAssign: (id: string) => void;
};

function statusBorderColor(
  availability: ResponderRecord["availability"],
): string {
  switch (availability) {
    case "Ready":
      return "border-l-emerald-400";
    case "En Route":
      return "border-l-cyan-400";
    case "Deployed":
      return "border-l-red-400";
    case "Offline":
      return "border-l-slate-500";
    default:
      return "border-l-white/20";
  }
}

export function ResponderCard({ responder, onAssign }: ResponderCardProps) {
  return (
    <article
      className={`motion-surface flex flex-col rounded-2xl border border-white/[0.09] border-l-[3px] bg-black/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)] ${statusBorderColor(responder.availability)}`}
    >
      {/* Header row */}
      <div className="flex items-start justify-between gap-3 px-4 pt-4">
        <div className="min-w-0">
          <p className="text-[10px] uppercase tracking-[0.16em] text-white/35">
            {responder.id}
          </p>
          <h3 className="mt-0.5 truncate text-base font-bold text-white">
            {responder.name}
          </h3>
        </div>
        <div className="shrink-0 pt-0.5">
          <StatusPill status={responder.availability} />
        </div>
      </div>

      {/* Unit + specialization row */}
      <div className="mt-2.5 flex flex-wrap items-center gap-2 px-4">
        <span className="inline-flex items-center gap-1 rounded-md border border-white/[0.09] bg-white/[0.05] px-2 py-0.5 text-[10px] font-semibold uppercase tracking-[0.12em] text-white/60">
          <User className="h-2.5 w-2.5" />
          {responder.unit}
        </span>
        <span className="text-xs capitalize text-white/45">
          {responder.specialization}
        </span>
      </div>

      {/* Stats row */}
      <div className="mt-3 space-y-1.5 border-t border-white/[0.07] px-4 pt-3">
        <div className="flex items-center gap-2 text-xs text-white/55">
          <Clock className="h-3.5 w-3.5 shrink-0 text-white/30" />
          <span>
            ETA:{" "}
            <span className="font-medium text-white/80">{responder.eta}</span>
          </span>
        </div>
        <div className="flex items-start gap-2 text-xs text-white/55">
          <MapPin className="mt-px h-3.5 w-3.5 shrink-0 text-white/30" />
          <span className="font-mono text-[11px] text-white/40">
            {responder.lat.toFixed(4)}, {responder.lng.toFixed(4)}
          </span>
        </div>
        {responder.currentStatus ? (
          <p className="truncate text-[11px] text-white/40">
            {responder.currentStatus}
          </p>
        ) : null}
      </div>
    </article>
  );
}
