import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.commons

PanelWindow {
  id: root

  property var lang: LanguageService.translations
  property var theme: ThemeService.theme

  property string pendingAction: ""
  property string pendingActionLabel: ""

  implicitWidth: ScalerService.s(380)
  implicitHeight: ScalerService.s(200)

  anchors {
    top: true
    left: true
  }
  margins {
    top: screen ? Math.round((screen.height - implicitHeight) / 2) : 0
    left: screen ? Math.round((screen.width - implicitWidth) / 2) : 0
  }

  exclusiveZone: 0
  visible: false
  color: "transparent"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  property bool yesSelected: false

  Process {
    id: sleepProcess
  }
  Process {
    id: lockProcess
  }
  Process {
    id: hibernateProcess
  }
  Process {
    id: restartProcess
  }
  Process {
    id: shutdownProcess
  }

  function show(action, actionLabel) {
    pendingAction = action;
    pendingActionLabel = actionLabel;
    yesSelected = false;
    visible = true;
    Qt.callLater(function () {
      keyboardCapture.forceActiveFocus();
    });
  }

  function hide() {
    visible = false;
    pendingAction = "";
    pendingActionLabel = "";
  }

  function executeAction() {
    switch (pendingAction) {
      case "sleep":
      sleepProcess.command = [
      "sh",
      "-c",
      "systemctl suspend && qs ipc --path ~/.config/quickshell/cartoon-shell/ call lock lock"
      ];
      sleepProcess.startDetached();
      break;
      case "lock":
      lockProcess.command = [
      "qs",
      "ipc",
      "--path",
      Directories.home + "/.config/quickshell/cartoon-shell/",
      "call",
      "lock",
      "lock"
      ]
      lockProcess.startDetached();
      break;
      case "hibernate":
      hibernateProcess.command = [
      "sh",
      "-c",
      "systemctl hibernate || loginctl hibernate"
      ];
      hibernateProcess.startDetached();
      break;
      case "restart":
      restartProcess.command = ["systemctl", "reboot"];
      restartProcess.startDetached();
      break;
      case "shutdown":
      shutdownProcess.command = ["systemctl", "poweroff"];
      shutdownProcess.startDetached();
      break;
    }
    hide();
  }

  Rectangle {
    anchors.fill: parent
    radius: ScalerService.s(15)
    color: theme.primary.background
    border.color: theme.normal.black
    border.width: ScalerService.s(3)

    Column {
      anchors.fill: parent
      anchors.margins: ScalerService.s(25)
      spacing: ScalerService.s(20)

      Text {
        text: lang?.confirm?.title || "Confirm"
        color: theme.primary.foreground
        font.pixelSize: ScalerService.s(24)
        font.bold: true
        font.family: "ComicShannsMono Nerd Font"
        anchors.horizontalCenter: parent.horizontalCenter
      }

      Text {
        text: (lang?.confirm?.message || "Are you sure you want to {action}?").replace("{action}", pendingActionLabel)
        color: theme.primary.foreground
        font.pixelSize: ScalerService.s(16)
        font.family: "ComicShannsMono Nerd Font"
        wrapMode: Text.WordWrap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: ScalerService.s(30)

        Rectangle {
          id: noButton
          width: ScalerService.s(110)
          height: ScalerService.s(45)
          radius: ScalerService.s(10)
          readonly property bool highlighted: mouseAreaNo.containsMouse || (!root.yesSelected && !mouseAreaYes.containsMouse)
          color: highlighted ? theme.button.background_select : theme.button.background
          border.color: highlighted ? theme.button.border_select : theme.button.border
          border.width: ScalerService.s(2)

          Text {
            anchors.centerIn: parent
            text: lang?.confirm?.no || "No"
            color: theme.primary.foreground
            font.pixelSize: ScalerService.s(18)
            font.family: "ComicShannsMono Nerd Font"
          }

          MouseArea {
            id: mouseAreaNo
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: hide()
            onContainsMouseChanged: {
              if (containsMouse)
                root.yesSelected = false;
            }
          }
        }

        Rectangle {
          id: yesButton
          width: ScalerService.s(110)
          height: ScalerService.s(45)
          radius: ScalerService.s(10)
          readonly property bool highlighted: mouseAreaYes.containsMouse || (root.yesSelected && !mouseAreaNo.containsMouse)
          color: highlighted ? theme.normal.red : theme.button.background
          border.color: theme.normal.red
          border.width: ScalerService.s(2)

          Text {
            anchors.centerIn: parent
            text: lang?.confirm?.yes || "Yes"
            color: parent.highlighted ? "white" : theme.primary.foreground
            font.pixelSize: ScalerService.s(18)
            font.family: "ComicShannsMono Nerd Font"
            font.bold: true
          }

          MouseArea {
            id: mouseAreaYes
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: executeAction()
            onContainsMouseChanged: {
              if (containsMouse)
                root.yesSelected = true;
            }
          }
        }
      }
    }
  }

  Item {
    id: keyboardCapture
    z: -1
    anchors.fill: parent
    focus: root.visible

    Keys.onPressed: function (event) {
      if (event.key === Qt.Key_Escape) {
        hide();
        event.accepted = true;
        return;
      }

      if (event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
        yesSelected = !yesSelected;
        event.accepted = true;
        return;
      }

      if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        if (yesSelected)
          executeAction();
        else
          hide();
        event.accepted = true;
        return;
      }

      if (event.key === Qt.Key_Y) {
        executeAction();
        event.accepted = true;
        return;
      }

      if (event.key === Qt.Key_N) {
        hide();
        event.accepted = true;
      }
    }
  }

  Shortcut {
    sequence: "Escape"
    onActivated: hide()
  }
}
