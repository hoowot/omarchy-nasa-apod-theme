# Contributing

Thanks for helping improve NASA APOD Wallpaper & Theme. This repository is
**public**: anything committed, including git metadata, can be copied,
cached, and indexed permanently, even if it's later deleted. These
guidelines help keep personal information and secrets out of it, and keep
the plugin's behavior predictable.

They apply to everyone working on the project, including anyone using an AI
coding assistant. When you're unsure whether something is sensitive, treat
it as sensitive and ask.

> These are project conventions only. They are not legal advice and make no
> statement about compliance with any law, regulation, or standard. The
> software is provided "as is", without warranty of any kind. See
> [`LICENSE`](LICENSE).

---

## 1. Keep personal and private information out

Commits, files, comments, commit messages, branch and tag names,
screenshots, and git author/committer metadata should contain **none** of
the following:

- Real names, other than the public handle you choose to contribute under
- Personal or work email addresses. Use your GitHub `noreply` address for
  commits.
- Employer or client names, internal project names, domains, or URLs
- Local usernames, hostnames, home-directory paths (`/home/<user>/...`),
  machine IDs, MAC/IP addresses, or network names (SSIDs)
- Precise location, phone numbers, or account identifiers
- Logs, state files, or command output captured from a real machine
- Any sensitive personal information (health, financial, government ID,
  biometric, and similar categories). This project has no use for any of
  it.

Use placeholders in examples: `<user>`, `<you>`, `<repo-url>`,
`$HOME/path/to/...`.

### Screenshots and preview images

Screenshots of the desktop can reveal more than intended. Before adding one:

- Crop to the widget, or use a mockup like `preview.png`. Tray icons,
  workspace names, terminal prompts, and window titles show your username,
  which apps you use, and what you're working on.
