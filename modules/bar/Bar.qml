import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.bar
import qs.commons
import qs.services

PanelWindow {
  id: panel
  // Kích thước cố định cho mỗi hướng

  implicitWidth: (Settings.bar.position === "left" || Settings.bar.position === "right") ? ScalerService.s(40) : Screen.width
  implicitHeight: (Settings.bar.position === "top" || Settings.bar.position === "bottom") ? ScalerService.s(50) : Screen.height

  color: "transparent"

  anchors {
    left: (Settings.bar.position === "left" || Settings.bar.position === "top" || Settings.bar.position === "bottom") ? true : false
    right: (Settings.bar.position === "right" || Settings.bar.position === "top" || Settings.bar.position === "bottom") ? true : false
    top: (Settings.bar.position === "top" || Settings.bar.position === "left" || Settings.bar.position === "right") ? true : false
    bottom: (Settings.bar.position === "bottom" || Settings.bar.position === "left" || Settings.bar.position === "right") ? true : false
  }

  margins {
    top: (Settings.bar.position === "top" || Settings.bar.position === "left" || Settings.bar.position === "right") ? ScalerService.s(10) : 0
    left: (Settings.bar.position === "left" || Settings.bar.position === "top" || Settings.bar.position === "bottom") ? ScalerService.s(10) : 0
    right: (Settings.bar.position === "right" || Settings.bar.position === "top" || Settings.bar.position === "bottom") ? ScalerService.s(10) : 0
    bottom: (Settings.bar.position === "bottom" || Settings.bar.position === "left" || Settings.bar.position === "right") ? ScalerService.s(10) : 0
  }

  // Xác định layout dựa trên vị trí
  property bool isVertical: Settings.bar.position === "left" || Settings.bar.position === "right"

  Loader {
    anchors.fill: parent
    sourceComponent: isVertical ? verticalLayout : horizontalLayout
  }

  // Component cho layout ngang (top/bottom)
  Component {
    id: horizontalLayout

    RowLayout {
      id: horizontal
      property real animationProgress: 0
      SequentialAnimation on animationProgress {
        running: true
        NumberAnimation {
          from: 0
          to: 0.6
          duration: 100
          easing.type: Easing.Linear
        }
      }
      anchors.fill: parent
      spacing: ScalerService.s(6)

      Item {
        Layout.preferredWidth: ScalerService.s(60)
        Layout.fillHeight: true
        LauncherSection {
          animationProgress: horizontal.animationProgress
        }
      }

      Item {
        Layout.preferredWidth: ScalerService.s(380)
        Layout.fillHeight: true
        WorkspaceSection {
          animationProgress: horizontal.animationProgress
        }
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumWidth: ScalerService.s(180)
        MediaSection {
          animationProgress: horizontal.animationProgress
        }
      }

      Item {
        Layout.preferredWidth: ScalerService.s(400)
        Layout.fillHeight: true
        InfoSection {
          animationProgress: horizontal.animationProgress
        }
      }

      Item {
        Layout.preferredWidth: (Settings.bar.cpu.active || Settings.bar.ram.active) ? ScalerService.s(200) : 0
        Layout.fillHeight: true
        visible: Settings.bar.cpu.active || Settings.bar.ram.active
        SystemStatsSection {
          animationProgress: horizontal.animationProgress
        }
      }

      Item {
        Layout.fillHeight: true
        Layout.preferredWidth: statusTrayHost.implicitWidth
        Layout.minimumWidth: statusTrayHost.implicitWidth
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

        Item {
          id: statusTrayHost
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          height: parent.height
          implicitWidth: statusTray.implicitWidth

          StatusTraySection {
            id: statusTray
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            width: implicitWidth
            animationProgress: horizontal.animationProgress
          }
        }
      }

    }
  }

  // Component cho layout dọc (left/right)
  Component {
    id: verticalLayout

    ColumnLayout {
      id: vertical
      property real animationProgress: 0
      SequentialAnimation on animationProgress {
        running: true
        NumberAnimation {
          from: 0
          to: 0.6
          duration: 100
          easing.type: Easing.Linear
        }
      }
      anchors.fill: parent
      spacing: ScalerService.s(6)

      Item {
        Layout.fillHeight: true
      }

      Item {
        Layout.preferredHeight: ScalerService.s(40)
        Layout.fillWidth: true
        LauncherSection {
          animationProgress: vertical.animationProgress
        }
      }

      Item {
        Layout.preferredHeight: ScalerService.s(280)
        Layout.fillWidth: true
        WorkspaceSection {
          animationProgress: vertical.animationProgress
        }
      }

      Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.minimumHeight: ScalerService.s(120)
        MediaSection {
          animationProgress: vertical.animationProgress
        }
      }

      Item {
        Layout.preferredHeight: ScalerService.s(180)
        Layout.fillWidth: true
        InfoSection {
          animationProgress: vertical.animationProgress
        }
      }

      Item {
        Layout.preferredHeight: (Settings.bar.cpu.active || Settings.bar.ram.active) ? ScalerService.s(100) : 0
        Layout.fillWidth: true
        visible: Settings.bar.cpu.active || Settings.bar.ram.active
        SystemStatsSection {
          animationProgress: vertical.animationProgress
        }
      }

      Item {
        Layout.preferredHeight: ScalerService.s(230)
        Layout.fillWidth: true
        StatusTraySection {
          animationProgress: vertical.animationProgress
        }
      }

      Item {
        Layout.fillHeight: true
      }
    }
  }
}
