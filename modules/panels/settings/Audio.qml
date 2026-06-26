import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.services
import qs.components
import qs.commons
import "../mixer" as MixerCom
import "./appearance/panel" as PanelCom
import "./audio" as AudioCom

Item {
  id: root

  property var sinks: []
  property var sources: []
  readonly property var defaultSink: Pipewire.defaultAudioSink
  readonly property var defaultSource: Pipewire.defaultAudioSource

  function sortDevices(list) {
    list.sort(function (a, b) {
      var an = (a.description || a.name || "").toLowerCase();
      var bn = (b.description || b.name || "").toLowerCase();
      return an.localeCompare(bn);
    });
    return list;
  }

  function refreshDevices() {
    var sinkList = [];
    var sourceList = [];
    var values = Pipewire.nodes ? Pipewire.nodes.values : null;

    if (values) {
      for (var i = 0; i < values.length; i++) {
        var node = values[i];
        if (node.isStream)
          continue;
        if (node.isSink) {
          sinkList.push(node);
        } else if (node.audio) {
          sourceList.push(node);
        }
      }
    }

    root.sinks = sortDevices(sinkList);
    root.sources = sortDevices(sourceList);
  }

  PwObjectTracker {
    objects: [root.defaultSink, root.defaultSource]
  }

  Connections {
    target: Pipewire.nodes
    function onValuesChanged() {
      root.refreshDevices();
    }
  }

  Component.onCompleted: root.refreshDevices();

  ScrollView {
    anchors.fill: parent
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      width: parent.parent.width - ScalerService.s(40)
      spacing: ScalerService.s(16)

      HeaderSettings {
        name: lang?.audio?.title || lang?.settings?.audio || "Audio"
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
          name: lang?.audio?.show_on_bar || "Show volume on bar"
          size: "small"
          Layout.fillWidth: true
        }

        CustomToggleSwitch {
          adapter: Settings.bar.volume.active
          onClicked: {
            Settings.bar.volume = {
              "style": Settings.bar.volume.style,
              "active": !Settings.bar.volume.active
            };
          }
        }
      }

      PanelCom.StyleSelectorRow {
        Layout.fillWidth: true
        title: lang?.audio?.bar_style || "Bar style"
        systemName: "volume"
        styleModel: 2
        currentStyle: Settings.bar.volume.style
        onStyleChanged: function (style) {
          Settings.bar.volume = {
            "style": style,
            "active": Settings.bar.volume.active
          };
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(1)
        color: theme.primary.foreground
        opacity: 0.2
      }

      CustomText {
        name: lang?.mixer?.output_device || "Output Device"
        isBold: true
        size: "small"
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(120)
        color: Qt.alpha(theme.primary.dim_background, 0.5)
        radius: ScalerService.s(Settings.appearance.radius2)
        border.color: theme.button.border_select
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: ScalerService.s(12)
          spacing: ScalerService.s(8)

          CustomText {
            name: defaultSink
              ? (defaultSink.description || defaultSink.name || (lang?.audio?.unknown_device || "Unknown Device"))
              : (lang?.audio?.no_devices || "No output devices found")
            size: "small"
            textColor: theme.button.text
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          MixerCom.MixerEntry {
            node: defaultSink
            Layout.fillWidth: true
            showIcon: false
            showMediaName: false
            visible: !!defaultSink
          }
        }
      }

      AudioCom.AudioDeviceList {
        deviceRole: "output"
        devices: root.sinks
        activeDevice: root.defaultSink
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(1)
        color: theme.primary.foreground
        opacity: 0.2
      }

      CustomText {
        name: lang?.audio?.input_device || "Input Device"
        isBold: true
        size: "small"
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(120)
        color: Qt.alpha(theme.primary.dim_background, 0.5)
        radius: ScalerService.s(Settings.appearance.radius2)
        border.color: theme.button.border_select
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: ScalerService.s(12)
          spacing: ScalerService.s(8)

          CustomText {
            name: defaultSource
              ? (defaultSource.description || defaultSource.name || (lang?.audio?.unknown_device || "Unknown Device"))
              : (lang?.audio?.no_input_devices || "No input devices found")
            size: "small"
            textColor: theme.button.text
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          MixerCom.MixerEntry {
            node: defaultSource
            Layout.fillWidth: true
            showIcon: false
            showMediaName: false
            visible: !!defaultSource
          }
        }
      }

      AudioCom.AudioDeviceList {
        deviceRole: "input"
        devices: root.sources
        activeDevice: root.defaultSource
      }
    }
  }
}