import { IncidentRecord } from "@/lib/ops-types";
import { Activity } from "lucide-react";

type IncidentTableProps = {
  rows: IncidentRecord[];
  onView: (id: string) => void;
  selectedId?: string;
};

function PriorityChip({ priority }: { priority: IncidentRecord["priority"] }) {
  const styles: Record<IncidentRecord["priority"], string> = {
    Critical: "bg-red-500/15 text-red-200 border border-red-400/25",
    High:     "bg-orange-500/[0.12] text-orange-200 border border-orange-400/[0.22]",
    Medium:   "bg-amber-500/[0.12] text-amber-200 border border-amber-400/[0.22]",
    Low:      "bg-slate-500/15 text-slate-300 border border-slate-400/20",
  };
  return (
    <span className={`inline-flex items-center rounded-md px-1.5 py-0.5 text-[10px] font-semibold ${styles[priority]}`}>
      {priority}
    </span>
  );
}

export function IncidentTable({ rows, onView, selectedId }: IncidentTableProps) {
  return (
    <div className="overflow-hidden rounded-2xl border border-white/[0.09] bg-black/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)]">
      <div className="max-h-[62vh] overflow-auto">
        <table className="w-full min-w-[860px] table-fixed text-left">
          <thead className="sticky top-0 z-10 border-b border-white/[0.09] bg-slate-950/60 backdrop-blur-sm">
            <tr className="text-[10px] uppercase tracking-[0.18em] text-white/40">
              <th className="w-[20%] px-4 py-3 font-semibold">Incident Type</th>
              <th className="w-[13%] px-4 py-3 font-semibold">Incident ID</th>
              <th className="w-[22%] px-4 py-3 font-semibold">Location</th>
              <th className="w-[15%] px-4 py-3 font-semibold">Created</th>
              <th className="w-[9%] px-4 py-3 font-semibold">Priority</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-4 py-16 text-center">
                  <div className="flex flex-col items-center gap-3">
                    <div className="flex h-10 w-10 items-center justify-center rounded-xl border border-white/[0.09] bg-white/[0.04]">
                      <Activity className="h-5 w-5 text-white/25" />
                    </div>
                    <div>
                      <p className="text-sm font-medium text-white/60">No active incidents</p>
                      <p className="mt-1 text-xs text-white/30">
                        New incidents will appear here automatically when they are created.
                      </p>
                    </div>
                  </div>
                </td>
              </tr>
            ) : (
              rows.map((row) => (
                <tr
                  key={row.id}
                  onClick={() => onView(row.id)}
                  className={
                    row.id === selectedId
                      ? "cursor-pointer border-b border-white/[0.05] border-l-2 border-l-cyan-400/70 bg-cyan-500/[0.06] text-sm text-white transition"
                      : row.isSos
                        ? "cursor-pointer border-b border-white/[0.05] border-l-2 border-l-red-400/70 bg-red-500/[0.05] text-sm text-white/90 transition hover:bg-red-500/[0.09]"
                        : "cursor-pointer border-b border-white/[0.05] text-sm text-white/85 transition hover:bg-white/[0.035]"
                  }
                >
                  <td className="px-4 py-3 align-top">
                    <div className="flex flex-wrap items-center gap-2 break-words font-medium capitalize">
                      <span>{row.incidentType || "Unknown"}</span>
                      {row.isSos ? (
                        <span className="inline-flex items-center rounded-md border border-red-400/30 bg-red-500/15 px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-[0.10em] text-red-200">
                          SOS
                        </span>
                      ) : null}
                    </div>
                  </td>
                  <td className="px-4 py-3 align-top">
                    <div className="break-all font-mono text-[11px] text-white/50">{row.id}</div>
                  </td>
                  <td className="px-4 py-3 align-top text-xs text-white/65">
                    <span className="break-words">{row.location || "Location unavailable"}</span>
                  </td>
                  <td className="px-4 py-3 align-top font-mono text-[11px] text-white/50">
                    <span className="break-words">{row.createdAt || "N/A"}</span>
                  </td>
                  <td className="px-4 py-3 align-top">
                    <PriorityChip priority={row.priority} />
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
