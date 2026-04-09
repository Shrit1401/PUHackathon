import { DisasterPhoto } from "../lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { ScrollArea } from "./ui/scroll-area";

type DisasterPhotosPanelProps = {
  photos: DisasterPhoto[];
};

export function DisasterPhotosPanel({ photos }: DisasterPhotosPanelProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Disaster Photos</CardTitle>
      </CardHeader>
      <CardContent className="h-64 p-0">
        <ScrollArea className="h-full">
          <div className="grid grid-cols-2 gap-2 p-4">
            {photos.length === 0 ? (
              <p className="col-span-2 text-sm text-white/60">
                No photos available yet.
              </p>
            ) : null}
            {photos.map((photo) => (
              <div
                key={photo.id}
                className="overflow-hidden rounded-xl border border-white/10 bg-white/4"
              >
                <div className="relative h-24 w-full bg-black/40">
                  <img
                    src={photo.url}
                    alt={photo.label ?? "Disaster photo"}
                    className="h-full w-full object-cover"
                    loading="lazy"
                  />
                </div>
                {photo.label ? (
                  <div className="px-2 py-1 text-[11px] text-white/80 line-clamp-2">
                    {photo.label}
                  </div>
                ) : null}
              </div>
            ))}
          </div>
        </ScrollArea>
      </CardContent>
    </Card>
  );
}