- Strip metadata, for example `exiftool -all= image.png`.
- Only use pictures you have the rights to share. Many APOD pictures are
  copyrighted by their photographers. Prefer images credited only to NASA
  (or NASA with partner agencies) from the
  [NASA Image and Video Library](https://images.nasa.gov/), and credit them
  in `README.md`.

## 2. Keep secrets out

- No passwords, API keys, tokens, private keys, certificates, or
  connection strings, real **or** realistic-looking examples. The plugin
  needs no credentials, so a change that introduces one won't be accepted.
- If you expose a secret anywhere, assume it's compromised. Revoke and
  rotate it first, then clean up. Removing the file afterwards doesn't
  undo a push.
- Scan before pushing (see §7).

## 3. Git identity and history

- Set your identity **for this repository only**:

  ```bash
  git config user.name  "<public-handle>"
  git config user.email "<id>+<public-handle>@users.noreply.github.com"
  ```

- Check the metadata before pushing. Every line should show only your
  public handle and noreply address:

  ```bash
  git log --format='%an <%ae> | %cn <%ce>' | sort -u
  ```

- Commit timestamps include your time-zone offset. To avoid revealing it,
  commit in UTC: `TZ=UTC git commit ...`
- If personal information reaches a local commit, rewrite it **before**
  pushing. If it has already been pushed, contact the maintainer rather
  than force-pushing.
- Signed commits and tags are encouraged.
- Don't force-push to `main`.

## 4. Plugin data handling

The plugin is designed so that nothing about the user's system is sent
anywhere. Changes should preserve that design:

- **No telemetry, analytics, crash reporting, or "phone home"** of any
  kind.
- **Network access is limited to what `README.md` documents**: HTTPS `GET`
  requests with no user data, to
  - `https://science.nasa.gov/feed/apod-basic/` for the APOD feed
  - `https://assets.science.nasa.gov/` for the day's image

  A change that adds, changes, or removes an endpoint must update the
  **Privacy and security** section of `README.md` and the design notes in
  `SECURITY.md` in the same pull request.
- Don't include usernames, hostnames, settings, or other user data in any
  URL, header, query string, or request body.
- Write only to the `nasa-apod` theme directory and the plugin's state
  directory. Keep only today's picture; don't build up an archive.
- The state file and log hold only public APOD data (date, title, link)
  and the plugin's own status messages.
- Keep the README accurate and plain. Describe what the plugin does and
  doesn't do, including its limitations, and avoid absolute or promotional
  claims such as "secure," "guaranteed," or "complete."

## 5. Coding guidelines

**Privileges**
- The plugin runs as the user. Don't use `sudo`, `pkexec`, or setuid, and
  don't write outside the theme directory, the state directory, and the
  plugin folder.

**Downloaded data is untrusted input**
- Download over HTTPS only, including redirects
  (`curl --proto '=https' --proto-redir '=https' -fsSL`), with timeouts
  (`--max-time`) and size limits (`--max-filesize`).
- Only download from the hosts listed in §4. Check every URL taken from the
  feed against that list before using it.
- Parse the feed with Python's standard library, and check what it returns
  before using it. Strip control and invisible formatting characters from
  any text that gets logged or displayed, and cap its length.
- Write downloads to a temporary directory inside the state directory and
  move them into place only once they've passed the checks.
- Never pass feed data to `eval`, `bash -c`, `source`, or an unquoted
  command position. Use it only as quoted data (`jq --arg`, `printf '%s'`).
- Never let ImageMagick guess the format of a downloaded file. Check the
  file's leading bytes, accept only JPEG, PNG or WebP, name the format
  explicitly (`jpeg:file`), and pass resource limits (`-limit ...`). Some
  ImageMagick formats can read or write local files or run other programs.
- Display text in QML as plain text (`Text.PlainText`), not rich or HTML
  text. (The Omarchy bar's label and tooltip are already plain text.)
- Only open links that point at `https://science.nasa.gov/`.
- On any error, keep the current wallpaper and theme and write the reason
  to the log. Never apply an image that failed a check.

**Shell**
- Use `set -uo pipefail` (or stricter) and quote every expansion.
- No hardcoded user paths. Use `$HOME` / `$XDG_CONFIG_HOME` /
  `$XDG_STATE_HOME`.
- `shellcheck bin/nasa-apod-theme` should report no warnings. Justify any
  suppression in a comment.

**Dependencies**
- Stick to tools included in a standard Omarchy install (`bash`, `curl`,
  `jq`, `python3` with only its standard library, ImageMagick, `flock`).
  Discuss any new runtime dependency in an issue first.
- Never `curl | sh`, and never download and run code at runtime.

**Repository layout**
- No symlinks (the Omarchy plugin validator rejects them). Keep
  `manifest.json` at the repo root.
- Keep `bin/nasa-apod-theme` and `bin/apod-palette.py` committed as
  executable (`100755`).
- Don't commit downloaded pictures, state files, logs, editor files, or
  `.env` files. Keep `.gitignore` current.

## 6. Reporting vulnerabilities

Please report security problems privately, as described in
[`SECURITY.md`](SECURITY.md), and not in public issues or pull requests.
Don't put details of an unfixed vulnerability in public issues, commits, or
release notes.

## 7. Before you push

Run these from the repo root. If any check fails, fix it before pushing,
or ask for help in an issue (without including sensitive details).

```bash
# 1. Plugin structure is valid
omarchy plugin validate .

# 2. Static analysis
shellcheck bin/nasa-apod-theme
python3 -m py_compile bin/apod-palette.py && rm -rf bin/__pycache__

# 3. No secrets in files or history
gitleaks detect --source . --log-opts="--all"

# 4. No personal or identifying data in tracked files.
#    Add your own name, employer, username, and hostname to the pattern
#    locally. Don't commit that list.
git grep -nIiE '/home/|@[a-z0-9-]+\.(com|net|org|io)|<your-private-terms>'

# 5. Commit metadata shows only your public handle and noreply email,
#    and every timestamp is in UTC (+0000)
git log --all --format='%an <%ae> | %cn <%ce>' | sort -u
git log --all --format='%ad | %cd' --date=iso | grep -v '+0000 | .*+0000'  # expect no output

# 6. Executable bits are correct
git ls-files -s bin/   # expect 100755 for both

# 7. A fresh clone validates
git clone -q . /tmp/nasa-apod-theme-test && omarchy plugin validate /tmp/nasa-apod-theme-test
```

To test behavior without touching your real theme, point the script at
throwaway directories and a saved copy of the feed. For example, a copy
whose newest item is an embedded-video day:

```bash
XDG_CONFIG_HOME=/tmp/apod-test/config XDG_STATE_HOME=/tmp/apod-test/state \
NASA_APOD_FEED_URL=file:///tmp/apod-test/feed.xml \
  bin/nasa-apod-theme --force --switch if-active
```

Also check by hand:

- [ ] The README's privacy section and `SECURITY.md` still match what the
      code does
- [ ] Any screenshots are cropped, stripped of metadata, and use pictures
      you have the rights to
- [ ] `version` in `manifest.json` is bumped and `CHANGELOG.md` updated for
      a release
- [ ] You're free to share this code under the project's license

## 8. Practices this project draws on

These guidelines borrow ideas from publicly available secure-development
and privacy guidance, including:

- [OWASP](https://owasp.org/) secure coding guidance
- [NIST Secure Software Development Framework (SP 800-218)](https://csrc.nist.gov/pubs/sp/800/218/final)
- [CISA Secure by Design](https://www.cisa.gov/securebydesign)
- [OpenSSF](https://openssf.org/) open-source security best practices
- Data minimization: collect nothing that isn't needed

They're listed only as background reading. This project doesn't claim to
follow, satisfy, or be assessed against any of them.

---

*Revisit this document when the plugin's behavior, network access, or
dependencies change.*
