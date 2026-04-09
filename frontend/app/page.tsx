import Link from "next/link";
import Image from "next/image";
import { Sora, Syne } from "next/font/google";
import {
  ArrowRight,
  Download,
  Smartphone,
  Wifi,
  ShieldCheck,
  Zap,
} from "lucide-react";

const sora = Sora({ subsets: ["latin"], variable: "--font-sora" });
const syne = Syne({ subsets: ["latin"], variable: "--font-syne" });

const stats = [
  { label: "Signal refresh", value: "12s" },
  { label: "Regions covered", value: "30+" },
  { label: "Model accuracy", value: "93.4%" },
];

const WHATSAPP_BOT_URL =
  "https://wa.me/+14155238886?text=join%20many-tool";

function WhatsAppIcon({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden
    >
      <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.435 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z" />
    </svg>
  );
}

const appFeatures = [
  {
    icon: ShieldCheck,
    label: "Emergency SOS",
    desc: "One-tap distress with auto location",
  },
  { icon: Wifi, label: "NFC Scan", desc: "Scan responder tags instantly" },
  {
    icon: Zap,
    label: "Live Alerts",
    desc: "Real-time risk push notifications",
  },
  {
    icon: Smartphone,
    label: "Health AI",
    desc: "Guided first-aid & triage advice",
  },
];

