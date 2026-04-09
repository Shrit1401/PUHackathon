type Callback<T> = (payload: T) => void;

type RealtimePayload = {
  id: string;
  updatedAt: string;
};

export function subscribeToIncidents(callback: Callback<RealtimePayload>) {
  return subscribeToChannel("incidents_live", callback);
}

export function subscribeToAssignments(callback: Callback<RealtimePayload>) {
  return subscribeToChannel("assignments_live", callback);
}

export function subscribeToResponders(callback: Callback<RealtimePayload>) {
  return subscribeToChannel("responders_live", callback);
}

function subscribeToChannel(
  channel: "incidents_live" | "responders_live" | "assignments_live",
  callback: Callback<RealtimePayload>,
) {
  const sseEnabled = process.env.NEXT_PUBLIC_ENABLE_SSE_REALTIME === "true";
  if (!sseEnabled || typeof window === "undefined") {
    return () => {};
  }

  const baseUrl =
    typeof window !== "undefined"
      ? "/api/backend"
      : process.env.NEXT_PUBLIC_RESQNET_API_BASE_URL?.trim() || "";
  const source = new EventSource(`${baseUrl}/realtime/${channel}`);

  const onData = (event: MessageEvent<string>) => {
    try {
      const parsed = JSON.parse(event.data) as Record<string, unknown>;
      const idCandidate =
        parsed.id ??
        parsed.incident_id ??
        parsed.responder_id ??
        parsed.assignment_id;
      callback({
        id: String(idCandidate ?? `${channel}-${Date.now()}`),
        updatedAt: new Date().toISOString(),
      });
    } catch {
      callback({
        id: `${channel}-${Date.now()}`,
        updatedAt: new Date().toISOString(),
      });
    }
  };

  source.addEventListener("snapshot", onData as EventListener);
  source.addEventListener("data", onData as EventListener);

  return () => {
    source.removeEventListener("snapshot", onData as EventListener);
    source.removeEventListener("data", onData as EventListener);
    source.close();
  };
}
