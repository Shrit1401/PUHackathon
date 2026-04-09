import { cache } from "react";

import { fetchNfcProfileOrNull } from "@/lib/api";

/** One NFC profile fetch per request (shared by `generateMetadata` and the page). */
export const loadNfcProfileForPage = cache(fetchNfcProfileOrNull);
