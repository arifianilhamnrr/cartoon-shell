import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.components
import "./network" as Com
import "./" as Bar

Item {
  id: root
  property int currentTab: 0
  property real animationProgress: 0

  SequentialAnimation on animationProgress {
    running: true
    NumberAnimation {
      from: 0
      to: 1
      duration: 500
      easing.type: Easing.Linear
    }
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: ScalerService.s(10)

    Bar.TopNavigationBar {
      animationProgress: root.animationProgress
      indexCategoegory: 2
      onCurrentTab: function (index) {
        root.currentTab = index;
      }
    }

    StackLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      currentIndex: root.currentTab

      Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        active: root.currentTab === 0
        source: "./network/WifiSettings.qml"
        onLoaded: {
          item.visible = Qt.binding(function () {
            return root.currentTab === 0;
          });
        }
      }

      Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        active: root.currentTab === 1
        source: "./network/BluetoothSettings.qml"
        onLoaded: {
          item.visible = Qt.binding(function () {
            return root.currentTab === 1;
          });
        }
      }
    }
  }
}