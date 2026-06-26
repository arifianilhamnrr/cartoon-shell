import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.components
import qs.commons

PanelWindow {
  id: root

  property real animationProgress: 0
  property var lang: LanguageService.translations
  property var theme: ThemeService.theme

  signal confirmRequested(string action, string actionLabel)

  readonly property var actions: [
    {
      id: "lock",
      label: lang?.system?.lock || "Lock Screen",
      icon: "system/sys-lock.png",
      confirm: false
    },
    {
      id: "sleep",
      label: lang?.system?.sleep || "Sleep Mode",
      icon: "system/sys-sleep.png",
      confirm: true,
      confirmLabel: lang?.confirm?.sleep || "enter sleep mode"
    },
    {
      id: "hibernate",
      label: lang?.system?.hibernate || "Hibernate",
      icon: "system/sys-sleep.png",
      confirm: true,
      confirmLabel: lang?.confirm?.hibernate || "hibernate"
    },
    {
      id: "restart",
      label: lang?.system?.restart || "Restart",
      icon: "system/sys-reboot.png",
      confirm: true,
      confirmLabel: lang?.confirm?.restart || "restart"
    },
    {
      id: "shutdown",
      label: lang?.system?.shutdown || "Shutdown",
      icon: "system/poweroff.png",
      confirm: true,
      confirmLabel: lang?.confirm?.shutdown || "shutdown"
    }
  ]

  function activateAction(action) {
    if (!action)
      return;

    VisibleService.togglePanel("session");

    if (action.id === "lock") {
      Quickshell.execDetached([
        "qs", "ipc", "--path",
        Directories.home + "/.config/quickshell/cartoon-shell/",
        "call", "lock", "lock"
      ]);
      return;
    }

    if (action.confirm)
      root.confirmRequested(action.id, action.confirmLabel || action.label);
  }

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  exclusiveZone: 0
  color: "transparent"
  focusable: true
  WlrLayershell.keyboardFocus: VisibleService.session
    ? WlrKeyboardFocus.Exclusive
    : WlrKeyboardFocus.None

  function selectPrevious() {
    const count = root.actions.length;
    if (count === 0)
      return;
    actionList.currentIndex = actionList.currentIndex <= 0
      ? count - 1
      : actionList.currentIndex - 1;
  }

  function selectNext() {
    const count = root.actions.length;
    if (count === 0)
      return;
    actionList.currentIndex = (actionList.currentIndex + 1) % count;
  }

  SequentialAnimation on animationProgress {
    running: VisibleService.session
    NumberAnimation {
      from: 0
      to: 1
      duration: 220
      easing.type: Easing.OutCubic
    }
  }

  onVisibleChanged: {
    if (visible) {
      actionList.currentIndex = 0;
    } else {
      root.animationProgress = 0;
    }
  }

  Shortcut {
    enabled: VisibleService.session
    sequence: "Up"
    onActivated: root.selectPrevious()
  }

  Shortcut {
    enabled: VisibleService.session
    sequence: "Down"
    onActivated: root.selectNext()
  }

  Shortcut {
    enabled: VisibleService.session
    sequence: "Return"
    onActivated: root.activateAction(root.actions[actionList.currentIndex])
  }

  Shortcut {
    enabled: VisibleService.session
    sequence: "Escape"
    onActivated: VisibleService.togglePanel("session")
  }

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(theme.primary.background.r, theme.primary.background.g, theme.primary.background.b, 0.55 * root.animationProgress)
    opacity: root.animationProgress

    MouseArea {
      anchors.fill: parent
      onClicked: VisibleService.togglePanel("session")
    }
  }

  Rectangle {
    anchors.centerIn: parent
    width: ScalerService.s(380)
    height: menuColumn.implicitHeight + ScalerService.s(32)
    opacity: root.animationProgress
    scale: 0.94 + (root.animationProgress * 0.06)
    color: theme.primary.background
    border.color: theme.button.border
    radius: ScalerService.s(Settings.appearance.radius1)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0

    ColumnLayout {
      id: menuColumn
      anchors.fill: parent
      anchors.margins: ScalerService.s(16)
      spacing: ScalerService.s(12)

      CustomText {
        name: lang?.session_menu?.title || "Session Menu"
        size: "large"
        isBold: true
        Layout.alignment: Qt.AlignHCenter
      }

      CustomText {
        name: lang?.session_menu?.hint || "↑↓ navigate · Enter select · Esc close"
        size: "xs"
        textColor: theme.primary.dim_foreground
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(1)
        color: theme.primary.foreground
        opacity: 0.2
      }

      ListView {
        id: actionList
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(56) * root.actions.length + ScalerService.s(4) * (root.actions.length - 1)
        clip: true
        spacing: ScalerService.s(4)
        model: root.actions
        currentIndex: 0
        interactive: false

        delegate: Rectangle {
          width: actionList.width
          height: ScalerService.s(56)
          radius: ScalerService.s(Settings.appearance.radius3)
          color: ListView.isCurrentItem
            ? Qt.alpha(theme.button.background_select, 0.85)
            : Qt.alpha(theme.primary.dim_background, 0.45)
          border.color: ListView.isCurrentItem ? theme.button.border_select : theme.button.border
          border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

          RowLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(10)
            spacing: ScalerService.s(12)

            IconImage {
              path: modelData.icon
              size: "normal"
            }

            CustomText {
              name: modelData.label
              size: "small"
              isBold: ListView.isCurrentItem
              Layout.fillWidth: true
            }

            IconText {
              visible: ListView.isCurrentItem
              name: "keyboard_return"
              size: "small"
              textColor: theme.primary.dim_foreground
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              actionList.currentIndex = index;
              root.activateAction(modelData);
            }
            onContainsMouseChanged: {
              if (containsMouse)
                actionList.currentIndex = index;
            }
          }
        }
      }
    }
  }
}