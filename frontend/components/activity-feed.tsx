import { ActivityLogEntry } from "../lib/types";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { ScrollArea } from "./ui/scroll-area";

type ActivityFeedProps = {
  entries: ActivityLogEntry[];
  onSelectEntry?: (entry: ActivityLogEntry) => void;
};

export function ActivityFeed({ entries, onSelectEntry }: ActivityFeedProps) {
  return (
    <Card motion="surface">
      <CardHeader>
        <CardTitle>Recent Updates</CardTitle>
      </CardHeader>
      <CardContent className="h-64 p-0">
        <ScrollArea className="h-full">
          <div className="space-y-2 p-4">
            {entries.length === 0 ? (
              <p className="text-sm text-white/55">
                No updates yet. New field reports will appear here.
              </p>
            ) : null}
            {entries.map((entry) => (
              <button
                key={entry.id}
                type="button"
                onClick={() => onSelectEntry?.(entry)}
                className="motion-pressable w-full rounded-xl border border-white/10 bg-white/2 p-3 text-left hover:-translate-y-0.5 hover:bg-white/5 focus-visible:ring-2 focus-visible:ring-cyan-200/60 focus-visible:ring-offset-0 focus-visible:outline-none active:translate-y-0"
              >
                <div className="mb-1 text-xs font-mono text-white/45">
                  {entry.timestamp}
                </div>
                <div className="text-sm text-white/82">{entry.message}</div>
              </button>
            ))}
          </div>
        </ScrollArea>
      </CardContent>
    </Card>
  );
}
