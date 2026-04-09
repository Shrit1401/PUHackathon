"use client";

type ReaderRailLink = {
  id: string;
  label: string;
  hint?: string;
};

type ReaderRailProps = {
  links: ReaderRailLink[];
  title?: string;
};

export function ReaderRail({ links, title = "On this page" }: ReaderRailProps) {
  function scrollToId(hash: string) {
    const el = document.getElementById(hash);
    el?.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  return (
    <nav
      aria-label="Page sections"
      className="read-rail flex flex-wrap items-center gap-3 rounded-2xl border border-white/[0.07] bg-black/25 px-4 py-3 shadow-[inset_0_1px_0_rgba(255,255,255,0.04)]"
    >
      <p className="text-[9.5px] font-semibold uppercase tracking-[0.22em] text-white/25 shrink-0">
        {title}
      </p>
      <div className="h-3 w-px bg-white/[0.08]" />
      <div className="flex flex-wrap gap-1.5">
        {links.map((link) => (
          <button
            key={link.id}
            type="button"
            onClick={() => scrollToId(link.id)}
            title={link.hint}
            className="read-rail-pill rounded-lg border border-white/[0.08] bg-white/[0.03] px-3 py-1.5 text-left text-[11px] font-medium text-white/50 transition-[background-color,border-color,color] duration-150 hover:border-white/[0.14] hover:bg-white/[0.06] hover:text-white/80 active:scale-[0.97]"
          >
            {link.label}
          </button>
        ))}
      </div>
    </nav>
  );
}
