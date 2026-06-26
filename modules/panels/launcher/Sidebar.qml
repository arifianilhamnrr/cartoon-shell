import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.components
import qs.commons

Rectangle {
  id: root
  Layout.preferredWidth: ScalerService.s(210)
  property real animationProgress: 0

  SequentialAnimation on animationProgress {
    running: true

    NumberAnimation {
      from: 0
      to: 1
      duration: 700
      easing.type: Easing.Linear
    }
  }
  Layout.fillHeight: true
  color: Qt.alpha(theme.primary.dim_background,0.6)
  border.color: theme.button.border
  radius: ScalerService.s(Settings.appearance.radius2)
  border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: ScalerService.s(12)
    spacing: ScalerService.s(10)

    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: ScalerService.s(60)
      CustomRectangle {
        id: launcherButton
        anchors.centerIn: parent
        implicitWidth: root.animationProgress > 0.1 ? parent.width : 0
        implicitHeight: root.animationProgress > 0.1 ? parent.height : 0
        color: ThemeService.menuItemBackground(mouseAreaLauncher.containsMouse || mouseAreaLauncher.containsPress)
        border.color: ThemeService.menuItemBorder(mouseAreaLauncher.containsMouse || mouseAreaLauncher.containsPress)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
        radius: ScalerService.s(Settings.appearance.radius3)
        scale: mouseAreaLauncher.containsPress ? 0.98 : 1.0

        RowLayout {
          anchors.fill: parent
          anchors.margins: ScalerService.s(8)

          IconImage {
            path: "launcher/dashboard"
            rotation: mouseAreaLauncher.containsMouse ? 0 : 90
            opacity: root.animationProgress > 0.2 ? 1 : 0
          }

          CustomText {
            opacity: root.animationProgress > 0.2 ? 1 : 0
            text: lang.system.application
            scale: mouseAreaLauncher.containsMouse ? 1.05 : 1.0
            textColor: ThemeService.menuItemText(mouseAreaLauncher.containsMouse || mouseAreaLauncher.containsPress)
            isBold: mouseAreaLauncher.containsMouse
            size: "small"
          }

          Item {
            Layout.fillWidth: true
          }
        }

        MouseArea {
          id: mouseAreaLauncher
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            VisibleService.togglePanel("listLauncher");
          }
        }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: ScalerService.s(60)
      CustomRectangle {
        id: settingsButton
        implicitWidth: root.animationProgress > 0.2 ? parent.width : 0
        implicitHeight: root.animationProgress > 0.2 ? parent.height : 0
        anchors.centerIn: parent
        border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
        radius: ScalerService.s(Settings.appearance.radius3)
        color: ThemeService.menuItemBackground(mouseAreaSettings.containsMouse || mouseAreaSettings.containsPress)
        border.color: ThemeService.menuItemBorder(mouseAreaSettings.containsMouse || mouseAreaSettings.containsPress)
        scale: mouseAreaSettings.containsPress ? 0.98 : 1.0

        RowLayout {
          anchors.fill: parent
          anchors.margins: ScalerService.s(8)

          IconImage {
            path: "system/setting.png"
            rotation: mouseAreaSettings.containsMouse ? 360 : 0
            opacity: root.animationProgress > 0.3 ? 1 : 0
          }

          CustomText {
            text: lang.settings.title
            textColor: ThemeService.menuItemText(mouseAreaSettings.containsMouse || mouseAreaSettings.containsPress)
            isBold: mouseAreaSettings.containsMouse
            size: "small"
            scale: mouseAreaSettings.containsMouse ? 1.05 : 1.0
            opacity: root.animationProgress > 0.3 ? 1 : 0
          }

          Item {
            Layout.fillWidth: true
          }
        }

        MouseArea {
          id: mouseAreaSettings
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            VisibleService.togglePanel("setting");
          }
        }
      }
    }

    Item {
      Layout.fillHeight: true
    }
  }
}