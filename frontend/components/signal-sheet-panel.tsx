import { SignalSheetRow } from "../lib/types";
import { getSeverityLabel } from "../lib/disaster-utils";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { ScrollArea } from "./ui/scroll-area";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "./ui/table";

type SignalSheetPanelProps = {
  rows: SignalSheetRow[];
};

const sourceTag: Record<SignalSheetRow["source"], string> = {
  News: "bg-slate-800 text-slate-200",
  Social: "bg-sky-950 text-sky-200",
  App: "bg-emerald-950 text-emerald-200",
  WhatsApp: "bg-green-950 text-green-200",
};

export function SignalSheetPanel({ rows }: SignalSheetPanelProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Signal Data Sheet</CardTitle>
      </CardHeader>
      <CardContent className="h-72 p-0">
        <ScrollArea className="h-full">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Time</TableHead>
                <TableHead>Source</TableHead>
                <TableHead>Zone</TableHead>
                <TableHead>Details</TableHead>
                <TableHead>Risk</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((row) => (
                <TableRow key={row.id}>
                  <TableCell className="font-mono text-slate-400">{row.timestamp}</TableCell>
                  <TableCell>
                    <span className={["rounded px-2 py-1 text-[11px]", sourceTag[row.source]].join(" ")}>
                      {row.source}
                    </span>
                  </TableCell>
                  <TableCell>{row.zone}</TableCell>
                  <TableCell className="max-w-[280px] text-slate-300">{row.detail}</TableCell>
                  <TableCell>{getSeverityLabel(row.severity)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </ScrollArea>
      </CardContent>
    </Card>
  );
}
