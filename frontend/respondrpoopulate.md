# Responder Populate Commands

Use these commands to seed responder data into the backend.

## 1) Set backend URL

```bash
export BACKEND_URL="https://8301-182-71-109-122.ngrok-free.app"
```

## 2) Verify current responders

```bash
curl -sS "$BACKEND_URL/responders?limit=20" | jq
```

## 3) Populate sample responders

```bash
curl -sS -X POST "$BACKEND_URL/responders" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Medic Unit Alpha",
    "type": "ambulance",
    "phone": "+919900000001",
    "latitude": 22.5726,
    "longitude": 88.3639,
    "availability": "ready"
  }' | jq

curl -sS -X POST "$BACKEND_URL/responders" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Kolkata Fire Team 2",
    "type": "fire",
    "phone": "+919900000002",
    "latitude": 22.5790,
    "longitude": 88.3700,
    "availability": "ready"
  }' | jq

curl -sS -X POST "$BACKEND_URL/responders" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Traffic Patrol East",
    "type": "police",
    "phone": "+919900000003",
    "latitude": 22.5650,
    "longitude": 88.3510,
    "availability": "en_route"
  }' | jq

curl -sS -X POST "$BACKEND_URL/responders" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Volunteer Network V1",
    "type": "volunteer",
    "phone": "+919900000004",
    "latitude": 22.5900,
    "longitude": 88.3900,
    "availability": "ready"
  }' | jq
```

## 4) Confirm population

```bash
curl -sS "$BACKEND_URL/responders?limit=200" | jq
```

## Optional: one-shot seed script

```bash
cat <<'EOF' > seed_responders.sh
#!/usr/bin/env bash
set -euo pipefail

: "${BACKEND_URL:=https://8301-182-71-109-122.ngrok-free.app}"

create_responder() {
  curl -sS -X POST "$BACKEND_URL/responders" \
    -H "Content-Type: application/json" \
    -d "$1" | jq
}

create_responder '{"name":"Medic Unit Alpha","type":"ambulance","phone":"+919900000001","latitude":22.5726,"longitude":88.3639,"availability":"ready"}'
create_responder '{"name":"Kolkata Fire Team 2","type":"fire","phone":"+919900000002","latitude":22.5790,"longitude":88.3700,"availability":"ready"}'
create_responder '{"name":"Traffic Patrol East","type":"police","phone":"+919900000003","latitude":22.5650,"longitude":88.3510,"availability":"en_route"}'
create_responder '{"name":"Volunteer Network V1","type":"volunteer","phone":"+919900000004","latitude":22.5900,"longitude":88.3900,"availability":"ready"}'
EOF

chmod +x seed_responders.sh
./seed_responders.sh
```

