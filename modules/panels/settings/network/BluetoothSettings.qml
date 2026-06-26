import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.services
import qs.components
import qs.commons
import "../../bluetooth" as BtCom

Item {
  id: root
  property real animationProgress: 1
  property var adapter: Bluetooth.defaultAdapter
  property string pairErrorMessage: ""

  property int connectedCount: 0

  function refreshConnectedCount() {
    var values = Bluetooth.devices ? Bluetooth.devices.values : null;
    if (!values) {
      root.connectedCount = 0;
      return;
    }

    var count = 0;
    for (var i = 0; i < values.length; i++) {
      if (values[i].connected)
        count++;
    }
    root.connectedCount = count;
  }

  Timer {
    id: errorMessageTimer
    interval: 5000
    onTriggered: pairErrorMessage = ""
  }

  ScrollView {
    anchors.fill: parent
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      width: parent.parent.width - ScalerService.s(40)
      spacing: ScalerService.s(16)

      HeaderSettings {
        name: lang?.bluetooth?.title || "Bluetooth"
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
          name: "Show Bluetooth on bar"
          size: "small"
          Layout.fillWidth: true
        }

        CustomToggleSwitch {
          adapter: Settings.bar.bluetooth.active
          onClicked: {
            Settings.bar.bluetooth = {
              "style": Settings.bar.bluetooth.style,
              "active": !Settings.bar.bluetooth.active
            };
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: pairErrorMessage ? ScalerService.s(40) : 0
        radius: ScalerService.s(8)
        color: theme.normal.red
        visible: pairErrorMessage !== ""
        clip: true

        Text {
          anchors.centerIn: parent
          text: pairErrorMessage
          color: theme.primary.foreground
          font.pixelSize: ScalerService.s(12)
          font.family: "ComicShannsMono Nerd Font"
        }
      }

      BtCom.BluetoothStatusCard {
        Layout.fillWidth: true
        adapter: root.adapter
        connectedCount: root.connectedCount
      }

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(420)

        BtCom.BluetoothDeviceList {
          anchors.fill: parent
          adapter: root.adapter
          connectedCount: root.connectedCount
          onPairError: function (message) {
            pairErrorMessage = message;
            errorMessageTimer.restart();
          }
        }
      }
    }
  }

  Connections {
    target: adapter
    enabled: !!adapter
    function onEnabledChanged() {
      if (adapter?.enabled) {
        adapter.pairable = true;
        adapter.discoverable = false;
      }
    }
  }

  Connections {
    target: Bluetooth.devices
    enabled: !!Bluetooth.devices
    function onValuesChanged() {
      root.refreshConnectedCount();
    }
  }

  Component.onCompleted: {
    root.refreshConnectedCount();
    if (adapter && adapter.enabled) {
      adapter.pairable = true;
    }
  }
}