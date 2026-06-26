import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.components
import qs.commons
import qs.services

Item {
  id: root

  property bool vertical: false
  property int percent: 0
  property bool charging: false
  property bool ready: false

  readonly property string percentLabel: ready ? percent + "%" : "…"
  readonly property string iconName: {
    if (!ready)
      return "battery_0_bar"

    if (charging) {
      if (percent >= 85)
        return "battery_charging_full"
      if (percent >= 55)
        return "battery_charging_80"
      if (percent >= 30)
        return "battery_charging_50"
      return "battery_charging_20"
    }

    if (percent <= 15)
      return "battery_alert"
    if (percent <= 30)
      return "battery_2_bar"
    if (percent <= 50)
      return "battery_4_bar"
    if (percent <= 75)
      return "battery_5_bar"
    return "battery_full"
  }
  readonly property color iconColor: {
    if (!ready)
      return theme.primary.dim_foreground
    if (charging)
      return theme.normal.green
    if (percent <= 20)
      return theme.normal.red
    return theme.button.text
  }

  width: contentLoader.item ? contentLoader.item.implicitWidth : 0
  height: contentLoader.item ? contentLoader.item.implicitHeight : 0

  function refresh() {
    const dev = UPower.displayDevice
    if (!dev || !dev.ready)
      return

    ready = true
    percent = Math.round(dev.percentage * 100)
    charging = dev.state === UPowerDeviceState.Charging
  }

  Component.onCompleted: refresh()

  Timer {
    interval: 500
    running: !root.ready
    repeat: true
    onTriggered: root.refresh()
  }

  Connections {
    target: UPower.displayDevice
    enabled: UPower.displayDevice && UPower.displayDevice.ready
    function onPercentageChanged() {
      root.refresh()
    }
    function onStateChanged() {
      root.refresh()
    }
  }

  Loader {
    id: contentLoader
    sourceComponent: root.vertical ? verticalLayout : horizontalLayout
  }

  Component {
    id: horizontalLayout

    RowLayout {
      spacing: ScalerService.s(4)

      IconText {
        name: root.iconName
        size: "small"
        textColor: root.iconColor
      }

      CustomText {
        name: root.percentLabel
        isBold: true
        size: "xs"
        textColor: theme.button.text
      }
    }
  }

  Component {
    id: verticalLayout

    ColumnLayout {
      spacing: ScalerService.s(2)

      IconText {
        name: root.iconName
        size: "xs"
        textColor: root.iconColor
        Layout.alignment: Qt.AlignHCenter
      }

      CustomText {
        name: root.percentLabel
        isBold: true
        size: "2xs"
        textColor: theme.button.text
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }
}