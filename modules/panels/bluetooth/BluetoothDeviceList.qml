// Device list component for Bluetooth panel
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.services
import qs.components
import "." as Components

Rectangle {
  id: deviceListRoot
  required property var adapter
  required property int connectedCount

  signal pairError(string message)

  property bool isScanning: false
  property int deviceCount: 0

  function refreshDeviceCount() {
    var values = Bluetooth.devices ? Bluetooth.devices.values : null;
    deviceListRoot.deviceCount = values ? values.length : 0;
  }

  Layout.fillWidth: true
  Layout.fillHeight: true
  radius: ScalerService.s(12)
  color: theme.primary.dim_background
  clip: true
  visible: adapter?.enabled || false

  function startScan() {
    if (!adapter || !adapter.enabled)
      return;
    deviceListRoot.isScanning = true;
    adapter.discovering = true;
    scanTimer.restart();
  }

  function stopScan() {
    if (adapter?.discovering)
      adapter.discovering = false;
    deviceListRoot.isScanning = false;
  }

  Timer {
    id: scanTimer
    interval: 10000
    onTriggered: deviceListRoot.stopScan()
  }

  Connections {
    target: adapter
    enabled: !!adapter
    function onDiscoveringChanged() {
      if (!adapter.discovering && deviceListRoot.isScanning)
        deviceListRoot.isScanning = false;
    }
  }

  Connections {
    target: Bluetooth.devices
    enabled: !!Bluetooth.devices
    function onValuesChanged() {
      deviceListRoot.refreshDeviceCount();
    }
  }

  Component.onCompleted: deviceListRoot.refreshDeviceCount()

  ColumnLayout {
    anchors.fill: parent

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: ScalerService.s(36)
      color: "transparent"

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: ScalerService.s(10)
        anchors.rightMargin: ScalerService.s(4)

        CustomText {
          name: (lang?.bluetooth?.devices || "Devices") + " (" + deviceListRoot.deviceCount + ")"
          textColor: theme.primary.dim_foreground
          size: "small"
          Layout.fillWidth: true
        }

        ScanButton {
          scanning: deviceListRoot.isScanning
          enabled: adapter?.enabled || false
          label: lang?.bluetooth?.scan || "Scan"
          scanningLabel: lang?.bluetooth?.searching || "Searching for devices..."
          onClicked: deviceListRoot.startScan()
        }
      }
    }

    ScrollView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

      ListView {
        id: deviceList
        model: Bluetooth.devices
        spacing: ScalerService.s(4)
        boundsBehavior: Flickable.StopAtBounds

        delegate: Components.BluetoothDeviceItem {
          adapter: deviceListRoot.adapter
          onPairError: function (message) {
            deviceListRoot.pairError(message);
          }
        }

        // Empty state message
        Text {
          anchors.centerIn: parent
          text: {
            if (!adapter?.enabled)
            return lang?.bluetooth?.disabled || "Bluetooth is off";
            if (adapter?.discovering && deviceListRoot.deviceCount === 0)
            return "🔍 " + (lang?.bluetooth?.searching || "Searching for devices...");
            if (deviceListRoot.deviceCount === 0)
            return lang?.bluetooth?.no_devices || "No devices found";
            return "";
          }
          color: theme.primary.dim_foreground
          font.pixelSize: ScalerService.s(13)
          visible: text !== ""
        }
      }
    }
  }
}
