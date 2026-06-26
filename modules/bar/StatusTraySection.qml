import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick.Controls
import Quickshell.Services.SystemTray
import qs.services
import qs.commons
import qs.components
import "./widget/" as Com

Rectangle {
  id: root
  border.color: theme.button.border
  border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
  radius: ScalerService.s(Settings.appearance.radius2)
  color: theme.primary.background
  anchors.verticalCenter: parent.verticalCenter
  anchors.right: isVertical ? undefined : parent.right
  anchors.horizontalCenter: isVertical ? parent.horizontalCenter : undefined
  property real animationProgress: 0
  readonly property int contentPadding: ScalerService.s(10)
  SequentialAnimation on animationProgress {
    running: true
    NumberAnimation {
      from: 0
      to: 1
      duration: 1000
      easing.type: Easing.Linear
    }
  }
  implicitWidth: {
    if (root.animationProgress <= 0.5)
      return 0;
    if (isVertical)
      return parent.width;
    const contentWidth = trayLoader.item ? trayLoader.item.implicitWidth : 0;
    return contentWidth + (contentPadding * 2);
  }
  implicitHeight: root.animationProgress > 0.5 ? parent.height : 0
  width: implicitWidth
  height: implicitHeight
  Behavior on implicitHeight {
    NumberAnimation {
      id: heightAnim
      duration: 500
      easing.type: Easing.OutCubic
    }
  }
  Behavior on implicitWidth {
    NumberAnimation {
      id: widthAnim
      duration: 500
      easing.type: Easing.OutCubic
    }
  }

  property real currentVolume: Pipewire.defaultAudioSink?.audio.volume ?? 0
  property bool isMuted: Pipewire.defaultAudioSink?.audio.mute ?? false
  property bool isVertical: Settings.bar.position === "left" || Settings.bar.position === "right"
  property bool shouldShowOsd: false

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  Connections {
    target: Pipewire.defaultAudioSink?.audio ?? null
  }

  // UI Layout
  Loader {
    id: trayLoader
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: isVertical ? parent.horizontalCenter : undefined
    anchors.right: isVertical ? undefined : parent.right
    anchors.rightMargin: isVertical ? 0 : contentPadding
    anchors.leftMargin: isVertical ? contentPadding : 0
    anchors.topMargin: isVertical ? ScalerService.s(6) : 0
    anchors.bottomMargin: isVertical ? ScalerService.s(6) : 0
    width: isVertical
      ? (parent.width - contentPadding * 2)
      : (item ? item.implicitWidth : 0)
    height: isVertical
      ? (parent.height - ScalerService.s(12))
      : (item ? item.implicitHeight : parent.height)
    sourceComponent: isVertical ? verticalLayout : horizontalLayout
  }

  Component {
    id: horizontalLayout

    RowLayout {
      id: horizontalTrayRow
      spacing: ScalerService.s(8)

      // System Tray Icons
      Repeater {
        id: trayRepeater
        model: SystemTray.items

        Rectangle {
          id: trayItemContainer
          Layout.preferredWidth: ScalerService.s(30)
          Layout.preferredHeight: ScalerService.s(30)
          Layout.alignment: Qt.AlignVCenter
          color: "transparent"
          radius: ScalerService.s(6)
          transformOrigin: Item.Center

          visible: modelData.icon !== ""
          property var trayItem: modelData

          TrayIconImage {
            id: trayIcon
            anchors.centerIn: parent
            width: ScalerService.s(22)
            height: ScalerService.s(22)
            trayId: trayItemContainer.trayItem?.id || ""
            trayTitle: trayItemContainer.trayItem?.title || ""
            trayTooltip: trayItemContainer.trayItem?.tooltipTitle || ""
            source: trayItemContainer.trayItem?.icon || ""

            ToolTip {
              id: trayTooltip
              visible: trayTooltipArea.containsMouse && trayItemContainer.trayItem?.tooltipTitle
              text: trayItemContainer.trayItem?.tooltipTitle || ""
              delay: 1000
            }
          }

          MouseArea {
            id: trayTooltipArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            onEntered: trayItemContainer.scale = 1.1
            onExited: trayItemContainer.scale = 1.0
            onPressed: trayItemContainer.scale = 0.95
            onReleased: trayItemContainer.scale = containsMouse ? 1.1 : 1.0

            onClicked: function (mouse) {
              if (!trayItemContainer.trayItem)
              return;
              if (mouse.button === Qt.LeftButton) {
                trayItemContainer.trayItem.activate();
              } else if (mouse.button === Qt.RightButton) {
                if (trayItemContainer.trayItem.hasMenu && trayItemContainer.trayItem.menu) {
                  trayItemContainer.trayItem.display(root, mouse.x, mouse.y);
                }
              } else if (mouse.button === Qt.MiddleButton) {
                trayItemContainer.trayItem.secondaryActivate();
              }
            }

            onWheel: function (wheel) {
              if (!trayItemContainer.trayItem)
              return;
              trayItemContainer.trayItem.scroll(wheel.angleDelta.y, wheel.angleDelta.x !== 0);
            }
          }

          Behavior on scale {
            NumberAnimation {
              duration: 100
              easing.type: Easing.OutCubic
            }
          }
        }
      }

      // Bluetooth
      Com.StatContainer {
        Layout.preferredWidth: ScalerService.s(32)
        Layout.preferredHeight: ScalerService.s(32)
        Layout.alignment: Qt.AlignVCenter
        panelName: "bluetooth"

        Com.BluetoothStat {
          anchors.centerIn: parent
        }
      }

      Com.StatContainer {
        Layout.preferredWidth: ScalerService.s(32)
        Layout.preferredHeight: ScalerService.s(32)
        Layout.alignment: Qt.AlignVCenter
        panelName: "wifi"

        Com.WifiStat {
          anchors.centerIn: parent
        }
      }

      // Volume
      Com.StatContainer {
        Layout.preferredWidth: ScalerService.s(32)
        Layout.preferredHeight: ScalerService.s(32)
        Layout.alignment: Qt.AlignVCenter
        panelName: "mixer"

        Com.VolumeStat {
          anchors.centerIn: parent
        }
      }

      Com.StatContainer {
        Layout.preferredWidth: batteryStat.width + ScalerService.s(4)
        Layout.preferredHeight: ScalerService.s(32)
        Layout.alignment: Qt.AlignVCenter
        panelName: "battery"

        Com.BatteryStat {
          id: batteryStat
          anchors.centerIn: parent
        }
      }

      // Power Off
      Rectangle {
        id: powerContainer
        Layout.preferredWidth: ScalerService.s(30)
        Layout.preferredHeight: ScalerService.s(30)
        Layout.alignment: Qt.AlignVCenter
        color: "transparent"
        radius: ScalerService.s(6)
        transformOrigin: Item.Center

        Image {
          id: powerIcon
          source: Directories.assetsPath + '/system/poweroff.png'
          width: ScalerService.s(24)
          height: ScalerService.s(24)
          sourceSize: Qt.size(ScalerService.s(24), ScalerService.s(24))
          anchors.centerIn: parent
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onEntered: powerContainer.scale = 1.2
          onExited: powerContainer.scale = 1.0
          onPressed: powerContainer.scale = 0.9
          onReleased: powerContainer.scale = 1.2

          onClicked: VisibleService.togglePanel("dashboard")
        }

        Behavior on scale {
          NumberAnimation {
            duration: 100
          }
        }
      }
    }
  }

  Component {
    id: verticalLayout

    ColumnLayout {
      anchors.fill: parent
      spacing: ScalerService.s(8)

      // System Tray Icons (vertical)
      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: contentVerticalTray.height

        Item {
          anchors.centerIn: parent
          width: parent.height
          height: parent.width
          transformOrigin: Item.Center

          ColumnLayout {
            id: contentVerticalTray
            anchors.centerIn: parent
            spacing: ScalerService.s(4)

            Repeater {
              model: SystemTray.items

              Rectangle {
                id: trayItemContainerVertical
                Layout.preferredWidth: ScalerService.s(25)
                Layout.preferredHeight: ScalerService.s(25)
                color: "transparent"
                radius: ScalerService.s(4)

                visible: modelData.icon !== ""
                property var trayItem: modelData

                TrayIconImage {
                  anchors.centerIn: parent
                  width: ScalerService.s(20)
                  height: ScalerService.s(20)
                  trayId: trayItemContainerVertical.trayItem?.id || ""
                  trayTitle: trayItemContainerVertical.trayItem?.title || ""
                  trayTooltip: trayItemContainerVertical.trayItem?.tooltipTitle || ""
                  source: trayItemContainerVertical.trayItem?.icon || ""
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor

                  onEntered: trayItemContainerVertical.scale = 1.1
                  onExited: trayItemContainerVertical.scale = 1.0
                  onClicked: function (mouse) {
                    if (!trayItemContainerVertical.trayItem)
                    return;
                    if (mouse.button === Qt.LeftButton) {
                      trayItemContainerVertical.trayItem.activate();
                    }
                  }
                }

                Behavior on scale {
                  NumberAnimation {
                    duration: 100
                  }
                }
              }
            }
          }
        }
      }

      // Bluetooth (vertical)
      Com.StatContainer {
        Layout.fillWidth: true
        Layout.fillHeight: true
        panelName: "bluetooth"

        Com.BluetoothStat {
          anchors.centerIn: parent
        }
      }

      Item {
        Layout.fillWidth: true
      }

      Com.StatContainer {
        Layout.fillWidth: true
        Layout.fillHeight: true
        panelName: "wifi"

        Com.WifiStat {
          anchors.centerIn: parent
        }
      }

      Item {
        Layout.fillWidth: true
      }

      // Volume (vertical)
      Com.StatContainer {
        Layout.fillWidth: true
        Layout.fillHeight: true
        panelName: "mixer"

        Com.VolumeStat {
          anchors.centerIn: parent
        }
      }

      Com.StatContainer {
        Layout.fillWidth: true
        Layout.preferredHeight: batteryStatVertical.height + ScalerService.s(8)
        panelName: "battery"

        Com.BatteryStat {
          id: batteryStatVertical
          anchors.centerIn: parent
          vertical: true
        }
      }

      // Power (vertical)
      Item {
        width: ScalerService.s(25)
        height: ScalerService.s(25)

        Item {
          anchors.centerIn: parent
          width: parent.height
          height: parent.width
          transformOrigin: Item.Center

          Image {
            id: powerIconVertical
            anchors.centerIn: parent
            source: Directories.assetsPath + '/system/poweroff.png'
            width: ScalerService.s(25)
            height: ScalerService.s(25)
            sourceSize: Qt.size(ScalerService.s(25), ScalerService.s(25))
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: VisibleService.togglePanel("dashboard")
          onEntered: parent.opacity = 0.8
          onExited: parent.opacity = 1.0
        }

        Behavior on opacity {
          NumberAnimation {
            duration: 100
          }
        }
      }
    }
  }
}