export default function LandingPage() {
  return (
    <main
      className={`${sora.variable} ${syne.variable} relative min-h-screen overflow-hidden bg-[#06070b] text-[#f5f5ef]`}
    >
      <div className="lp-ambient pointer-events-none absolute inset-0" />
      <div className="lp-orbit pointer-events-none absolute inset-0" />
      <div className="lp-grain pointer-events-none absolute inset-0" />

      <div className="mx-auto flex min-h-screen w-full max-w-6xl flex-col px-6 pb-16 pt-8 sm:px-10 lg:px-16">
        {/* Nav */}
        <header className="lp-reveal flex items-center justify-between">
          <div className="flex items-center gap-3">
            <img src="/img.png" alt="ResQNet" className="h-8" />
            <p className="font-[var(--font-syne)] text-sm tracking-[0.25em] text-white/70 uppercase">
              RESQNET+
            </p>
          </div>
          <Link
            href="/dashboard"
            className="rounded-full border border-white/15 bg-white/5 px-4 py-2 text-xs tracking-[0.2em] text-white/80 uppercase transition hover:bg-white/10 hover:text-white"
          >
            Dashboard
          </Link>
        </header>

        {/* Hero */}
        <section className="my-auto grid gap-12 py-14 lg:grid-cols-[1.1fr_0.9fr] lg:items-center">
          <div className="lp-reveal [animation-delay:120ms]">
            <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-[#d2f6c5]/20 bg-[#d2f6c5]/8 px-3.5 py-1.5">
              <span className="h-1.5 w-1.5 rounded-full bg-[#d2f6c5] shadow-[0_0_8px_rgba(210,246,197,0.8)]" />
              <p className="text-[10px] tracking-[0.2em] text-[#d2f6c5]/85 uppercase font-medium">
                Live Disaster Intelligence
              </p>
            </div>

            <h1 className="max-w-2xl font-[var(--font-syne)] text-5xl leading-[0.93] tracking-[-0.03em] text-[#f7f7f2] sm:text-6xl lg:text-[4.5rem]">
              Clarity in chaos,
              <br />
              <span className="text-white/40">in real time.</span>
            </h1>

            <p className="mt-7 max-w-lg text-base leading-relaxed text-white/60">
              A command surface for teams tracking risk signals, validating
              impact, and making fast calls when every minute matters.
            </p>

            <div className="mt-10 flex flex-wrap gap-3">
              <Link
                href="/dashboard"
                className="group inline-flex items-center gap-2 rounded-full bg-[#e5ffd4] px-6 py-3 text-sm font-semibold text-[#111411] transition hover:-translate-y-0.5 hover:bg-[#efffe4] hover:shadow-[0_4px_20px_rgba(110,231,183,0.32)]"
              >
                Open Platform
                <ArrowRight className="size-4 transition group-hover:translate-x-0.5" />
              </Link>
              <a
                href="#download"
                className="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/5 px-6 py-3 text-sm font-medium text-white/80 transition hover:bg-white/10 hover:text-white"
              >
                <Download className="size-4" />
                Get the App
              </a>
              <a
                href={WHATSAPP_BOT_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 rounded-full border border-[#25D366]/35 bg-[#25D366]/10 px-6 py-3 text-sm font-medium text-[#b8f5cf] transition hover:border-[#25D366]/50 hover:bg-[#25D366]/18 hover:text-white"
              >
                <WhatsAppIcon className="size-4 shrink-0 text-[#25D366]" />
                WhatsApp bot
              </a>
            </div>

            {/* Stats */}
            <div className="mt-10 grid grid-cols-3 gap-3">
              {stats.map((stat) => (
                <div
                  key={stat.label}
                  className="rounded-2xl border border-white/[0.09] bg-white/[0.03] px-4 py-4"
                >
                  <p className="font-[var(--font-syne)] text-2xl font-semibold tracking-tight">
                    {stat.value}
                  </p>
                  <p className="mt-0.5 text-[11px] text-white/45">
                    {stat.label}
                  </p>
                </div>
              ))}
            </div>
          </div>

          {/* Signal card */}
          <div className="lp-reveal [animation-delay:240ms]">
            <div className="rounded-3xl border border-white/12 bg-black/35 p-6 backdrop-blur-xl shadow-[inset_0_1px_0_rgba(255,255,255,0.05),0_24px_64px_rgba(0,0,0,0.5)]">
              <div className="flex items-center gap-2 mb-4">
                <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 shadow-[0_0_8px_rgba(52,211,153,0.8)] animate-pulse" />
                <p className="text-[10px] tracking-[0.18em] text-white/40 uppercase font-medium">
                  Live Signal
                </p>
              </div>
              <p className="font-[var(--font-syne)] text-2xl leading-snug tracking-[-0.02em] text-white/90">
                Flood-risk pressure detected across 4 districts.
              </p>
              <p className="mt-3 text-sm text-white/50 leading-relaxed">
                Model confidence stable and trending upward over the last 20
                minutes.
              </p>
              <div className="mt-5 h-px bg-white/[0.07]" />
              <div className="mt-4 flex items-center justify-between">
                <span className="text-[11px] text-white/35">
                  Updated 4s ago
                </span>
                <Link
                  href="/dashboard"
                  className="flex items-center gap-1 text-[11px] text-cyan-400/80 hover:text-cyan-300 transition"
                >
                  View live <ArrowRight className="size-3" />
                </Link>
              </div>
            </div>
          </div>
        </section>

        {/* Mobile app section */}
        <section
          id="download"
          className="lp-reveal [animation-delay:360ms] mt-4 rounded-3xl border border-white/[0.09] bg-white/[0.025] overflow-hidden backdrop-blur-xl shadow-[inset_0_1px_0_rgba(255,255,255,0.05)]"
        >
          <div className="grid lg:grid-cols-2 items-center gap-0">
            {/* Left content */}
            <div className="px-8 py-10 sm:px-12">
              <p className="text-[10px] tracking-[0.22em] text-white/35 uppercase font-medium mb-4">
                Mobile App
              </p>
              <h2 className="font-[var(--font-syne)] text-3xl sm:text-4xl leading-tight tracking-[-0.025em] text-white/92 max-w-md">
                ResQNet+ in your pocket.
              </h2>
              <p className="mt-4 text-sm text-white/55 leading-relaxed max-w-sm">
                Emergency SOS, NFC responder scan, real-time alerts, and AI
                health triage — offline-capable and built for the field.
              </p>

              {/* Feature grid */}
              <div className="mt-8 grid grid-cols-2 gap-3 max-w-sm">
                {appFeatures.map(({ icon: Icon, label, desc }) => (
                  <div
                    key={label}
                    className="rounded-2xl border border-white/[0.08] bg-white/[0.03] p-3.5 hover:border-white/[0.13] hover:bg-white/[0.05] transition"
                  >
                    <Icon className="h-4 w-4 text-white/40 mb-2" />
                    <p className="text-xs font-semibold text-white/85">
                      {label}
                    </p>
                    <p className="mt-0.5 text-[10px] text-white/40 leading-relaxed">
                      {desc}
                    </p>
                  </div>
                ))}
              </div>

              {/* Download + WhatsApp */}
              <div className="mt-8 flex flex-wrap gap-3">
                <a
                  href="/api/download/apk"
                  download="ResQNet.apk"
                  className="group inline-flex items-center gap-3 rounded-2xl border border-[#3ddc84]/20 bg-[#3ddc84]/[0.07] px-5 py-3 transition-all duration-150 hover:border-[#3ddc84]/35 hover:bg-[#3ddc84]/[0.12] hover:-translate-y-px"
                >
                  {/* Google Play / Android icon */}
                  <svg
                    className="h-5 w-5 shrink-0 text-[#3ddc84]"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                  >
                    <path d="M3.18 23.76a2 2 0 0 0 2.73.73l10.02-5.79-2.9-2.9-9.85 7.96zm16.3-10.38L16.9 11.6 4.38.57A2 2 0 0 0 1.5 2.24v19.52a2 2 0 0 0 2.88 1.67l12.52-10.05zm2.34-1.35-3.47-2-3.09 3.09 3.09 3.09 3.5-2.02a2 2 0 0 0-.03-4.16zm-18.67-9L16.9 11.6l2.58-2.57L5.88.6A2 2 0 0 0 3.15 3z" />
                  </svg>
                  <span className="flex flex-col">
                    <span className="text-[9px] tracking-[0.2em] uppercase text-white/40">
                      Download APK for
                    </span>
                    <span className="text-sm font-semibold text-white leading-tight">
                      Android
                    </span>
                  </span>
                </a>
                <a
                  href={WHATSAPP_BOT_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group inline-flex items-center gap-3 rounded-2xl border border-[#25D366]/25 bg-[#25D366]/[0.08] px-5 py-3 transition-all duration-150 hover:border-[#25D366]/40 hover:bg-[#25D366]/[0.14] hover:-translate-y-px"
                >
                  <WhatsAppIcon className="h-5 w-5 shrink-0 text-[#25D366]" />
                  <span className="flex flex-col">
                    <span className="text-[9px] tracking-[0.2em] uppercase text-white/40">
                      Talk on WhatsApp
                    </span>
                    <span className="text-sm font-semibold text-white leading-tight">
                      Our bot
                    </span>
                  </span>
                </a>
              </div>
            </div>

            {/* Phone mockup — floating right */}
            <div className="relative hidden lg:flex items-center justify-center overflow-hidden min-h-[420px]">
              {/* layered glows */}
              <div
                className="absolute inset-0 pointer-events-none"
                style={{
                  background:
                    "radial-gradient(ellipse at 50% 55%, rgba(61,220,132,0.13) 0%, transparent 65%)",
                }}
              />
              <div
                className="absolute bottom-0 left-1/2 -translate-x-1/2 h-32 w-64 rounded-full blur-3xl pointer-events-none"
                style={{ background: "rgba(61,220,132,0.10)" }}
              />
              <Image
                src="/mobile.png"
                alt="ResQNet mobile app"
                width={520}
                height={420}
                className="relative w-full max-w-[520px] object-contain drop-shadow-[0_32px_64px_rgba(0,0,0,0.7)]"
                priority
              />
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="lp-reveal [animation-delay:480ms] mt-8 border-t border-white/[0.07] pt-6 flex items-center justify-between gap-4 flex-wrap">
          <div className="flex items-center gap-3">
            <img src="/img.png" alt="ResQNet" className="h-5 opacity-50" />
            <p className="text-[10px] text-white/30 tracking-wide">
              ResQNet+ · Disaster Intelligence Platform
            </p>
          </div>
          <p className="text-[10px] tracking-[0.14em] text-white/30 uppercase">
            InnovateX · Presidency University · Team Shrit, Saaheer, Induj,
            Kritgaya
          </p>
        </footer>
      </div>
    </main>
  );
}
