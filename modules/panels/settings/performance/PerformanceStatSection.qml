import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.commons
import "../appearance/panel" as PanelCom
import "../../../bar/widget" as BarCom

ColumnLayout {
  id: root

  property string statName: "cpu"
  property int percent: 0
  property string title: statName === "cpu" ? "CPU" : "RAM"

  readonly property var barSettings: statName === "cpu" ? Settings.bar.cpu : Settings.bar.ram

  function usageColor(value) {
    if (value > 80)
      return theme.normal.red;
    if (value > 60)
      return theme.normal.yellow;
    return theme.normal.green;
  }

  function setActive(active) {
    if (statName === "cpu") {
      Settings.bar.cpu = {
        "style": Settings.bar.cpu.style,
        "active": active
      };
      return;
    }

    Settings.bar.ram = {
      "style": Settings.bar.ram.style,
      "active": active
    };
  }

  function setStyle(style) {
    if (statName === "cpu") {
      Settings.bar.cpu = {
        "style": style,
        "active": Settings.bar.cpu.active
      };
      return;
    }

    Settings.bar.ram = {
      "style": style,
      "active": Settings.bar.ram.active
    };
  }

  spacing: ScalerService.s(12)
  Layout.fillWidth: true

  CustomText {
    name: root.title
    isBold: true
    size: "small"
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: ScalerService.s(12)

    CustomText {
      name: statName === "cpu"
        ? (lang?.performance_settings?.show_cpu_on_bar || "Show CPU on bar")
        : (lang?.performance_settings?.show_ram_on_bar || "Show RAM on bar")
      size: "small"
      Layout.fillWidth: true
    }

    CustomToggleSwitch {
      adapter: barSettings.active
      onClicked: root.setActive(!barSettings.active)
    }
  }

  PanelCom.StyleSelectorRow {
    Layout.fillWidth: true
    title: lang?.performance_settings?.bar_style || "Bar style"
    systemName: statName
    styleModel: 8
    currentStyle: barSettings.style
    onStyleChanged: function (style) {
      root.setStyle(style);
    }
  }

  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: ScalerService.s(110)
    color: Qt.alpha(theme.primary.dim_background, 0.5)
    radius: ScalerService.s(Settings.appearance.radius2)
    border.color: theme.button.border_select
    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

    RowLayout {
      anchors.fill: parent
      anchors.margins: ScalerService.s(12)
      spacing: ScalerService.s(16)

      ColumnLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(8)

        CustomText {
          name: (lang?.performance_settings?.current_usage || "Current usage") + ": " + percent + "%"
          size: "small"
          textColor: root.usageColor(percent)
          isBold: true
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: ScalerService.s(10)
          radius: ScalerService.s(5)
          color: theme.button.background

          Rectangle {
            height: parent.height
            width: parent.width * Math.min(percent / 100, 1)
            radius: parent.radius
            color: root.usageColor(percent)

            Behavior on width {
              NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
              }
            }
          }
        }
      }

      Rectangle {
        Layout.preferredWidth: ScalerService.s(120)
        Layout.preferredHeight: ScalerService.s(48)
        radius: ScalerService.s(Settings.appearance.radius3)
        color: Qt.alpha(theme.button.background, 0.6)
        border.color: theme.button.border
        border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0

        Loader {
          anchors.centerIn: parent
          active: statName === "cpu"
          sourceComponent: BarCom.CpuStat {}
        }

        Loader {
          anchors.centerIn: parent
          active: statName === "ram"
          sourceComponent: BarCom.RamStat {}
        }
      }
    }
  }
}