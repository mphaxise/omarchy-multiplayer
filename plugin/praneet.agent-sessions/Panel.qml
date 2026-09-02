import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Agent Sessions bar widget for Omarchy.
//
// Shows every durable omarchy-agent-session record: who needs you, who is
// working, what finished today, and what got orphaned. Structure follows
// 03-sessions-panel.md ("this mirrors the entry, data, and row split the
// omarchy.agents plugin uses"), collapsed to two files because the task
// that produced this skeleton asked for Panel.qml + Session.qml only (no
// separate Main.qml): the Process/Timer/FileView data layer that
// omarchy.agents keeps in Main.qml lives directly in this file instead,
// matching how the Hermes reference plugin keeps everything in one
// Panel.qml. Session.qml is still its own file, one row each.
//
// Sources actually read for this file: omacom/omarchy quattro
// shell/plugins/agents/{manifest.json,Panel.qml,Main.qml,Agent.qml} and
// shell/plugins/README.md; stevequinn/omarchy-hermes-sessions
// {Panel.qml,manifest.json,scripts/snapshot.sh}; spec/03-sessions-panel.md,
// spec/02-command-surface.md, spec/00-overview.md (read from this project's
// own drafts, see README-plugin.md for the path note); context-pack.md.
Panel {
  id: root
  moduleName: "praneet.agent-sessions"
  ipcTarget: "praneet.agent-sessions"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgentColor: bar ? bar.urgent : Color.urgent
  // Color.muted is asserted as a real theme token by context-pack.md's bar
  // widget contract notes ("Color.foreground/background/accent/urgent/muted"),
  // read directly from the shell source; it does not happen to appear in
  // either fetched reference Panel.qml because neither needed a third,
  // quieter state.
  readonly property color mutedColor: Color.muted
  readonly property color dim: Qt.darker(foreground, 1.3) // 1.55 gave #6d728a, 3.60:1 on Tokyo Night; 1.3 gives #8288a5, 4.89:1 (WCAG AA for caption text)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string logTag: "agent-sessions"

  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

  // ------------------------------------------------------------- settings
  //
  // `settings` is shell-injected (context-pack.md: "shell injects bar,
  // moduleName, settings"; confirmed by agents/Panel.qml passing
  // `settings: root.settings` straight into its Main{}).

  function setting(name, fallback) {
    var value = root.settings ? root.settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  readonly property int refreshIntervalSec: Math.max(5, Number(setting("refreshIntervalSec", 10)))
  readonly property bool showWhenEmpty: setting("showWhenEmpty", false) === true
  readonly property int maxRows: Math.max(5, Number(setting("maxRows", 20)))

  // ------------------------------------------------------------ selection
  //
  // Keyboard state lives here, not in Session.qml, because Esc has to know
  // about an armed Stop or an open Send field regardless of which row it
  // belongs to (03-sessions-panel.md: "Esc clears an armed Stop or an open
  // Send field first and closes the panel on the second press").

  property bool cursorActive: false
  property int selectedIndex: 0
  property string armedStopId: ""
  property string sendOpenId: ""
  // Sessions whose Stop was confirmed and whose record has not yet reported
  // a terminal state; Session.qml renders the spinner from this.
  property var stoppingIds: ({})
  Timer {
    // Poll fast right after a stop so the row moves to Done today within a
    // couple of seconds instead of waiting for the regular tick.
    id: stopFollowUp
    interval: 1000; repeat: true; running: Object.keys(root.stoppingIds).length > 0
    onTriggered: root.refresh()
  }

  property double nowMs: Date.now()
  Timer {
    // Keeps every row's "since" duration and the stale marker honest while
    // the panel sits open, same purpose as both reference plugins' 30 s
    // clock tick.
    interval: 30000
    running: root.opened
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }

  onOpenedChanged: if (opened) {
    // Cursor visible from the first frame: with one row, arrow keys have
    // nowhere to go, and an invisible cursor read as "keys do nothing"
    // (Praneet, rig, 2026-09-02).
    cursorActive = true
    selectedIndex = 0
    armedStopId = ""
    sendOpenId = ""
    nowMs = Date.now()
    refresh()
    if (panelFlick) panelFlick.contentY = 0
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  // ------------------------------------------------------------- data
  //
  // Primary source: a Timer drives a Process running scripts/snapshot.sh,
  // exactly the pattern Hermes uses for its own scripts/snapshot.sh, and the
  // same StdioCollector + 64 KB cap + try/catch shape as Hermes's real code
  // (not the SplitParser sketch in 03-sessions-panel.md's illustrative
  // Process block, which is unconfirmed against any fetched source).

  property var snapshot: null // { sessions: [...] } once a good parse lands
  property bool loading: false
  property int consecutiveFailures: 0
  readonly property int maxSnapshotBytes: 65536 // 64 KB, per 03-sessions-panel.md "Failure isolation"
  readonly property int backoffIntervalSec: 60   // after three straight failures

  readonly property var allSessions: snapshot && Array.isArray(snapshot.sessions) ? snapshot.sessions : []
  readonly property bool hasErrorRow: !!snapshot && typeof snapshot.error === "string" && snapshot.error !== ""

  // Companion scripts live beside this QML file; resolve relative to it so
  // the plugin works from any install location (same helper as Hermes).
  function scriptPath(name) {
    return Qt.resolvedUrl("scripts/" + name).toString().replace(/^file:\/\//, "")
  }

  function refresh() {
    if (snapshotProcess.running) return
    loading = true
    snapshotProcess.command = [scriptPath("snapshot.sh")]
    snapshotProcess.running = true
  }

  Process {
    id: snapshotProcess
    running: false

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.loading = false
        var raw = String(text)
        // Seatbelt against a runaway CLI, mirrored from Hermes's
        // maxSnapshotBytes guard: never hand more than the cap to JSON.parse.
        if (raw.length > root.maxSnapshotBytes) {
          console.warn(root.logTag, "snapshot too large, discarded:", raw.length, "bytes")
          root.recordFailure()
          return
        }
        var parsed = null
        try {
          parsed = JSON.parse(raw)
        } catch (e) {
          console.warn(root.logTag, "bad snapshot", e)
          root.recordFailure()
          return
        }
        if (!parsed || typeof parsed !== "object" || typeof parsed.error === "string") {
          console.warn(root.logTag, "snapshot reported an error:", parsed && parsed.error)
          root.recordFailure()
          return
        }
        // Good snapshot: adopt it and clear the failure streak. A bad or
        // error snapshot never reaches here, so the last good list stands
        // until three in a row fail (see recordFailure).
        // Fresh clock with every list: a record whose `since` is newer than
        // the last nowMs read as a negative age, which the hero printed as
        // "0M" while the row under it said "just now" (rig capture e5).
        root.nowMs = Date.now()
        root.snapshot = { sessions: Array.isArray(parsed.sessions) ? parsed.sessions : [] }
        root.clearStoppedFromStopping(root.snapshot.sessions)
        root.recordSuccess()
      }
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text).trim() !== "") console.warn(root.logTag, String(text).trim())
    }

    onExited: function(exitCode) {
      // Belt-and-braces reset only; the stdout handler above is what
      // classifies success/failure so a slow or absent stdout callback
      // cannot double-count a single run as two failures.
      root.loading = false
    }
  }

  // Three consecutive failures (non-zero exit, bad JSON, oversize, or an
  // {"error": ...} payload) replace the list with a single error row and
  // back the Timer off to 60 s; the next success restores refreshIntervalSec
  // and clears the row. Exactly 03-sessions-panel.md's "Failure isolation".
  function recordFailure() {
    consecutiveFailures++
    if (consecutiveFailures >= 3) {
      snapshot = { sessions: [], error: "Session list unavailable, retrying" }
    }
  }

  function recordSuccess() {
    consecutiveFailures = 0
  }

  Timer {
    id: pollTimer
    interval: (root.consecutiveFailures >= 3 ? root.backoffIntervalSec : root.refreshIntervalSec) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // Secondary source, per 03-sessions-panel.md's "Data" section: the
  // reconciler rewrites this file once per tick even when nothing changed,
  // so its generated_at is a liveness signal independent of whether our own
  // snapshot.sh poll happens to be succeeding. Only used here for the stale
  // marker; session content itself comes from the primary Process above.
  FileView {
    id: indexFile
    path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy/sessions/index.json"
    // VERIFY ON RIG: 03-sessions-panel.md names this exact risk -- whether
    // watchChanges fires reliably when index.json is replaced by rename
    // instead of edited in place; some inotify setups miss a rename. The
    // Timer-driven snapshot.sh poll above is the fallback either way.
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.parseIndex(text())
    onLoadFailed: root.indexGeneratedAtMs = 0
  }

  property real indexGeneratedAtMs: 0

  function parseIndex(content) {
    try {
      var parsed = JSON.parse(String(content || ""))
      var iso = parsed && parsed.generated_at ? String(parsed.generated_at) : ""
      var ms = iso !== "" ? new Date(iso).getTime() : NaN
      root.indexGeneratedAtMs = isFinite(ms) ? ms : 0
    } catch (e) {
      console.warn(root.logTag, "bad index.json", e)
      root.indexGeneratedAtMs = 0
    }
  }

  readonly property bool indexStale: indexGeneratedAtMs > 0
    && (nowMs - indexGeneratedAtMs) > (2 * root.refreshIntervalSec * 1000)

  // One duration vocabulary for the hero, the stale marker, and every row
  // (Session.qml calls this through `formatAge`): "just now", "3m",
  // "1h 20m", "2d 3h". Never "0m", never negative.
  function formatDuration(ms) {
    if (!(ms > 0)) return "just now"
    var minutes = Math.floor(ms / 60000)
    if (minutes < 1) return "just now"
    var hours = Math.floor(minutes / 60)
    var days = Math.floor(hours / 24)
    if (days > 0) return days + "d " + (hours % 24) + "h"
    if (hours > 0) return hours + "h " + (minutes % 60) + "m"
    return minutes + "m"
  }

  function staleAgeText() {
    return indexStale ? formatDuration(nowMs - indexGeneratedAtMs) : ""
  }

  // --------------------------------------------------------------- rows
  //
  // Section membership and sort order come straight from the "Panel layout"
  // table in 03-sessions-panel.md.

  function sinceMs(session) {
    var iso = session && session.status ? String(session.status.since || "") : ""
    var ms = iso !== "" ? new Date(iso).getTime() : NaN
    return isFinite(ms) ? ms : 0
  }

  function attentionRank(state) {
    return state === "blocked" ? 0 : (state === "waiting" ? 1 : 2)
  }

  // 1. Needs you: waiting, blocked. Blocked before waiting, oldest since
  // first within each group, so the longest-neglected session leads.
  function needsYouSessions() {
    var list = root.allSessions.filter(function(s) {
      return s.status && (s.status.state === "blocked" || s.status.state === "waiting")
    })
    list.sort(function(a, b) {
      var r = root.attentionRank(a.status.state) - root.attentionRank(b.status.state)
      return r !== 0 ? r : root.sinceMs(a) - root.sinceMs(b)
    })
    return list
  }

  // 2. Working: starting, working, idle. Alive, asking for nothing. Sort
  // order is not specified in the spec; most-recently-changed first is this
  // skeleton's choice (see README-plugin.md assumptions).
  function workingSessions() {
    var states = { starting: true, working: true, idle: true }
    var list = root.allSessions.filter(function(s) { return s.status && states[s.status.state] })
    list.sort(function(a, b) { return root.sinceMs(b) - root.sinceMs(a) })
    return list
  }

  // 3. Done today: done, failed, stopped in the last 24 h. Older ones drop
  // off the panel; the receipt is their record.
  function doneTodaySessions() {
    var states = { done: true, failed: true, stopped: true }
    var cutoff = root.nowMs - 24 * 3600 * 1000
    var list = root.allSessions.filter(function(s) {
      return s.status && states[s.status.state] && root.sinceMs(s) >= cutoff
    })
    list.sort(function(a, b) { return root.sinceMs(b) - root.sinceMs(a) })
    return list
  }

  // 4. Orphaned.
  function orphanedSessions() {
    var list = root.allSessions.filter(function(s) { return s.status && s.status.state === "orphaned" })
    list.sort(function(a, b) { return root.sinceMs(b) - root.sinceMs(a) })
    return list
  }

  readonly property var needsYouRows: needsYouSessions()
  readonly property var workingRows: workingSessions()
  readonly property var doneRows: doneTodaySessions()
  readonly property var orphanedRows: orphanedSessions()

  // maxRows caps the flattened total; lowest-priority sections are what
  // gets trimmed first since they are concatenated last (see
  // README-plugin.md assumptions -- the spec does not state this rule).
  readonly property var visibleRows: needsYouRows.concat(workingRows).concat(doneRows).concat(orphanedRows).slice(0, root.maxRows)

  readonly property int needsAttentionCount: allSessions.filter(function(s) { return s.needs_attention === true }).length

  // Bar glyph color: most urgent condition wins, per the "Bar widget" table.
  readonly property string barState: {
    if (allSessions.some(function(s) { return s.status && s.status.state === "blocked" })) return "blocked"
    if (allSessions.some(function(s) { return s.status && s.status.state === "waiting" })) return "waiting"
    return "quiet"
  }
  readonly property color barGlyphColor: barState === "blocked" ? urgentColor
    : (barState === "waiting" ? foreground : mutedColor)

  // Hidden entirely when there are no sessions at all and showWhenEmpty is
  // false -- matching the literal hide-when-empty test both reference
  // plugins use ("visible: sessions.length > 0" / "providers.length > 0"),
  // not a "live sessions only" reading of that rule (see README assumptions).
  visible: allSessions.length > 0 || showWhenEmpty || hasErrorRow
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // --------------------------------------------------------------- actions

  function openSession(id) {
    if (!id) return
    Quickshell.execDetached(["omarchy-agent-session-open", String(id)])
  }

  function sendToSession(id, text) {
    if (!id || String(text || "").trim() === "") return
    Quickshell.execDetached(["omarchy-agent-session-send", String(id), String(text)])
  }

  function stopSession(id) {
    if (!id) return
    var next = Object.assign({}, root.stoppingIds); next[String(id)] = Date.now(); root.stoppingIds = next
    Quickshell.execDetached(["omarchy-agent-session-stop", String(id)])
  }

  function clearStoppedFromStopping(sessions) {
    var ids = Object.keys(root.stoppingIds)
    if (ids.length === 0) return
    var live = {}
    for (var i = 0; i < sessions.length; i++) live[sessions[i].id] = sessions[i].status ? sessions[i].status.state : ""
    var next = {}
    for (var j = 0; j < ids.length; j++) {
      var st = live[ids[j]]
      var stale = (Date.now() - root.stoppingIds[ids[j]]) > 30000
      if (st && st !== "stopped" && st !== "done" && st !== "failed" && !stale) next[ids[j]] = root.stoppingIds[ids[j]]
    }
    root.stoppingIds = next
  }

  function openReceipt(id) {
    if (!id) return
    // omarchy-launch-tui, not -or-focus-tui, per this skeleton's brief.
    // VERIFY ON RIG (also flagged in 02-command-surface.md's own "Verify on
    // rig" list): whether omarchy-launch-tui's `-e "$1" "${@:2}"` form runs
    // a bare vendored script directly, and whether it needs an app id at
    // all -- context-pack.md shows it reading $APP_ID from the environment
    // rather than a --app-id flag, unlike omarchy-launch-or-focus-tui.
    Quickshell.execDetached(["omarchy-launch-tui", scriptPath("receipt-pager"), String(id)])
  }

  function newSession() {
    // bar.run is the confirmed fire-and-forget shell path (agents/Panel.qml
    // launchAgent uses the same call shape for its own "--pick" launch).
    if (root.bar) root.bar.run("omarchy-agent-session-new --pick")
    root.close()
  }

  // Middle click: "most recently needing attention" sorts newest-since
  // first within blocked/waiting -- the opposite order from the Needs You
  // section, which surfaces the *oldest*-neglected session instead. Both
  // orderings are named explicitly and separately in 03-sessions-panel.md.
  function mostRecentAttentionSession() {
    var list = root.allSessions.filter(function(s) {
      return s.status && (s.status.state === "blocked" || s.status.state === "waiting")
    })
    list.sort(function(a, b) {
      var r = root.attentionRank(a.status.state) - root.attentionRank(b.status.state)
      return r !== 0 ? r : root.sinceMs(b) - root.sinceMs(a)
    })
    return list
  }

  function openMostUrgent() {
    var candidates = mostRecentAttentionSession()
    if (candidates.length > 0) root.openSession(candidates[0].id)
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { root.refresh(); return "ok" }
  }

  // ------------------------------------------------------------ bar icon

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // VERIFY ON RIG: glyph codepoint guessed (nerd-font "robot"-family
    // private-use point); neither fetched reference plugin renders a
    // session/agent glyph distinct from their own icons, so this needs a
    // real look on the rig's font.
    text: "󰚩"
    active: true
    activeColor: root.barGlyphColor
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.newSession()
      else if (buttonCode === Qt.MiddleButton) root.openMostUrgent()
      else root.toggle()
    }

    // Badge: count of sessions with needs_attention true.
    // VERIFY ON RIG: neither reference plugin shows a numeric bar badge, so
    // this is a manual overlay rather than a confirmed BarIconButton
    // property; a native badge/count API may already exist on the rig.
    Rectangle {
      visible: root.needsAttentionCount > 0
      width: Math.max(14, badgeText.implicitWidth + Style.space(6))
      height: 14
      radius: height / 2
      color: root.urgentColor
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.rightMargin: -2
      anchors.topMargin: -2

      Text {
        id: badgeText
        anchors.centerIn: parent
        text: root.needsAttentionCount > 99 ? "99+" : String(root.needsAttentionCount)
        color: Color.background
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption - 2 > 8 ? Style.font.caption - 2 : 8
        font.bold: true
      }
    }
  }

  // ------------------------------------------------------------ panel

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(640))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function(dx, dy) {
        if (dy === 0 || root.visibleRows.length === 0) return
        root.cursorActive = true
        if (dy < 0) root.selectedIndex = Math.max(0, root.selectedIndex - 1)
        else root.selectedIndex = Math.min(root.visibleRows.length - 1, root.selectedIndex + 1)
        // VERIFY ON RIG: this skeleton does not scroll the selected row into
        // view. Hermes's reference math assumes a fixed ~52px row height;
        // rows here vary (the inline Send field changes a row's height), so
        // that fixed-offset trick would misplace the scroll. Needs real
        // per-row y positions, e.g. via a ListView, to do properly.
      }
      onActivateRequested: {
        if (root.visibleRows.length === 0) return
        var s = root.visibleRows[root.selectedIndex]
        if (s) { root.openSession(s.id); root.close() }  // the terminal is the point; get the overlay out of its way
      }
      onDeleteRequested: {
        // PanelKeyCatcher routes `x` here, never to onTextKey.
        if (root.visibleRows.length === 0) return
        var s = root.visibleRows[root.selectedIndex]
        if (!s) return
        if (root.armedStopId === s.id) { root.stopSession(s.id); root.armedStopId = "" }
        else { root.sendOpenId = ""; root.armedStopId = s.id }
      }
      onCloseRequested: {
        // Esc clears an armed Stop or an open Send field first, and closes
        // the panel only on the press after that (03-sessions-panel.md).
        if (root.sendOpenId !== "") { root.sendOpenId = ""; return }
        if (root.armedStopId !== "") { root.armedStopId = ""; return }
        root.close()
      }
      onTextKey: function(t) {
        if (root.visibleRows.length === 0) return
        var s = root.visibleRows[root.selectedIndex]
        if (!s) return
        if (t === "s" || t === "S") {
          root.armedStopId = ""
          root.sendOpenId = s.id
        } else if (t === "x" || t === "X") {
          if (root.armedStopId === s.id) {
            root.stopSession(s.id)
            root.armedStopId = ""
          } else {
            root.sendOpenId = ""
            root.armedStopId = s.id
          }
        } else if (t === "r" || t === "R") {
          root.openReceipt(s.id)
        }
      }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(12)

          // ---------- Hero ----------
          PanelHero {
            width: parent.width
            title: root.needsYouRows.length > 0
              ? (root.needsYouRows[0].name || root.needsYouRows[0].id)
              : (root.workingRows.length + " working")
            meta: {
              var base = root.needsYouRows.length > 0
                ? (String(root.needsYouRows[0].status.state) + " · " + root.formatDuration(root.nowMs - root.sinceMs(root.needsYouRows[0])))
                : (root.allSessions.length === 0 ? "No sessions" : "Nothing needs you")
              return root.indexStale ? (base + " · stale (" + root.staleAgeText() + ")") : base
            }
            foreground: root.foreground
            fontFamily: root.fontFamily

            iconComponent: Component {
              Rectangle {
                width: 12; height: 12; radius: 6
                color: root.barGlyphColor
                anchors.centerIn: parent
              }
            }
          }

          // ---------- Error row (three-strikes backoff) ----------
          BorderSurface {
            visible: root.hasErrorRow
            width: parent.width
            implicitHeight: errorText.implicitHeight + Style.spacing.xl * 2
            color: root.alpha(root.urgentColor, 0.10)
            borderSpec: Border.flat(root.alpha(root.urgentColor, 0.35), 1)
            radius: Style.cornerRadius

            Text {
              id: errorText
              textFormat: Text.PlainText
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: Style.space(12)
              anchors.rightMargin: Style.space(12)
              text: root.snapshot ? String(root.snapshot.error || "") : ""
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
          }

          // ---------- No sessions ----------
          Column {
            visible: !root.hasErrorRow && root.allSessions.length === 0
            width: parent.width
            spacing: Style.space(10)
            topPadding: Style.space(16)

            Text {
              width: parent.width
              text: root.snapshot ? "No sessions yet." : "Checking for sessions…"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
            }

            Button {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "New session"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.newSession()
            }
          }

          // ---------- Sections ----------
          Repeater {
            model: [
              { title: "NEEDS YOU", rows: root.needsYouRows, offset: 0 },
              { title: "WORKING", rows: root.workingRows, offset: root.needsYouRows.length },
              { title: "DONE TODAY", rows: root.doneRows, offset: root.needsYouRows.length + root.workingRows.length },
              { title: "ORPHANED", rows: root.orphanedRows, offset: root.needsYouRows.length + root.workingRows.length + root.doneRows.length }
            ]

            delegate: Column {
              required property var modelData
              width: column.width
              spacing: Style.space(8)
              visible: !root.hasErrorRow && modelData.rows.length > 0

              PanelSeparator {
                foreground: root.foreground
              }

              PanelSectionHeader {
                width: parent.width
                text: modelData.title
                foreground: root.foreground
                fontFamily: root.fontFamily
              }

              Repeater {
                model: modelData.rows

                delegate: Session {
                  required property var modelData
                  required property int index

                  session: modelData
                  // Repeater is not a visual Item, so this delegate's actual
                  // `parent` is the enclosing per-section Column above (the
                  // one holding `required property var modelData` with
                  // {title, rows, offset}), not the inner Repeater itself.
                  hasCursor: root.cursorActive && (parent.modelData.offset + index) === root.selectedIndex
                  stopArmed: root.armedStopId === modelData.id
                  stopping: root.stoppingIds[modelData.id] !== undefined
                  sendOpen: root.sendOpenId === modelData.id
                  foreground: root.foreground
                  accent: Color.accent
                  urgentColor: root.urgentColor
                  mutedColor: root.mutedColor
                  fontFamily: root.fontFamily
                  nowMs: root.nowMs
                  formatAge: root.formatDuration

                  onOpenRequested: function(id) { root.openSession(id) }
                  onSendOpenRequested: function(id) { root.armedStopId = ""; root.sendOpenId = id }
                  onSendSubmitRequested: function(id, text) { root.sendToSession(id, text); root.sendOpenId = "" }
                  onSendCancelRequested: function(id) { root.sendOpenId = "" }
                  onStopArmRequested: function(id) { root.sendOpenId = ""; root.armedStopId = id }
                  onStopConfirmRequested: function(id) { root.stopSession(id); root.armedStopId = "" }
                  onReceiptRequested: function(id) { root.openReceipt(id) }
                }
              }
            }
          }

          Item {
            width: parent.width
            height: Style.space(2)
          }
        }
      }
    }
  }
}
