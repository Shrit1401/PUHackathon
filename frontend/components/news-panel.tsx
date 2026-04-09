import Link from "next/link";
import type { NewsArticle } from "../lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { ScrollArea } from "./ui/scroll-area";

type NewsPanelProps = {
  articles: NewsArticle[];
};

export function NewsPanel({ articles }: NewsPanelProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>News Signals</CardTitle>
      </CardHeader>
      <CardContent className="h-64 p-0">
        <ScrollArea className="h-full">
          <div className="space-y-3 p-4">
            {articles.length === 0 ? (
              <p className="text-sm text-white/60">
                No live news signals yet. Fresh coverage will appear here.
              </p>
            ) : null}
            {articles.map((article) => {
              const published = new Date(article.published);
              const time = isNaN(published.getTime())
                ? article.published
                : published.toLocaleString("en-IN", {
                    hour12: false,
                    month: "short",
                    day: "2-digit",
                    hour: "2-digit",
                    minute: "2-digit",
                  });

              return (
                <Link
                  key={article.url}
                  href={article.url}
                  target="_blank"
                  rel="noreferrer"
                  className="block rounded-xl border border-white/10 bg-white/2 p-3 transition hover:bg-white/6"
                >
                  <div className="mb-1 flex items-center justify-between text-[11px] text-white/55">
                    <span className="truncate pr-2">{article.source}</span>
                    <span className="font-mono">{time}</span>
                  </div>
                  <p className="text-sm font-medium text-white/90">
                    {article.title}
                  </p>
                  {article.summary ? (
                    <p className="mt-1 line-clamp-2 text-xs text-white/70">
                      {article.summary}
                    </p>
                  ) : null}
                  <div className="mt-2 flex flex-wrap gap-1 text-[10px] text-white/65">
                    <span className="rounded-full border border-white/15 bg-white/4 px-2 py-0.5 uppercase tracking-[0.16em]">
                      {article.disaster_type}
                    </span>
                    <span className="rounded-full border border-white/10 bg-white/3 px-2 py-0.5">
                      {article.query}
                    </span>
                  </div>
                </Link>
              );
            })}
          </div>
        </ScrollArea>
      </CardContent>
    </Card>
  );
}

