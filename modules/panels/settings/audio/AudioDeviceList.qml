import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.components
import qs.services
import qs.commons

ColumnLayout {
  id: root

  property string deviceRole: "output"
  property var devices: []
  property var activeDevice: null

  readonly property bool isInput: deviceRole === "input"
  readonly property string listTitle: isInput
    ? (lang?.audio?.input_devices || "Input Devices")
    : (lang?.audio?.output_devices || "Output Devices")
  readonly property string emptyText: isInput
    ? (lang?.audio?.no_input_devices || "No input devices found")
    : (lang?.audio?.no_devices || "No output devices found")
  readonly property string itemIcon: isInput ? "mic" : "volume_up"
  readonly property string emptyIcon: isInput ? "mic_off" : "volume_off"

  spacing: ScalerService.s(8)
  Layout.fillWidth: true

  CustomText {
    name: root.listTitle
    isBold: true
    size: "small"
    Layout.fillWidth: true
  }

  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: ScalerService.s(220)
    color: Qt.alpha(theme.primary.dim_background, 0.5)
    radius: ScalerService.s(Settings.appearance.radius2)
    border.color: theme.button.border
    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
    clip: true

    ColumnLayout {
      anchors.centerIn: parent
      spacing: ScalerService.s(8)
      visible: root.devices.length === 0

      IconText {
        name: root.emptyIcon
        size: "large"
        textColor: theme.primary.dim_foreground
        Layout.alignment: Qt.AlignHCenter
      }

      CustomText {
        name: root.emptyText
        size: "small"
        textColor: theme.primary.dim_foreground
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
      }
    }

    ScrollView {
      anchors.fill: parent
      anchors.margins: ScalerService.s(8)
      clip: true
      visible: root.devices.length > 0
      ScrollBar.vertical.policy: ScrollBar.AsNeeded

      ColumnLayout {
        width: parent.parent.width - ScalerService.s(16)
        spacing: ScalerService.s(6)

        Repeater {
          model: root.devices

          delegate: Rectangle {
            required property var modelData
            required property int index

            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(52)
            radius: ScalerService.s(Settings.appearance.radius2)
            color: mouseArea.containsMouse
              ? Qt.alpha(theme.button.background_select, 0.6)
              : (isActive
                ? Qt.alpha(theme.button.background, 0.5)
                : Qt.alpha(theme.primary.dim_background, 0.35))
            border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
            border.color: isActive ? theme.button.border_select : theme.button.border

            readonly property bool isActive: {
              if (!root.activeDevice || !modelData)
                return false;
              return modelData.id === root.activeDevice.id;
            }

            RowLayout {
              anchors.fill: parent
              anchors.margins: ScalerService.s(10)
              spacing: ScalerService.s(10)

              IconText {
                name: root.itemIcon
                size: "small"
                textColor: isActive ? theme.button.text : theme.primary.dim_foreground
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(2)

                CustomText {
                  name: modelData?.description || modelData?.name || (lang?.audio?.unknown_device || "Unknown Device")
                  size: "small"
                  isBold: isActive
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                CustomText {
                  visible: isActive
                  name: lang?.audio?.default_device || "Default"
                  size: "xs"
                  textColor: theme.normal.green
                }
              }

              Rectangle {
                Layout.preferredWidth: ScalerService.s(28)
                Layout.preferredHeight: ScalerService.s(28)
                radius: ScalerService.s(14)
                color: isActive ? theme.normal.green : theme.button.background
                visible: isActive

                IconText {
                  anchors.centerIn: parent
                  name: "check"
                  size: "small"
                  textColor: theme.primary.background
                }
              }
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (!modelData)
                  return;
                if (root.isInput)
                  Pipewire.preferredDefaultAudioSource = modelData;
                else
                  Pipewire.preferredDefaultAudioSink = modelData;
              }
            }
          }
        }
      }
    }
  }
}