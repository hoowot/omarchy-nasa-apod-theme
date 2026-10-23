# Security Policy

## No support commitment

NASA APOD Wallpaper & Theme is a personal hobby project, shared in case it's
useful. It is provided "as is", without warranty of any kind. See
[`LICENSE`](LICENSE).

There is **no commitment** of any kind to:

- read, acknowledge, or respond to reports
- investigate, confirm, or fix any issue
- publish releases, advisories, or announcements
- keep the project maintained, available, or compatible with future
  versions of Omarchy

The project may stop being maintained at any time without notice. If you
rely on it, review the code yourself, and consider keeping your own fork.

## Supported versions

None. No version is supported or guaranteed to receive fixes. If a fix is
made, it will be in the latest commit on `main`, which you can get with:

```bash
omarchy plugin update hoowot.nasa-apod-theme
```

## Reporting a vulnerability

If you find a security problem, you're welcome to report it. Please
understand that it may not get a reply or a fix.

**Please don't report security problems in public issues, discussions, or
pull requests.** If GitHub's private vulnerability reporting is enabled for
this repository, use it: open the **Security** tab and choose **Report a
vulnerability**. If it isn't enabled, it's reasonable to disclose the issue
publicly once you've given what you consider a fair amount of time, or to
fix it in your own fork.

Helpful details to include:

- What the problem is and what an attacker could do with it
- Steps to reproduce, or a proof of concept
- The plugin commit you tested and your Omarchy version (`omarchy version`)

Please **don't** include personal information or secrets. Trim logs and
output to what's needed to show the problem.

## Scope

Relevant to this project:

- `bin/nasa-apod-theme`, `bin/apod-palette.py`, `BarWidget.qml`, and
  `manifest.json` in this repository
- How the plugin downloads, checks, and uses the APOD feed and images
- Anything that would cause the plugin to send user data off the machine,
  run unintended commands, or write outside the directories listed below

Not part of this project (report these upstream instead):

- Omarchy or `omarchy-shell` itself: [Omarchy](https://github.com/basecamp/omarchy)
- The APOD feed, images, or science.nasa.gov:
  [NASA Science](https://science.nasa.gov/apod/)
- ImageMagick, curl, jq, or Python: their own projects

## Design notes for reviewers

How the plugin is written to behave (see the code to confirm):

- Runs as the logged-in user without requesting elevated privileges.
- Its network activity is HTTPS `GET` requests to `science.nasa.gov` for
  the APOD feed and to `assets.science.nasa.gov` for the day's image.
  Downloads refuse any other protocol, including on redirects, and have
  time and size limits. The requests don't include user data, though, like
  any web request, they reveal your IP address to those servers. Once
  today's picture has been handled, the plugin makes no requests until the
  next day's picture is due.
- Writes only to `~/.config/omarchy/themes/nasa-apod/` and
  `~/.local/state/omarchy-nasa-apod/` (or the `XDG_CONFIG_HOME` and
  `XDG_STATE_HOME` equivalents), and switches themes with
  `omarchy theme set`. By default it never switches the user's theme on
  its own: it only switches when the user right-clicks the widget, clicks
  the one-time "theme is ready" notification, or picks the theme
  themselves, and after that only keeps that theme up to date. The
  `switchTheme` setting, off by default, makes it switch automatically.
  The notification and right-click run `omarchy theme set nasa-apod` with
  fixed arguments; no feed data reaches either command. When it cleans up old pictures,
  it only deletes its own `apod-*` files.
- Treats the feed as untrusted:
  - It is parsed by Python's standard XML library, which doesn't resolve
    external entities, and is never executed.
  - The image URL must be HTTPS on `assets.science.nasa.gov`, or nothing
    is downloaded. The page link must be HTTPS on `science.nasa.gov`, or
    it's dropped. The widget checks the link again before opening it, and
    only opens it when you click.
  - The title has control and invisible formatting characters removed and
    is capped at 200 characters, so it can't inject terminal escape
    sequences into the log. The title and link are only ever passed as
    data, never interpolated into a shell command, and the bar shows them
    as plain text.
- Treats the downloaded image as untrusted:
  - It must start with a JPEG, PNG or WebP signature. ImageMagick is told
    that format explicitly instead of guessing from the content, since
    some of its formats can read or write files or run other programs.
  - ImageMagick decodes it with limits on dimensions, memory, disk and
    time, then re-encodes it as a fresh JPEG with metadata removed. The
    wallpaper renderer and the palette step only ever read that re-encoded
    file.
  - It doesn't replace the wallpaper with a download under 50 KB, or with
    the video-player screenshot the feed carries on embedded-video days.
- The plugin doesn't change ImageMagick's own security policy. Systems
  that need stricter limits can set them in ImageMagick's `policy.xml`.
