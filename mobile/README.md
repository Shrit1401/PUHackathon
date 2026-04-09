# ResQNet Citizen App

High-impact disaster intelligence app built for demo and production extension.

## Stack
- Flutter (stable)
- Riverpod
- GoRouter
- Supabase (Auth + Postgres + Realtime)
- OpenStreetMap (`flutter_map`) for live situational map
- Google Maps (tracking screen)

## What is now implemented
- Email OTP + Phone OTP authentication
- One-tap SOS with GPS capture
- Live risk meter from nearest disaster confidence
- Situational map with:
  - OpenStreetMap base layer
  - Heat-style risk overlay from `grid_risk`
  - Disaster hotspot markers
  - Citizen report markers
- Citizen reporting flow with category, description, GPS, optional event link
- Intelligence feed tabs:
  - Official disaster alerts
  - Citizen reports
- Rescue tracking with live unit updates and ETA

## Project Structure
```text
lib/
  core/
  features/
    auth/
    dashboard/
    sos/
    tracking/
    alerts/
    map/
    reports/
    splash/
  services/
  models/
  theme/
```

## Run
```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

## Supabase requirements for this schema
Using your existing tables:
- `profiles`
- `disaster_events`
- `grid_risk`
- `reports`
- `rescue_units`

Enable realtime on:
- `disaster_events`
- `grid_risk`
- `reports`
- `rescue_units`

Auth requirements:
- Enable Email provider (OTP)
- Enable Phone provider (OTP)
- Signups enabled
- Phone input in E.164 format (`+14155550123`)

## Notes
- OSM map works without API key.
- Google Maps key is still required for the tracking screen.
