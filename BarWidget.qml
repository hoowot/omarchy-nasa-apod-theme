import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

// Shows today's NASA Astronomy Picture of the Day title in the bar, and runs
// bin/nasa-apod-theme once an hour to pick up a new picture. The script does
// the downloading and theming and writes a small state file; this widget
// only reads that file, so every monitor's copy stays in sync.
BarWidget {
  id: root
  moduleName: "hoowot.nasa-apod-theme"

  readonly property bool switchTheme: setting("switchTheme", true) !== false
  readonly property bool showTitle: setting("showTitle", true) !== false

  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME")
    || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy-nasa-apod"

  property string apodDate: ""
  property string apodTitle: ""
  property string apodLink: ""
  property bool apodIsVideo: false

  // The link comes from the downloaded feed, so only ever open NASA's own pages.
  readonly property bool linkIsSafe: apodLink.indexOf("https://science.nasa.gov/") === 0

  readonly property string shortTitle: apodTitle.length > 32
    ? apodTitle.substring(0, 31) + "…"
    : apodTitle

  function pluginFile(name) {
    let url = String(Qt.resolvedUrl(name))
    if (url.indexOf("file://") === 0) url = url.slice(7)
    return decodeURIComponent(url)
  }

  function applyState(raw) {
    try {
      const data = JSON.parse(String(raw || "{}"))
      root.apodDate = typeof data.date === "string" ? data.date : ""
      root.apodTitle = typeof data.title === "string" ? data.title : ""
      root.apodLink = typeof data.link === "string" ? data.link : ""
      root.apodIsVideo = data.media === "embed"
    } catch (e) {
      root.apodDate = ""
      root.apodTitle = ""
      root.apodLink = ""
      root.apodIsVideo = false
    }
  }

  function refresh() {
    if (!refresher.running) refresher.running = true
  }

  Process {
    id: refresher
    command: [root.pluginFile("bin/nasa-apod-theme"),
      "--switch", root.switchTheme ? "always" : "if-active"]
    onExited: stateFile.reload()
  }

  // watchChanges alone isn't enough: it can't watch a state file that
  // doesn't exist yet (the first run creates it), and the script replaces
  // the file atomically, which gives it a new inode. Re-read it after each
  // refresh, and every minute for the copies on other monitors, whose own
  // refresh skips the work when another copy holds the lock.
  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: stateFile.reload()
  }

  // Once today's picture is handled the script exits without any network
  // request, so hourly is cheap and still catches the next one soon after
  // it is posted.
  Timer {
    interval: 3600000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  FileView {
    id: stateFile
    path: root.stateDir + "/state.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.applyState(text())
    onLoadFailed: root.applyState("")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.showTitle && root.shortTitle !== "" ? "🔭 " + root.shortTitle : "🔭"
    fontSize: Style.font.caption
    horizontalMargin: 6
    tooltipText: root.apodTitle === ""
      ? "NASA APOD: waiting for today's picture"
      : root.apodTitle + (root.apodDate !== "" ? " (" + root.apodDate + ")" : "")
        + (root.apodIsVideo ? "\nToday's APOD is a video, so the wallpaper is unchanged" : "")
        + (root.linkIsSafe ? "\nClick to " + (root.apodIsVideo ? "watch" : "open") + " on science.nasa.gov" : "")
    onPressed: if (root.linkIsSafe) Qt.openUrlExternally(root.apodLink)
  }
}
