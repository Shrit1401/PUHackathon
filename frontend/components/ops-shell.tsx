import { HeaderBar } from "./header-bar";
import { ChevronRight } from "lucide-react";

type OpsShellProps = {
  title: string;
  subtitle: string;
  /** Optional extra line under the subtitle for narrative context */
  lede?: string;
  tag?: string;
  children: React.ReactNode;
  onRefresh?: () => void;
};

export function OpsShell({
  title,
  subtitle,
  lede,
  tag = "Live feed active",
  children,
  onRefresh,
}: OpsShellProps) {
  return (
    <div className="relative min-h-screen overflow-hidden bg-[#05060a] text-slate-100">
      <div className="lp-ambient pointer-events-none absolute inset-0 -z-10" />
      <div className="lp-orbit pointer-events-none absolute inset-0 -z-10" />
      <div className="lp-grain pointer-events-none absolute inset-0 -z-10" />
      <div className="pointer-events-none absolute inset-x-0 top-0 -z-10 h-40 bg-[radial-gradient(ellipse_at_top,rgba(56,189,248,0.07),transparent_70%)]" />
      <HeaderBar onRefresh={onRefresh ?? (() => undefined)} />

      {/* Top bar */}
      <div className="border-b border-white/[0.07] bg-black/20 shadow-[inset_0_-1px_0_rgba(255,255,255,0.04)] backdrop-blur-md">
        <div className="mx-auto flex w-full max-w-[1560px] items-center justify-between gap-4 px-4 py-3.5">
          {/* Left: breadcrumb + title */}
          <div className="min-w-0">
            <div className="flex items-center gap-1.5 text-[10px] uppercase tracking-[0.18em] text-white/35">
              <span>ResQNet+</span>
              <ChevronRight className="h-3 w-3 shrink-0 text-white/20" />
              <span className="text-white/50">{title}</span>
            </div>
            <div className="mt-1 flex flex-wrap items-baseline gap-3">
              <h1 className="text-lg font-bold tracking-tight text-white sm:text-xl">{title}</h1>
              <p className="hidden text-sm text-white/45 sm:block">{subtitle}</p>
            </div>
            {lede ? (
              <p className="mt-1 max-w-2xl text-xs leading-relaxed text-white/35">{lede}</p>
            ) : null}
          </div>

          {/* Right: live tag */}
          <div className="flex shrink-0 items-center gap-2 rounded-lg border border-white/[0.09] bg-black/30 px-3 py-1.5 text-[10px] font-semibold uppercase tracking-[0.16em] text-white/50 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)]">
            <span className="inline-flex h-1.5 w-1.5 animate-pulse rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.7)]" />
            {tag}
          </div>
        </div>
      </div>

      <main className="px-4 pt-4 pb-8 sm:px-6">
        <div className="mx-auto w-full max-w-[1560px] space-y-4">
          {children}
        </div>
      </main>
    </div>
  );
}
