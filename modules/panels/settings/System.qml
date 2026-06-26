import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons
import "./system" as SysCom

Item {
  id: root

  readonly property string compositorName: {
    if (CompositorService.isHyprland)
      return "Hyprland";
    if (CompositorService.isNiri)
      return "Niri";
    if (CompositorService.isSway)
      return "Sway";
    return "Wayland";
  }

  ScrollView {
    anchors.fill: parent
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      width: parent.parent.width - ScalerService.s(40)
      spacing: ScalerService.s(16)

      HeaderSettings {
        name: lang?.system_settings?.title || lang?.settings?.system || "System"
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(1)
        color: theme.primary.foreground
        opacity: 0.2
      }

      CustomText {
        visible: SystemSpecService.loading
        name: lang?.system_settings?.loading || "Loading device specs..."
        size: "small"
        textColor: theme.primary.dim_foreground
      }

      SysCom.DeviceSpecCard {
        sectionTitle: lang?.system_settings?.device || "Device"
        rows: [
          {
            label: lang?.system_settings?.hostname || "Hostname",
            value: SystemSpecService.hostname
          },
          {
            label: lang?.system_settings?.os || "Operating System",
            value: SystemSpecService.osName
          },
          {
            label: lang?.system_settings?.kernel || "Kernel",
            value: SystemSpecService.kernel
          },
          {
            label: lang?.system_settings?.architecture || "Architecture",
            value: SystemSpecService.architecture
          }
        ]
      }

      SysCom.DeviceSpecCard {
        sectionTitle: lang?.system_settings?.hardware || "Hardware"
        rows: [
          {
            label: lang?.system_settings?.cpu || "Processor",
            value: SystemSpecService.cpuModel
          },
          {
            label: lang?.system_settings?.cpu_cores || "CPU Cores",
            value: SystemSpecService.cpuCores
          },
          {
            label: lang?.system_settings?.memory || "Memory",
            value: SystemSpecService.memory
          },
          {
            label: lang?.system_settings?.gpu || "Graphics",
            value: SystemSpecService.gpu
          },
          {
            label: lang?.system_settings?.storage || "Storage",
            value: SystemSpecService.storage
          }
        ]
      }

      SysCom.DeviceSpecCard {
        sectionTitle: lang?.system_settings?.runtime || "Runtime"
        rows: [
          {
            label: lang?.system_settings?.uptime || "Uptime",
            value: UptimeService.uptimePretty
          },
          {
            label: lang?.system_settings?.boot_time || "Boot time",
            value: UptimeService.getBootTimeFormatted()
          },
          {
            label: lang?.system_settings?.compositor || "Compositor",
            value: root.compositorName
          },
          {
            label: lang?.system_settings?.shell || "Shell",
            value: "cartoon-shell"
          }
        ]
      }
    }
  }
}