-- Sample disaster events
insert into public.disaster_events (id, type, latitude, longitude, confidence_score, created_at) values
  ('11111111-1111-1111-1111-111111111111', 'fire', 37.7754, -122.4185, 0.82, now() - interval '10 minutes'),
  ('22222222-2222-2222-2222-222222222222', 'flood', 37.7848, -122.4092, 0.61, now() - interval '35 minutes'),
  ('33333333-3333-3333-3333-333333333333', 'earthquake', 37.7642, -122.4312, 0.47, now() - interval '70 minutes')
on conflict (id) do nothing;

insert into public.rescue_units (id, name, latitude, longitude, status, capacity) values
  ('aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'Unit Alpha', 37.7790, -122.4210, 'available', 6),
  ('aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'Unit Bravo', 37.7695, -122.4013, 'available', 4),
  ('aaaaaaa3-aaaa-aaaa-aaaa-aaaaaaaaaaa3', 'Unit Charlie', 37.7588, -122.4475, 'busy', 5)
on conflict (id) do nothing;

insert into public.shelters (id, name, latitude, longitude, capacity, available_slots) values
  ('bbbbbbb1-bbbb-bbbb-bbbb-bbbbbbbbbbb1', 'Civic Arena Shelter', 37.7781, -122.4170, 320, 145),
  ('bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbb2', 'Harbor Relief Center', 37.7940, -122.3934, 180, 64),
  ('bbbbbbb3-bbbb-bbbb-bbbb-bbbbbbbbbbb3', 'Mission Safe Point', 37.7597, -122.4148, 220, 92)
on conflict (id) do nothing;
