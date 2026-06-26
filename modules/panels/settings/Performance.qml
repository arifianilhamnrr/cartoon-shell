import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons
import qs.services.cpu
import qs.services.ram
import "./performance" as PerfCom

Item {
  id: root

  ScrollView {
    anchors.fill: parent
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      width: parent.parent.width - ScalerService.s(40)
      spacing: ScalerService.s(16)

      HeaderSettings {
        name: lang?.performance_settings?.title || lang?.settings?.performance || "Performance"
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(1)
        color: theme.primary.foreground
        opacity: 0.2
      }

      PerfCom.PerformanceStatSection {
        statName: "cpu"
        title: lang?.performance_settings?.cpu || "CPU"
        percent: Math.round(CpuSimpleService.cpuPercent)
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(1)
        color: theme.primary.foreground
        opacity: 0.2
      }

      PerfCom.PerformanceStatSection {
        statName: "ram"
        title: lang?.performance_settings?.ram || "RAM"
        percent: RamSimpleService.ramPercent
      }
    }
  }
}