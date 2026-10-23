import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

// Shows today's NASA Astronomy Picture of the Day title in the bar, and runs
// bin/nasa-apod-theme once an hour to pick up a new picture. The script does
// the downloading and theming and writes a small state file; this widget
// only reads that file, so every monitor's copy stays in sync.
//
// The theme is only switched when the user asks: by right-clicking the
// widget, clicking the one-time "theme is ready" notification, picking it in
// the theme switcher, or turning on the switchTheme setting. Once it's the
// current theme, the daily refresh keeps it up to date.
BarWidget {
  id: root
  moduleName: "hoowot.nasa-apod-theme"

  readonly property bool switchTheme: setting("switchTheme", false) === true
  readonly property bool showTitle: setting("showTitle", true) !== false

  readonly property string themeName: "nasa-apod"
  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME")
    || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy-nasa-apod"
  readonly property string themeDir: (Quickshell.env("XDG_CONFIG_HOME")
    || (Quickshell.env("HOME") + "/.config")) + "/omarchy/themes/" + themeName

  property string apodDate: ""
  property string apodTitle: ""
  property string apodLink: ""
  property bool apodIsVideo: false
  property bool themeReady: false
  property string currentTheme: ""

  readonly property bool themeActive: currentTheme === themeName
  readonly property bool canSwitch: themeReady && !themeActive

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

  function useTheme() {
    if (root.canSwitch && !switcher.running) switcher.running = true
  }

  function reloadFiles() {
    stateFile.reload()
    themeFile.reload()
    themeColors.reload()
  }

  Process {
    id: refresher
    command: [root.pluginFile("bin/nasa-apod-theme"),
      "--switch", root.switchTheme ? "always" : "if-active"]
    onExited: root.reloadFiles()
  }

  Process {
    id: switcher
    command: ["omarchy", "theme", "set", root.themeName]
    onExited: root.reloadFiles()
  }

  // watchChanges alone isn't enough: it can't watch a file that doesn't
  // exist yet (the first run creates the state file), and both files are
  // replaced rather than edited in place, which gives them a new inode.
  // Re-read them after each refresh, and every minute for the copies on
  // other monitors and for theme changes made elsewhere.
  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: root.reloadFiles()
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

  // Omarchy records the current theme's name here (`omarchy theme current`
  // prints it as a display name).
  FileView {
    id: themeFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme.name"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.currentTheme = String(text()).trim()
    onLoadFailed: root.currentTheme = ""
  }

  // The theme is ready to switch to once the script has built it. Checking
  // for the file itself (rather than a flag in the state file) also works
  // for state files written by earlier versions. It's missing only until the
  // first picture has been built, for example when the plugin is installed
  // on an embedded-video day.
  FileView {
    id: themeColors
    path: root.themeDir + "/colors.toml"
    printErrors: false
    onLoaded: root.themeReady = true
    onLoadFailed: root.themeReady = false
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
        + (root.canSwitch ? "\nRight-click to use it as your theme" : "")
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) root.useTheme()
      else if (mouseButton === Qt.LeftButton && root.linkIsSafe) Qt.openUrlExternally(root.apodLink)
    }
  }
}
