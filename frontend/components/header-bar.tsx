"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Brain, RefreshCw, ScanLine } from "lucide-react";
import { Button } from "./ui/button";

type HeaderBarProps = {
  onRefresh: () => void;
};

export function HeaderBar({ onRefresh }: HeaderBarProps) {
  const [clock, setClock] = useState("");
  const pathname = usePathname();
  const nav = [
    { href: "/dashboard", label: "Dashboard" },
    { href: "/incidents", label: "Incidents" },
    { href: "/responders", label: "Responders" },
    { href: "/map", label: "Map" },
    { href: "/nfc", label: "NFC" },
    { href: "/ai-insights", label: "AI Insights" },
  ];

  useEffect(() => {
    const tick = () => {
      setClock(
        new Date().toLocaleString("en-IN", {
          hour12: false,
          day: "2-digit",
          month: "short",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
          second: "2-digit",
        }),
      );
    };

    tick();
    const interval = setInterval(tick, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <header className="sticky top-0 z-40 flex h-[68px] items-center justify-between border-b border-white/[0.08] bg-black/25 px-5 shadow-[0_1px_0_rgba(255,255,255,0.04)] backdrop-blur-xl sm:px-6">
      <div className="flex items-center gap-5">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.28em] text-white/55 uppercase">
            RESQNET+
          </p>
          <p className="text-sm font-medium tracking-tight text-white/90">
            Dashboard
          </p>
        </div>
        <div className="hidden h-5 w-px bg-white/[0.08] lg:block" />
        <nav className="hidden items-center gap-0.5 lg:flex">
          {nav.map((item) => {
            const active =
              item.href === "/nfc"
                ? pathname.startsWith("/nfc")
                : pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={[
                  "group relative inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-[10px] font-medium uppercase tracking-[0.14em] transition-[background-color,color,border-color] duration-150 ease-out",
                  active
                    ? "bg-cyan-300/10 text-cyan-100"
                    : "text-white/48 hover:bg-white/[0.05] hover:text-white/75",
                ].join(" ")}
              >
                {item.href === "/ai-insights" ? (
                  <Brain
                    className={`h-3 w-3 shrink-0 ${active ? "text-cyan-300" : "text-white/35 group-hover:text-white/55"}`}
                    aria-hidden
                  />
                ) : null}
                {item.href === "/nfc" ? (
                  <ScanLine
                    className={`h-3 w-3 shrink-0 ${active ? "text-cyan-300" : "text-white/35 group-hover:text-white/55"}`}
                    aria-hidden
                  />
                ) : null}
                {item.label}
                {active && (
                  <span className="absolute bottom-0.5 left-1/2 h-0.5 w-3 -translate-x-1/2 rounded-full bg-cyan-300/70" />
                )}
              </Link>
            );
          })}
        </nav>
      </div>

      <div className="flex items-center gap-2.5">
        <div className="hidden md:flex md:items-center md:gap-2.5">
          <div className="inline-flex items-center gap-1.5 rounded-full border border-emerald-400/20 bg-emerald-400/8 px-2.5 py-1">
            <span className="status-dot-live h-1.5 w-1.5 rounded-full bg-emerald-300 shadow-[0_0_6px_rgba(110,231,183,0.7)]" />
            <span className="text-[9px] font-semibold tracking-[0.16em] text-emerald-200/80 uppercase">
              Field team online
            </span>
          </div>
          <div className="hidden items-center gap-1.5 xl:flex">
            <p className="text-[9px] uppercase tracking-[0.18em] text-white/35">
              Local
            </p>
            <p className="font-mono text-[11px] tabular-nums text-white/65">
              {clock}
            </p>
          </div>
        </div>
        <div className="h-4 w-px bg-white/[0.08]" />
        <Button
          onClick={onRefresh}
          size="sm"
          variant="ghost"
          className="gap-1.5 text-white/55 hover:text-white/85"
        >
          <RefreshCw className="h-3.5 w-3.5" />
          <span className="hidden sm:inline">Refresh</span>
        </Button>
      </div>
    </header>
  );
}
