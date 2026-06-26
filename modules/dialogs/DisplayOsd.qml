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
  property string currentMode: DisplayService.currentMode
  property string currentLabel: DisplayService.currentLabel
  property string currentIcon: DisplayService.currentIcon

  Connections {
    target: DisplayService
    function onUpdated() {
      root.currentMode = DisplayService.currentMode;
      root.currentLabel = DisplayService.currentLabel;
      root.currentIcon = DisplayService.currentIcon;
      root.shouldShowOsd = true;
      hideTimer.restart();
    }
  }

  Timer {
    id: hideTimer
    interval: 1400
    onTriggered: root.shouldShowOsd = false
  }

  function modeColor(modeId) {
    if (modeId !== currentMode)
      return theme.primary.dim_background;

    switch (modeId) {
      case "laptop":
      return theme.normal.blue;
      case "extend":
      return theme.normal.green;
      case "mirror":
      return theme.normal.yellow;
      default:
      return theme.button.background_select;
    }
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
      implicitWidth: ScalerService.s(320)
      implicitHeight: ScalerService.s(108)
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
            topMargin: ScalerService.s(12)
          }
          spacing: ScalerService.s(12)

          RowLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(10)

            IconText {
              name: currentIcon
              size: "large"
              textColor: theme.normal.cyan
            }

            CustomText {
              name: currentLabel
              color: theme.primary.foreground
              size: "large"
              isBold: true
              Layout.fillWidth: true
              elide: Text.ElideRight
            }

            CustomText {
              name: lang?.display?.title || "Display"
              size: "small"
              textColor: theme.primary.dim_foreground
              Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(6)

            Repeater {
              model: DisplayService.modes

              delegate: Rectangle {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(10)
                radius: ScalerService.s(5)
                color: root.modeColor(modelData.id)
                opacity: modelData.id === root.currentMode ? 1 : 0.45

                Behavior on color {
                  ColorAnimation {
                    duration: 180
                  }
                }

                Behavior on opacity {
                  NumberAnimation {
                    duration: 180
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}