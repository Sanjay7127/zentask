# README media assets

This folder holds the screenshots and demo GIF referenced by the root
[`README.md`](../../README.md). **None of the files below exist yet** — the
main README links to them anyway so the layout is ready the moment real
media is dropped in; until then those links/images will render broken on
GitHub, which is expected and preferable to fabricating fake screenshots.

## Checklist

| File | Purpose | Suggested size |
| --- | --- | --- |
| `demo.gif` | Animated walkthrough for the README hero section | ≤ 8 MB, 800–1000px wide |
| `home.png` | Tasks tab (the home screen) | 1080×2400 or similar phone aspect ratio |
| `projects.png` | A project's detail view (progress bar, task list) | same |
| `calendar.png` | Calendar tab | same |
| `analytics.png` | Analytics dashboard | same |
| `focus.png` | Focus Mode / Pomodoro timer mid-session | same |
| `habits.png` | Habits screen with a streak visible | same |
| `goals.png` | Goals screen with a progress bar | same |
| `settings.png` | Settings screen | same |
| `security.png` | Security & Privacy screen | same |

## How to capture these

1. Run the app on a real device, emulator, or `flutter run -d chrome`.
2. Populate it with a few realistic tasks/projects/habits/goals — not empty
   states — so the screenshots actually show the feature.
3. Capture at 2x/3x resolution where possible; PNG for stills, GIF (or MP4
   converted to GIF) for the demo.
4. Drop the files directly into this folder using the exact names above —
   `README.md` already points at them, so no other change is needed.

## Optimizing before committing

Large, uncompressed screenshots bloat the repo's clone size forever (git
doesn't shrink history on its own). Before committing:

```bash
# PNGs
pngquant --quality=65-85 *.png

# GIF
gifsicle -O3 --colors 128 demo.gif -o demo.gif
```
