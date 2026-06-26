import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.commons
import qs.components
import qs.services

Scope {
  id: root

  property var theme: ThemeService.theme
  property var lang: LanguageService.translations
  property bool shouldShowOsd: false
  property real currentBrightness: BrightnessService.brightness
  property int currentPercent: BrightnessService.brightnessPercent

  Connections {
    target: BrightnessService
    function onUpdated() {
      root.currentBrightness = BrightnessService.brightness;
      root.currentPercent = BrightnessService.brightnessPercent;
      root.shouldShowOsd = true;
      hideTimer.restart();
    }
  }

  Timer {
    id: hideTimer
    interval: 1200
    onTriggered: root.shouldShowOsd = false
  }

  function barColor() {
    const v = Math.max(0, Math.min(currentBrightness, 1));
    if (v < 0.25)
      return theme.normal.blue;
    if (v < 0.5)
      return theme.normal.cyan;
    if (v < 0.75)
      return theme.normal.yellow;
    return theme.normal.yellow;
  }

  function brightnessIcon() {
    if (currentPercent <= 0)
      return "brightness_empty";
    if (currentPercent <= 25)
      return "brightness_2";
    if (currentPercent <= 50)
      return "brightness_4";
    if (currentPercent <= 75)
      return "brightness_6";
    return "brightness_7";
  }

  LazyLoader {
    active: root.shouldShowOsd

    PanelWindow {
      anchors {
        bottom: true
      }
      margins {
        bottom: ScalerService.s(120)
      }
      exclusiveZone: 0
      implicitWidth: ScalerService.s(300)
      implicitHeight: ScalerService.s(100)
      color: "transparent"
      mask: Region {}

      Rectangle {
        anchors.fill: parent
        border.color: theme.button.border
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
        color: theme.primary.background

        ColumnLayout {
          anchors {
            fill: parent
            leftMargin: ScalerService.s(15)
            rightMargin: ScalerService.s(15)
            bottomMargin: ScalerService.s(15)
          }
          spacing: ScalerService.s(12)

          RowLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(10)

            IconText {
              name: root.brightnessIcon()
              size: "large"
              textColor: theme.normal.yellow
            }

            CustomText {
              name: currentPercent + "%"
              color: theme.primary.foreground
              size: "large"
              isBold: true
              Layout.rightMargin: ScalerService.s(4)
            }

            Item {
              Layout.fillWidth: true
              Layout.minimumWidth: ScalerService.s(16)
            }

            CustomText {
              name: lang?.brightness?.title || "Brightness"
              size: "small"
              textColor: theme.primary.dim_foreground
              Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
              Layout.leftMargin: ScalerService.s(8)
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(20)
            radius: ScalerService.s(20)
            color: theme.primary.dim_background

            Rectangle {
              anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
              }
              width: parent.width * Math.max(0, Math.min(currentBrightness, 1))
              radius: parent.radius
              color: root.barColor()

              Behavior on width {
                NumberAnimation {
                  duration: 200
                  easing.type: Easing.OutCubic
                }
              }

              Behavior on color {
                ColorAnimation {
                  duration: 100
                }
              }
            }
          }
        }
      }
    }
  }
}