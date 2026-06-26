import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Bluetooth
import qs.components
import qs.commons
import qs.services

RowLayout {
  id: root

  property int style: Settings.bar.bluetooth.style
  property var adapter: Bluetooth.defaultAdapter

  spacing: ScalerService.s(2)

  readonly property bool bluetoothEnabled: adapter?.enabled ?? false
  readonly property string iconName: bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
  readonly property color iconColor: bluetoothEnabled
    ? theme.button.text
    : theme.primary.dim_foreground

  Item {
    visible: root.style === 1
    width: ScalerService.s(32)
    height: width

    Image {
      anchors.fill: parent
      anchors.margins: ScalerService.s(2)
      source: Directories.assetsPath + "/settings/bluetooth.png"
      fillMode: Image.PreserveAspectFit
      smooth: true
      mipmap: true

      layer.enabled: true
      layer.effect: ColorOverlay {
        color: root.iconColor
      }
    }
  }

  IconText {
    visible: root.style === 2
    name: root.iconName
    textColor: root.iconColor
  }
}