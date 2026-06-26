import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import "." as Com

Item {
  RowLayout {
    anchors.fill: parent
    spacing: ScalerService.s(4)

    // CPU Container
    Com.StatContainer {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: Settings.bar.cpu.active
      panelName: "cpu"

      Com.CpuStat {
        anchors.centerIn: parent
      }
    }
    Com.StatContainer {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: Settings.bar.ram.active
      panelName: "ram"

      Com.RamStat {
        anchors.centerIn: parent
      }
    }
  }

}
