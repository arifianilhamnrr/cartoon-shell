// Status card component for Bluetooth panel
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

Rectangle {
  id: statusCard
  required property var adapter
  required property int connectedCount

  Layout.fillWidth: true
  height: ScalerService.s(82)
  radius: ScalerService.s(12)
  color: theme.primary.dim_background
  border.width: ScalerService.s(3)
  border.color: theme.normal.black

  RowLayout {
    anchors.fill: parent
    anchors.margins: ScalerService.s(14)
    spacing: ScalerService.s(12)

    ColumnLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(4)

      CustomText {
        name: adapter?.enabled ? (lang?.bluetooth?.enabled || "Bluetooth is on") : (lang?.bluetooth?.disabled || "Bluetooth is off")
        isBold: true
        textColor: adapter?.enabled ? theme.button.text : theme.primary.dim_foreground
      }

      CustomText {
        name: `${connectedCount} ` + (lang?.bluetooth?.devices_connected || "devices connected")
        size: "small"
        textColor: theme.primary.dim_foreground
        visible: adapter?.enabled || false
      }
    }

    Item {
      Layout.fillWidth: true
    }

    CustomToggleSwitch {
      adapter: statusCard.adapter?.enabled ?? false
      opacity: statusCard.adapter ? 1 : 0.5
      onClicked: {
        if (!statusCard.adapter)
          return

        statusCard.adapter.enabled = !statusCard.adapter.enabled
        if (statusCard.adapter.enabled) {
          statusCard.adapter.pairable = true
          statusCard.adapter.discoverable = true
        }
      }
    }
  }
}