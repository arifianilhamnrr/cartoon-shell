import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons
import "../../wifi" as WifiCom
import "." as NetCom

Item {
  id: root
  property real animationProgress: 1
  WifiService {
    id: wifiManager
  }

  ScrollView {
    anchors.fill: parent
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      width: parent.parent.width - ScalerService.s(40)
      spacing: ScalerService.s(16)

      HeaderSettings {
        name: lang?.wifi?.title || "WiFi"
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(1)
        color: theme.primary.foreground
        opacity: 0.2
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(12)

        CustomText {
          name: "Show WiFi on bar"
          size: "small"
          Layout.fillWidth: true
        }

        CustomToggleSwitch {
          adapter: Settings.bar.wifi.active
          onClicked: {
            Settings.bar.wifi = {
              "style": Settings.bar.wifi.style,
              "active": !Settings.bar.wifi.active
            };
          }
        }
      }

      WifiCom.WifiSpeedCard {
        Layout.fillWidth: true
        wifiManager: wifiManager
        animationProgress: root.animationProgress
      }

      WifiCom.WifiStatus {
        Layout.fillWidth: true
        wifiManager: wifiManager
        animationProgress: root.animationProgress
      }

      NetCom.WifiConnectionDetails {
        wifiManager: wifiManager
      }

      NetCom.WifiIpSettings {
        wifiManager: wifiManager
      }

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(360)

        WifiCom.WifiNetworkList {
          anchors.fill: parent
          wifiManager: wifiManager
          visible: wifiManager.wifiEnabled
          animationProgress: root.animationProgress
        }

        WifiCom.WifiEmptyState {
          anchors.fill: parent
          visible: !wifiManager.wifiEnabled
        }
      }
    }
  }
}