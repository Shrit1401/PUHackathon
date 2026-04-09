import type { Metadata } from "next";
import { Sora, Syne } from "next/font/google";

const syne = Syne({ subsets: ["latin"], variable: "--font-syne" });
const sora = Sora({ subsets: ["latin"], variable: "--font-sora" });

export const metadata: Metadata = {
  title: "NFC · ResQNet+",
  description:
    "Emergency tag telemetry, scan history, and public card access for ResQNet+.",
};

export default function NfcLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <div
      className={`${syne.variable} ${sora.variable} font-[family-name:var(--font-sora),var(--font-geist-sans),sans-serif]`}
    >
      {children}
    </div>
  );
}
