import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

Rectangle {
  id: root
  required property var wifiManager

  Layout.fillWidth: true
  implicitHeight: detailColumn.implicitHeight + ScalerService.s(24)
  radius: ScalerService.s(Settings.appearance.radius2)
  color: Qt.alpha(theme.primary.dim_background, 0.6)
  border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
  border.color: theme.normal.black
  visible: wifiManager.wifiEnabled && wifiManager.connectionDetails.connected

  ColumnLayout {
    id: detailColumn
    anchors.fill: parent
    anchors.margins: ScalerService.s(12)
    spacing: ScalerService.s(8)

    CustomText {
      name: lang?.wifi?.connection_details || "Connection Details"
      isBold: true
      size: "small"
    }

    GridLayout {
      Layout.fillWidth: true
      columns: 2
      columnSpacing: ScalerService.s(12)
      rowSpacing: ScalerService.s(6)

      Repeater {
        model: [
          { label: lang?.wifi?.network || "Network", value: wifiManager.connectionDetails.ssid || "-" },
          { label: lang?.wifi?.device || "Device", value: wifiManager.connectionDetails.device || "-" },
          { label: lang?.wifi?.ip_mode || "IP Mode", value: wifiManager.connectionDetails.ipv4Method === "manual" ? (lang?.wifi?.ip_static || "Static IP") : (lang?.wifi?.ip_dhcp || "DHCP") },
          { label: lang?.wifi?.ip_address || "IP Address", value: wifiManager.connectionDetails.ip || "-" },
          { label: lang?.wifi?.gateway || "Gateway", value: wifiManager.connectionDetails.gateway || "-" },
          { label: lang?.wifi?.dns_servers || "DNS Servers", value: wifiManager.connectionDetails.dnsText || "-" },
          { label: lang?.wifi?.signal || "Signal", value: wifiManager.connectionDetails.signalText || "-" },
          { label: lang?.wifi?.frequency || "Frequency", value: wifiManager.connectionDetails.frequency || "-" },
          { label: lang?.wifi?.channel || "Channel", value: wifiManager.connectionDetails.channel || "-" },
          { label: lang?.wifi?.security || "Security", value: wifiManager.connectionDetails.security || "-" },
          { label: lang?.wifi?.link_speed || "Link Speed", value: wifiManager.connectionDetails.rate || "-" },
          { label: lang?.wifi?.bssid || "BSSID", value: wifiManager.connectionDetails.bssid || "-" },
          { label: lang?.wifi?.mac_address || "MAC Address", value: wifiManager.connectionDetails.mac || "-" }
        ]

        delegate: RowLayout {
          Layout.fillWidth: true
          spacing: ScalerService.s(8)

          CustomText {
            name: modelData.label
            size: "xs"
            textColor: theme.primary.dim_foreground
            Layout.preferredWidth: ScalerService.s(110)
          }

          CustomText {
            name: modelData.value
            size: "xs"
            isBold: true
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
        }
      }
    }
  }
}