import type { NextConfig } from "next";
import path from "node:path";
import { fileURLToPath } from "node:url";

// Turbopack can infer a parent folder as the project root and then fail to
// resolve `next` from this app's node_modules ("Next.js package not found").
// Pinning the root fixes that class of panics.
const turbopackRoot = path.dirname(fileURLToPath(import.meta.url));

const nextConfig: NextConfig = {
  turbopack: {
    root: turbopackRoot,
  },
};

export default nextConfig;
