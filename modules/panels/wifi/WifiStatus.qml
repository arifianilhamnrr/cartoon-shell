import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

Rectangle {
  id: root
  property var wifiManager

  implicitHeight: ScalerService.s(80)
  color: Qt.alpha(theme.primary.dim_background,0.6)
  radius: ScalerService.s(Settings.appearance.radius2)
  border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
  border.color: theme.normal.black
  property real animationProgress: 0

  RowLayout {
    anchors.fill: parent
    anchors.margins: ScalerService.s(12)

    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.maximumWidth: parent.width - ScalerService.s(56)
      spacing: ScalerService.s(2)

      CustomText {
        Layout.fillWidth: true
        name: wifiManager.wifiEnabled ? (lang?.wifi?.enabled || "WiFi is on") : (lang?.wifi?.disabled || "WiFi is off")
        isBold: true
        textColor: wifiManager.wifiEnabled ? theme.button.text : theme.normal.red
        elide: Text.ElideRight
        opacity: root.animationProgress > 0.4 ? 1 : 0
      }
      CustomText {
        Layout.fillWidth: true
        name: {
          if (!wifiManager.wifiEnabled)
            return lang?.wifi?.disabled || "WiFi is off";
          if (wifiManager.connectedWifi === "Not connected")
            return lang?.wifi?.not_connected || "Not connected";
          var detail = wifiManager.connectedWifi;
          if (wifiManager.connectionDetails && wifiManager.connectionDetails.connected) {
            if (wifiManager.connectionDetails.signalText && wifiManager.connectionDetails.signalText !== "-")
              detail += " • " + wifiManager.connectionDetails.signalText;
          }
          return detail;
        }
        size: "small"
        textColor: theme.primary.dim_foreground
        elide: Text.ElideRight
        opacity: root.animationProgress > 0.5 ? 1 : 0
      }
    }

    CustomToggleSwitch {
      Layout.alignment: Qt.AlignVCenter
      opacity: root.animationProgress > 0.6 ? 1 : 0
      adapter: wifiManager.wifiEnabled
      onClicked:{
        wifiManager.toggleWifi();
      }
    }
  }
}
