import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import Quickshell.Io
import qs.components
import qs.commons

Item {
  id: ramTaskManager

  property real animationProgress: 0
  property int updateInterval: 3000

  property var processList: []
  property string lastUpdateTime: Qt.formatTime(new Date(), "hh:mm:ss")

  Timer {
    id: refreshTimer
    interval: updateInterval
    running: true
    repeat: true
    onTriggered: processFetcher.running = true
  }

  Timer {
    id: clockTimer
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      ramTaskManager.lastUpdateTime = Qt.formatTime(new Date(), "hh:mm:ss");
    }
  }

  Process {
    id: processFetcher
    running: false
    stdout: StdioCollector {
      id: processOutput
    }

    command: [Qt.resolvedUrl("../../../scripts/task-manager-ram.py")]

    onExited: {
      try {
        var txt = processOutput.text ? processOutput.text.trim() : "";
        if (txt !== "") {
          const data = JSON.parse(txt);
          ramTaskManager.processList = data;
        }
      } catch (e) {}
    }
  }

  Item {
    anchors.fill: parent
    ColumnLayout {
      anchors.fill: parent
      anchors.margins: ScalerService.s(16)
      spacing: ScalerService.s(12)

      Item {
        Layout.fillWidth: true
        height: ScalerService.s(50)
        RowLayout {
          anchors.fill: parent
          anchors.margins: ScalerService.s(12)

          CustomText {
            name: lang?.ram?.title || "RAM Manager"
            size: "large"
            isBold: true
          }

          Item {
            Layout.fillWidth: true
          }

          ColumnLayout {
            spacing: ScalerService.s(2)
            CustomText {
              name: lang?.ram?.header_bar?.last_update || "Last update"
              size: "small"
            }
            CustomText {
              name: lastUpdateTime
              size: "small"
              isBold: true
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(32)
        color: Qt.alpha(theme.button.background, 0.5)

        radius: ScalerService.s(6)

        RowLayout {
          anchors.fill: parent
          anchors.margins: ScalerService.s(8)
          spacing: ScalerService.s(8)

          CustomText {
            name: lang?.ram?.headers?.pid || "PID"
            size: "small"
            isBold: true
            textColor: theme.button.text
            Layout.preferredWidth: ScalerService.s(70)
          }
          CustomText {
            name: lang?.ram?.headers?.name || "Name"
            size: "small"
            isBold: true
            textColor: theme.button.text
            Layout.fillWidth: true
          }
          CustomText {
            name: lang?.ram?.headers?.ram_percent || "RAM %"
            size: "small"
            isBold: true
            textColor: theme.button.text
            Layout.preferredWidth: ScalerService.s(80)
            horizontalAlignment: Text.AlignRight
          }
          CustomText {
            name: lang?.ram?.headers?.memory || "Memory"
            size: "small"
            isBold: true
            textColor: theme.button.text
            Layout.preferredWidth: ScalerService.s(100)
            horizontalAlignment: Text.AlignRight
          }
        }
      }

      Flickable {
        id: processFlick
        Layout.fillWidth: true
        Layout.fillHeight: true
        opacity: root.animationProgress > 0.3 ? 1 : 0

        Behavior on opacity {
          NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
          }
        }

        clip: true
        contentWidth: width
        contentHeight: processColumn.height

        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: processColumn
          width: processFlick.width
          spacing: ScalerService.s(2)

          Repeater {
            model: ramTaskManager.processList

            delegate: Rectangle {
              width: processFlick.width
              height: ScalerService.s(50)

              color: index % 2 === 0
              ? Qt.alpha(theme.primary.background, 0.5)
              : Qt.alpha(theme.primary.dim_background, 0.5)

              radius: ScalerService.s(6)
              border.color: Qt.lighter(color, 1.1)
              border.width: ScalerService.s(1)

              RowLayout {
                anchors.fill: parent
                anchors.margins: ScalerService.s(10)
                spacing: ScalerService.s(10)

                CustomText {
                  name: modelData.pid
                  size: "small"
                  textColor: theme.button.text
                  Layout.preferredWidth: ScalerService.s(70)
                }

                CustomText {
                  name: modelData.name
                  size: "small"
                  textColor: theme.primary.foreground
                  Layout.fillWidth: true
                }

                CustomText {
                  name: modelData.percent.toFixed(1)
                  size: "small"
                  textColor: getPercentageColor(modelData.percent)
                  Layout.preferredWidth: ScalerService.s(80)
                  horizontalAlignment: Text.AlignRight
                }

                CustomText {
                  name: modelData.rss_mb.toFixed(1) + " MB"
                  size: "small"
                  textColor: theme.primary.foreground
                  Layout.preferredWidth: ScalerService.s(100)
                  horizontalAlignment: Text.AlignRight
                }
              }

              Rectangle {
                anchors {
                  left: parent.left
                  right: parent.right
                  bottom: parent.bottom
                  margins: ScalerService.s(6)
                }

                height: ScalerService.s(3)
                radius: ScalerService.s(1.5)
                color: theme.primary.dim_background

                Rectangle {
                  width: parent.width * Math.min(modelData.percent / 30, 1)
                  height: parent.height
                  radius: ScalerService.s(1.5)
                  color: getPercentageColor(modelData.percent)

                  Behavior on width {
                    NumberAnimation {
                      duration: 250
                      easing.type: Easing.OutCubic
                    }
                  }
                }
              }
            }
          }
        }

        ScrollBar.vertical: ScrollBar {
          policy: ScrollBar.AsNeeded
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(60)
        color: theme.button.background
        radius: ScalerService.s(8)
        RowLayout {
          anchors.fill: parent
          anchors.margins: ScalerService.s(10)

          ColumnLayout {
            spacing: ScalerService.s(2)
            CustomText {
              name: lang?.ram?.footer?.process_count_label || "Processes"
              size: "small"
              textColor: theme.primary.dim_foreground
            }
            CustomText {
              name: processList.length
              size: "small"
              textColor: theme.button.text
              isBold: true
            }
          }

          Item {
            Layout.fillWidth: true
          }

          ColumnLayout {
            spacing: ScalerService.s(2)
            CustomText {
              name: lang?.ram?.footer?.total_ram_label || "Total RAM"
              size: "small"
              textColor: theme.primary.dim_foreground
            }
            CustomText {
              name: calculateTotalRAM().toFixed(1) + " MB"
              size: "small"
              textColor: theme.button.text
              isBold: true
            }
          }

          Item {
            Layout.preferredWidth: ScalerService.s(20)
          }

          ColumnLayout {
            spacing: ScalerService.s(2)
            CustomText {
              name: lang?.ram?.footer?.memory_distribution_label || "Top consumer"
              size: "small"
              textColor: theme.primary.dim_foreground
            }
            CustomText {
              name: getMemoryDistribution()
              size: "small"
              textColor: theme.button.text
              isBold: true
            }
          }
        }
      }
    }
  }

  function calculateTotalRAM() {
    var total = 0;
    for (var i = 0; i < processList.length; i++) {
      total += processList[i].rss_mb;
    }
    return total;
  }

  function getPercentageColor(percent) {
    if (percent > 90)
    return theme.normal.red;
    if (percent > 70)
    return theme.normal.yellow;
    if (percent > 50)
    return theme.normal.green;
    return theme.normal.cyan;
  }

  function getMemoryDistribution() {
    if (processList.length === 0)
    return "N/A";

    var topProcess = processList[0];
    var topPercentage = ((topProcess.rss_mb / calculateTotalRAM()) * 100).toFixed(1);
    return topProcess.name.split('/').pop() + " (" + topPercentage + "%)";
  }

  Timer {
    id: startupTimer
    interval: 150
    running: true
    onTriggered: processFetcher.running = true
  }
}
