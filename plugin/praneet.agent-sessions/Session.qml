import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

// One session row for the Agent Sessions panel: name, agent glyph, state
// with since-duration, workspace branch, owner label, child count, and the
// Open/Send/Stop/Receipt actions. Pulled out of Panel.qml into its own file
// per 03-sessions-panel.md ("Session.qml is one row, instantiated per
// session"). Structurally this is the Hermes Panel.qml session row
// (CursorSurface + MouseArea + PanelToolTip) factored into a standalone
// component; Hermes keeps its equivalent row inline in Panel.qml instead.
//
// Rendering and local UI affordances only -- every action a person can take
// is a signal. Panel.qml owns the actual omarchy-agent-session-* calls and
// the cross-row state (which row has an armed Stop or an open Send field),
// because Esc has to be able to clear either regardless of which row it
// belongs to.
CursorSurface {
  id: row

  // ---- inputs ----
  property var session: null          // one row object from list --json
  property bool hasCursor: false      // keyboard selection, owned by Panel.qml
  property bool stopArmed: false      // second x / click within this arm executes
  property bool sendOpen: false       // inline send field visible
  property bool stopping: false       // Stop confirmed, record not yet stopped; owned by Panel.qml
  property color foreground: Color.foreground
  property color accent: Color.accent
  property color urgentColor: Color.urgent
  property color mutedColor: Color.muted
  property string fontFamily: Style.font.family
  property double nowMs: Date.now()

  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property var spinnerFrames: ["◐", "◓", "◑", "◒"]
  property int spinnerIndex: 0
  Timer {
    running: row.stopping
    interval: 120; repeat: true
    onTriggered: row.spinnerIndex = (row.spinnerIndex + 1) % row.spinnerFrames.length
  }

  // ---- outputs ----
  signal openRequested(string id)
  signal sendOpenRequested(string id)
  signal sendSubmitRequested(string id, string text)
  signal sendCancelRequested(string id)
  signal stopArmRequested(string id)
  signal stopConfirmRequested(string id)
  signal receiptRequested(string id)

  readonly property string sid: session ? String(session.id || "") : ""
  readonly property string sname: session && session.name ? String(session.name) : sid
  readonly property string agentKind: session && session.agent ? String(session.agent.kind || "") : ""
  readonly property string state: session && session.status ? String(session.status.state || "") : ""
  readonly property string sinceIso: session && session.status ? String(session.status.since || "") : ""
  // Heuristic status dot: 03-sessions-panel.md "a row whose status.source is
  // herdr-manifest, the heuristic path, shows a small outlined dot beside
  // the state text". list --json's example in 02-command-surface.md does
  // not show a `source` field on status, so this treats it as optional and
  // absent-by-default (dot hidden unless the field is present and matches).
  readonly property bool lowConfidence: session && session.status
    ? String(session.status.source || "") === "herdr-manifest" : false
  readonly property string branch: session && session.workspace ? String(session.workspace.branch || "") : ""
  readonly property string ownerLabel: session && session.owner
    ? String(session.owner.label || session.owner.id || "") : ""
  readonly property int childCount: session ? Number(session.children || 0) : 0
  readonly property bool needsAttention: session ? session.needs_attention === true : false

  function durationText() {
    var ms = sinceIso !== "" ? new Date(sinceIso).getTime() : NaN
    if (!isFinite(ms)) return ""
    var d = Math.max(0, nowMs - ms)
    var mins = Math.floor(d / 60000)
    if (mins < 1) return "just now"
    if (mins < 60) return mins + "m"
    var hours = Math.floor(mins / 60)
    if (hours < 24) return hours + "h " + (mins % 60) + "m"
    var days = Math.floor(hours / 24)
    return days + "d " + (hours % 24) + "h"
  }

  // Per-row state color; same three-way scheme as the bar glyph in
  // Panel.qml, applied per session instead of rolled up across all of them.
  readonly property color stateColor: state === "blocked" ? urgentColor
    : (state === "waiting" ? foreground : mutedColor)

  current: state === "working" || state === "starting"
  bordered: false

  width: parent ? parent.width : 0
  implicitHeight: Math.max(Style.space(4), mainColumn.implicitHeight + Style.space(16))

  MouseArea {
    id: rowMouse
    // Row actions table: "Open (default) | Enter, or click the row". The
    // action buttons below sit in their own Row and stop propagation via
    // their own MouseArea-less Button clicks, so a click on Send/Stop/
    // Receipt does not also fire this row-open handler.
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    cursorShape: Qt.PointingHandCursor
    onClicked: row.openRequested(row.sid)
    z: -1 // sits behind the action buttons so their own clicks win
  }

  Column {
    id: mainColumn
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(12)
    anchors.rightMargin: Style.space(12)
    spacing: Style.space(4)

    // ---------- name + state ----------
    Row {
      width: parent.width
      spacing: Style.space(6)

      Rectangle {
        width: 8; height: 8; radius: 4
        color: row.stateColor
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: row.agentKind !== "" ? row.agentKind : "?"
        color: row.dim
        font.family: row.fontFamily
        font.pixelSize: Style.font.caption
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        id: nameText
        textFormat: Text.PlainText
        text: row.sname
        color: row.foreground
        font.family: row.fontFamily
        font.pixelSize: Style.font.body
        font.bold: row.needsAttention
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - stateLabel.width - (row.lowConfidence ? 16 : 0) - Style.space(24)
      }

      // Low-confidence dot: shape (outlined circle) plus a tooltip, never
      // color alone, per the spec's accessibility rule for heuristic status.
      Rectangle {
        visible: row.lowConfidence
        width: 6; height: 6; radius: 3
        color: "transparent"
        border.color: row.dim
        border.width: 1
        anchors.verticalCenter: parent.verticalCenter

        MouseArea { id: dotHover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton; z: 1 }
        PanelToolTip {
          visible: dotHover.containsMouse
          text: "status inferred from on-screen text; no lifecycle hook available."
          fontFamily: row.fontFamily
        }
      }

      // Praneet, rig, 2026-09-02: after confirming Stop nothing changed on
      // screen until the next poll, which read as "did that work?". While
      // the stop runs the state label becomes a spinner plus "stopping",
      // and the action buttons stand down.
      Text {
        id: stateLabel
        textFormat: Text.PlainText
        text: row.stopping
          ? (row.spinnerFrames[row.spinnerIndex] + " stopping")
          : (row.state + (row.durationText() !== "" ? " · " + row.durationText() : ""))
        color: row.stopping ? row.urgentColor : row.dim
        font.family: row.fontFamily
        font.pixelSize: Style.font.caption
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    // ---------- workspace / owner / children ----------
    Text {
      visible: !row.sendOpen
      textFormat: Text.PlainText
      width: parent.width
      text: [row.branch, row.ownerLabel,
             row.childCount > 0 ? (row.childCount + " child" + (row.childCount === 1 ? "" : "ren")) : ""]
        .filter(function(t) { return t !== "" }).join(" · ")
      color: row.dim
      font.family: row.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }

    // ---------- inline Send field ----------
    Row {
      width: parent.width
      visible: row.sendOpen
      spacing: Style.space(6)

      TextField {
        id: sendField
        // VERIFY ON RIG: plain QtQuick.Controls.TextField, not an
        // Omarchy-themed input -- neither reference plugin uses a text
        // input, so there is no confirmed themed equivalent to reach for.
        // It may look inconsistent against the shell's own controls until
        // checked on the rig.
        width: parent.width - sendButton.width - Style.space(6)
        placeholderText: "Send an instruction…"
        focus: row.sendOpen
        onAccepted: { row.sendSubmitRequested(row.sid, text); text = "" }
        Keys.onEscapePressed: row.sendCancelRequested(row.sid)
      }
      Button {
        id: sendButton
        text: "Send"
        bordered: true
        foreground: row.foreground
        fontFamily: row.fontFamily
        onClicked: { row.sendSubmitRequested(row.sid, sendField.text); sendField.text = "" }
      }
    }

    // ---------- actions: Send / Stop / Receipt ----------
    Row {
      width: parent.width
      spacing: Style.space(10)
      visible: !row.sendOpen
      // "Row height and every action control are at least Style.space(4)
      // tall" per the spec's accessibility section, applied literally here.
      height: Math.max(Style.space(4), implicitHeight)

      Button {
        text: "s Send"
        bordered: true
        enabled: !row.stopping
        foreground: row.foreground
        fontFamily: row.fontFamily
        fontSize: Style.font.caption
        onClicked: row.sendOpenRequested(row.sid)
      }
      Button {
        text: row.stopping ? "stopping…" : (row.stopArmed ? "x Confirm stop" : "x Stop")
        bordered: true
        enabled: !row.stopping
        foreground: (row.stopArmed || row.stopping) ? row.urgentColor : row.foreground
        fontFamily: row.fontFamily
        fontSize: Style.font.caption
        onClicked: row.stopArmed ? row.stopConfirmRequested(row.sid) : row.stopArmRequested(row.sid)
      }
      Button {
        text: "r Receipt"
        bordered: true
        foreground: row.foreground
        fontFamily: row.fontFamily
        fontSize: Style.font.caption
        onClicked: row.receiptRequested(row.sid)
      }
    }
  }

  PanelToolTip {
    visible: rowMouse.containsMouse && row.branch !== ""
    text: row.branch
    fontFamily: row.fontFamily
  }
}
