# Milestone 24: a sun and a moon that cross the sky (18 Nov 2026)

Request (user, 18 Nov 2026, after the AM/PM question): make the time of day visible. "Put a sun that goes from left to right in an arch and a moon too. When playing football and sleeping it shouldn't appear." Built as small patches, each committed on its own. The 24-hour clock stays (decision 76: no AM/PM; Portugal uses 24 hours).

## Rules (decisions 76 to 78)

- 76: the clock stays 24-hour; the sun and moon make the time of day clear.
- 77: the sun rises on the left at `daylight.start_hour` (07:00), is highest at midday between sunrise and sunset, and sets on the right at `daylight.end_hour` (19:00). The moon does the same from sunset to the next sunrise. The rise and set are on the ground line, so the body goes behind the horizon. Same hours as the sky colour, so they always agree. Only the look; no rule changes.
- 78: hidden during football (the field fills the stage) and while the avatar sleeps or waits for Wake (the bedroom fills the stage). Elsewhere it is behind the places: the room's wall covers it (only the windows show the sky), the street and the outside show it.

## Patches

1. **Position maths** (`scripts/ui/sky_bodies.gd`, static `arc()`): from the minute of the day, which body is up and how far along its arch it is (0 left, 1 right). Tests in `tests/sky_bodies_test.gd`.
2. **Drawing** (`SkyBodies` node in `scenes/main.tscn`, behind every place): a yellow sun with a soft glow and a pale crescent moon, placeholder shapes; sizes and arch height as `@export` values. The main screen sets the minute when the time changes.
3. **Hiding** during football and sleep (`main.gd`), with tests.

## Still to check

The look on a real phone; whether the team wants art instead of shapes.
