import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "." as Com
import qs.services
import qs.components

ColumnLayout {
  id: root
  property var wifiManager
  property real animationProgress: 0
  readonly property real reveal: (wifiManager && wifiManager.wifiList.length > 0)
      ? 1
      : animationProgress

  Rectangle {
    Layout.preferredHeight: ScalerService.s(36)
    Layout.fillWidth: true
    color: "transparent"

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: ScalerService.s(10)
      anchors.rightMargin: ScalerService.s(4)
      opacity: root.reveal > 0.3 ? 1 : 0

      CustomText {
        name: (lang?.wifi?.available_networks || "Available networks") + " (" + wifiManager.wifiList.length + ")"
        textColor: theme.primary.dim_foreground
        size: "small"
        Layout.fillWidth: true
      }

      ScanButton {
        scanning: wifiManager.isScanning
        enabled: wifiManager.wifiEnabled
        label: lang?.wifi?.scan || "Scan"
        scanningLabel: lang?.wifi?.searching || "Searching for networks..."
        onClicked: wifiManager.scanWifiNetworks(true)
      }
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    ScrollView {
      anchors.fill: parent

      ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        background: Rectangle {
          color: theme.primary.dim_background
          radius: ScalerService.s(3)
        }
        contentItem: Rectangle {
          color: theme.normal.blue
          radius: ScalerService.s(3)
        }
      }

      ListView {
        id: wifiListView
        model: wifiManager.wifiList
        spacing: ScalerService.s(6)

        delegate: Com.WifiNetworkItem {
          opacity: root.reveal > 0.5 ? 1 : 0

          SequentialAnimation on opacity {
            running: root.reveal < 1 && root.animationProgress > 0.8

            PauseAnimation {
              duration: index * 15
            }

            NumberAnimation {
              to: 1
              duration: 200
              easing.type: Easing.OutCubic
            }
          }
          width: wifiListView.width
          networkData: modelData
          wifiManager: root.wifiManager
        }
      }
    }

  }
}
