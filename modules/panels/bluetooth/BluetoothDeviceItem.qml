// Device item component for Bluetooth panel
import QtQuick
import qs.services
import qs.components
import qs.commons
import QtQuick.Layouts

Rectangle {
  id: delegateRoot
  required property var modelData
  required property int index
  required property var adapter

  signal pairError(string message)

  width: ListView.view.width
  height: ScalerService.s(70)
  radius: ScalerService.s(10)
  color: deviceMouseArea.containsMouse
    ? Qt.alpha(theme.button.background_select, 0.5)
    : (modelData?.connected
      ? Qt.alpha(theme.button.background, 0.5)
      : Qt.alpha(theme.primary.dim_background, 0.5))
  border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
  border.color: modelData?.connected ? theme.button.border : theme.normal.black

  scale: deviceMouseArea.containsPress ? 0.98 : 1.0
  Behavior on scale {
    NumberAnimation {
      duration: 100
    }
  }
  Behavior on color {
    ColorAnimation {
      duration: 200
    }
  }

  Rectangle {
    id: pairingIndicator
    visible: modelData?.pairing || false
    anchors.centerIn: parent
    width: parent.width - ScalerService.s(20)
    height: parent.height - ScalerService.s(20)
    radius: ScalerService.s(8)
    color: Qt.alpha(theme.button.background_select, 0.45)
    opacity: 0.9

    CustomText {
      anchors.centerIn: parent
      name: lang?.bluetooth?.pairing || "Pairing..."
      size: "xs"
      isBold: true
      textColor: theme.button.text
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: ScalerService.s(12)
    spacing: ScalerService.s(12)
    opacity: modelData?.pairing ? 0.7 : 1.0

    Rectangle {
      width: ScalerService.s(46)
      height: ScalerService.s(46)
      radius: ScalerService.s(23)
      color: modelData?.connected ? theme.normal.green : theme.button.background
      border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
      border.color: theme.button.border

      IconText {
        anchors.centerIn: parent
        name: getDeviceIconName(modelData?.icon || "")
        size: "small"
        textColor: modelData?.connected ? theme.primary.background : theme.button.text
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(2)

      CustomText {
        name: modelData?.name || lang?.bluetooth?.no_devices || "Unknown Device"
        size: "small"
        isBold: true
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      CustomText {
        name: {
          if (modelData?.connecting)
            return lang?.bluetooth?.connecting || "Connecting..."
          if (modelData?.connected)
            return lang?.bluetooth?.connected || "Connected"
          if (modelData?.paired)
            return lang?.bluetooth?.paired || "Paired"
          return lang?.bluetooth?.not_connected || "Not connected"
        }
        size: "xs"
        textColor: {
          if (modelData?.connecting)
            return theme.button.text
          if (modelData?.connected)
            return theme.normal.green
          if (modelData?.paired)
            return theme.button.text
          return theme.primary.dim_foreground
        }
      }
    }

    RowLayout {
      spacing: ScalerService.s(8)

      Rectangle {
        width: ScalerService.s(32)
        height: ScalerService.s(32)
        radius: ScalerService.s(8)
        color: modelData?.connected ? theme.normal.green : theme.button.background
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
        border.color: theme.button.border
        opacity: (modelData?.paired || modelData?.connecting) ? 1 : 0.5
        enabled: !modelData?.pairing

        IconText {
          anchors.centerIn: parent
          name: modelData?.connecting ? "sync" : modelData?.connected ? "link_off" : "link"
          size: "xs"
          textColor: modelData?.connected ? theme.primary.background : theme.button.text

          RotationAnimation on rotation {
            running: modelData?.connecting || false
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
          }
        }

        MouseArea {
          id: connectMouseArea
          anchors.fill: parent
          enabled: parent.enabled
          hoverEnabled: true
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: {
            if (modelData?.connected) {
              modelData.disconnect()
            } else if (modelData?.paired && !modelData?.connecting) {
              modelData.connect()
            }
          }
        }
      }

      Rectangle {
        width: ScalerService.s(32)
        height: ScalerService.s(32)
        radius: ScalerService.s(8)
        color: theme.button.background
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
        border.color: theme.button.border
        opacity: modelData?.pairing ? 0.8 : 1
        enabled: !modelData?.pairing

        IconText {
          anchors.centerIn: parent
          name: modelData?.pairing ? "hourglass_top" : modelData?.paired ? "delete" : "group_add"
          size: "xs"
          textColor: theme.button.text
        }

        MouseArea {
          id: pairMouseArea
          anchors.fill: parent
          enabled: parent.enabled && !modelData?.connected
          hoverEnabled: true
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: {
            if (modelData?.paired) {
              modelData.forget()
            } else {
              if (adapter) {
                adapter.pairable = true
                adapter.discoverable = true
              }

              try {
                modelData.pair()
              } catch (error) {
                delegateRoot.pairError(lang?.bluetooth?.pair_error || "Unable to pair with device")
              }
            }
          }
        }
      }
    }
  }

  MouseArea {
    id: deviceMouseArea
    anchors.fill: parent
    hoverEnabled: true
    propagateComposedEvents: true
    onPressed: function (mouse) {
      mouse.accepted = false
    }
  }

  function getDeviceIconName(iconName) {
    if (iconName.includes("audio"))
      return "headphones"
    if (iconName.includes("phone"))
      return "smartphone"
    if (iconName.includes("computer"))
      return "computer"
    if (iconName.includes("input-mouse"))
      return "mouse"
    if (iconName.includes("input-keyboard"))
      return "keyboard"
    if (iconName.includes("camera"))
      return "photo_camera"
    if (iconName.includes("printer"))
      return "print"
    return "devices"
  }
}