# Changelog

## 1.1.1 — 2026-10-23

- The plugin no longer switches your theme on its own by default.
  `switchTheme` now defaults to off: installing builds the `nasa-apod`
  theme and shows today's title, and you start using it by right-clicking
  🔭 in the bar, clicking the one-time "theme is ready" notification, or
  picking it in the theme switcher. Once it's your theme, it still updates
  daily. Turn `switchTheme` on for the previous behavior.
- Fixed the bar widget's title not appearing after a fresh install until
  the shell restarted.
- After updating, run `omarchy restart shell` so the bar loads the new
  widget.

## 1.1.0 — 2026-10-23

- Read the APOD RSS feed on science.nasa.gov instead of the
  `api.nasa.gov/planetary/apod` API, which now mostly returns HTTP 500 and
  otherwise returns a NASA logo placeholder. No API key is needed any more.
- Download the original full-resolution image instead of a resized copy.
- Refuse images under 50 KB so a placeholder can't replace the wallpaper.
- Keep the current wallpaper on days when APOD is an embedded YouTube or
  Vimeo video, since the feed's picture for those is a screenshot of the
  player. The tooltip says so, and clicking opens the video.
- The bar widget now runs the refresh itself, hourly, so there's no
  systemd timer to set up.
- New settings: `switchTheme` and `showTitle`.
- Click the widget to open today's APOD page.
- Only one refresh runs at a time on multi-monitor setups.
- Security hardening: downloads are HTTPS only with size limits and must
  come from NASA's hosts; downloaded images must be JPEG, PNG or WebP, are
  decoded with ImageMagick resource limits and an explicit format, and are
  re-encoded before use; titles are cleaned of control characters; the
  widget only opens science.nasa.gov links.
- No network requests once today's picture has been handled.
- State and log moved to `~/.local/state/omarchy-nasa-apod/`.

## 1.0.0

- First version: bar widget showing today's APOD title, with a separate
  script and systemd timer that applied the picture as a theme.
