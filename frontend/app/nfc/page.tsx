import Link from "next/link";
import { ArrowRight, ContactRound, Radio, ScanLine } from "lucide-react";

export default function NfcHubPage() {
  return (
    <main className="relative min-h-screen overflow-hidden bg-[#05060a] text-[#f0f4f8]">
      <div className="lp-ambient pointer-events-none absolute inset-0 -z-10" />
      <div className="lp-orbit pointer-events-none absolute inset-0 -z-10" />
      <div className="lp-grain pointer-events-none absolute inset-0 -z-10" />
      <div className="pointer-events-none absolute inset-x-0 top-0 -z-10 h-[min(52vh,520px)] bg-[radial-gradient(ellipse_80%_60%_at_50%_-10%,rgba(56,189,248,0.12),transparent_55%)]" />

      <header className="lp-reveal-nfc relative z-10 mx-auto flex w-full max-w-5xl items-center justify-between px-6 pt-8 sm:px-10">
        <Link
          href="/"
          className="nfc-press group flex items-center gap-3 rounded-full border border-white/[0.08] bg-white/[0.03] px-3 py-2 pr-4 text-[10px] font-semibold tracking-[0.22em] text-white/55 uppercase hover:border-white/[0.14] hover:bg-white/[0.06] hover:text-white/80"
        >
          <img src="/img.png" alt="ResQNet" className="h-7 w-7 opacity-90" />
          <span>ResQNet+</span>
        </Link>
        <Link
          href="/dashboard"
          className="nfc-press rounded-full border border-cyan-400/20 bg-cyan-400/[0.06] px-4 py-2 text-[10px] font-semibold tracking-[0.18em] text-cyan-100/90 uppercase hover:border-cyan-400/35 hover:bg-cyan-400/12"
        >
          Dashboard
        </Link>
      </header>

      <div className="relative z-10 mx-auto max-w-5xl px-6 pb-20 pt-14 sm:px-10">
        <div className="lp-reveal-nfc [animation-delay:60ms] mb-14 text-center sm:text-left">
          <div className="mb-5 inline-flex items-center gap-2 rounded-full border border-cyan-400/20 bg-cyan-400/[0.07] px-3.5 py-1.5">
            <span className="relative flex h-2 w-2">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-cyan-300/50 opacity-60" />
              <span className="relative inline-flex h-2 w-2 rounded-full bg-cyan-300 shadow-[0_0_10px_rgba(103,232,249,0.8)]" />
            </span>
            <span className="text-[10px] font-medium tracking-[0.2em] text-cyan-100/85 uppercase">
              Field telemetry
            </span>
          </div>
          <h1 className="font-[family-name:var(--font-syne),sans-serif] text-[clamp(2.25rem,6vw,3.75rem)] font-semibold leading-[0.95] tracking-[-0.035em] text-white">
            Near-field,
            <br />
            <span className="text-white/38">full context.</span>
          </h1>
          <p className="mx-auto mt-6 max-w-xl text-base leading-relaxed text-white/52 sm:mx-0">
            Every tap on an emergency tag becomes auditable signal: who was read,
            when, and which medical snapshot was available to responders.
          </p>
        </div>

        <div className="relative mx-auto mb-16 flex max-w-md justify-center sm:max-w-none">
          <div
            className="lp-reveal-nfc [animation-delay:120ms] relative flex aspect-square w-[min(100%,280px)] items-center justify-center"
            aria-hidden
          >
            <div className="nfc-field-ring absolute inset-0 rounded-full border border-cyan-400/25" />
            <div className="nfc-field-ring nfc-field-ring--lag absolute inset-[12%] rounded-full border border-emerald-300/20" />
            <div className="nfc-field-ring nfc-field-ring--lag2 absolute inset-[24%] rounded-full border border-sky-300/18" />
            <div className="absolute inset-[34%] rounded-full bg-[radial-gradient(circle_at_30%_30%,rgba(255,255,255,0.12),transparent_55%)] shadow-[inset_0_1px_0_rgba(255,255,255,0.08),0_0_60px_-12px_rgba(56,189,248,0.35)] ring-1 ring-white/10" />
            <ScanLine
              className="relative z-[1] h-14 w-14 text-cyan-200/90 drop-shadow-[0_0_24px_rgba(103,232,249,0.45)]"
              strokeWidth={1.25}
            />
          </div>
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          <Link
            href="/nfc/scans"
            className="lp-reveal-nfc group relative overflow-hidden rounded-3xl border border-white/[0.09] bg-white/[0.03] p-8 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)] transition-[transform,border-color,background-color,box-shadow] duration-200 [animation-delay:180ms] [transition-timing-function:cubic-bezier(0.23,1,0.32,1)] hover:border-cyan-400/25 hover:bg-white/[0.05] hover:shadow-[0_24px_64px_-28px_rgba(0,0,0,0.75)] active:scale-[0.985] sm:active:scale-[0.99] motion-reduce:transition-none motion-reduce:hover:transform-none"
          >
            <div className="pointer-events-none absolute -right-8 -top-8 h-32 w-32 rounded-full bg-cyan-400/10 blur-2xl transition-opacity duration-300 group-hover:opacity-100" />
            <Radio className="mb-5 h-8 w-8 text-cyan-300/80" strokeWidth={1.25} />
            <h2 className="font-[family-name:var(--font-syne),sans-serif] text-xl font-semibold tracking-tight text-white">
              Scan log
            </h2>
            <p className="mt-2 text-sm leading-relaxed text-white/48">
              Filter ingested reads by holder UUID, inspect snapshots, and open
              public emergency cards.
            </p>
            <span className="mt-6 inline-flex items-center gap-2 text-[11px] font-semibold tracking-[0.14em] text-cyan-200/90 uppercase">
              Open feed
              <ArrowRight className="h-3.5 w-3.5 transition-transform duration-200 [transition-timing-function:cubic-bezier(0.23,1,0.32,1)] group-hover:translate-x-0.5" />
            </span>
          </Link>

          <div className="lp-reveal-nfc rounded-3xl border border-white/[0.07] bg-black/25 p-8 shadow-[inset_0_1px_0_rgba(255,255,255,0.04)] [animation-delay:230ms]">
            <ContactRound
              className="mb-5 h-8 w-8 text-emerald-300/75"
              strokeWidth={1.25}
            />
            <h2 className="font-[family-name:var(--font-syne),sans-serif] text-xl font-semibold tracking-tight text-white">
              Public cards
            </h2>
            <p className="mt-2 text-sm leading-relaxed text-white/48">
              Emergency profiles are served at{" "}
              <code className="rounded-md border border-white/10 bg-white/[0.04] px-1.5 py-0.5 font-mono text-[11px] text-emerald-200/85">
                /profile/[userId]
              </code>
              . Share the URL or QR printed on a physical tag.
            </p>
            <p className="mt-5 text-[11px] leading-relaxed text-white/35">
              No login required for the public view—operators use the scan log to
              audit taps against the API.
            </p>
          </div>
        </div>

        <p className="lp-reveal-nfc mt-14 text-center text-[10px] tracking-[0.12em] text-white/28 [animation-delay:280ms] sm:text-left">
          ResQNet+ NFC · Encrypted backend ingest · Realtime dashboard
        </p>
      </div>
    </main>
  );
}
