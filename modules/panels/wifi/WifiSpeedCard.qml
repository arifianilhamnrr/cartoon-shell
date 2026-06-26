import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

Rectangle {
  id: root

  property var wifiManager
  property real animationProgress: 0

  Layout.fillWidth: true
  implicitHeight: contentColumn.implicitHeight + ScalerService.s(24)
  radius: ScalerService.s(Settings.appearance.radius2)
  color: Qt.alpha(theme.primary.dim_background, 0.6)
  border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
  border.color: theme.normal.black
  visible: wifiManager && wifiManager.wifiEnabled
  opacity: animationProgress > 0.55 ? 1 : 0

  ColumnLayout {
    id: contentColumn
    anchors.fill: parent
    anchors.margins: ScalerService.s(12)
    spacing: ScalerService.s(8)

    CustomText {
      name: lang?.wifi?.network_speed || "Network Speed"
      isBold: true
      size: "small"
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(16)

      RowLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(6)

        IconText {
          name: "arrow_downward"
          textColor: theme.normal.blue
        }

        ColumnLayout {
          spacing: 0
          CustomText {
            name: lang?.wifi?.download || "Download"
            size: "2xs"
            textColor: theme.primary.dim_foreground
          }
          CustomText {
            name: NetworkSpeedService.formatSpeed(NetworkSpeedService.downloadBps)
            size: "small"
            isBold: true
            textColor: theme.button.text
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(6)

        IconText {
          name: "arrow_upward"
          textColor: theme.normal.green
        }

        ColumnLayout {
          spacing: 0
          CustomText {
            name: lang?.wifi?.upload || "Upload"
            size: "2xs"
            textColor: theme.primary.dim_foreground
          }
          CustomText {
            name: NetworkSpeedService.formatSpeed(NetworkSpeedService.uploadBps)
            size: "small"
            isBold: true
            textColor: theme.button.text
          }
        }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: ScalerService.s(72)

      Canvas {
        id: speedChart
        anchors.fill: parent
        antialiasing: true

        property var downHistory: NetworkSpeedService.downloadHistory
        property var upHistory: NetworkSpeedService.uploadHistory

        onDownHistoryChanged: requestPaint()
        onUpHistoryChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
          const ctx = getContext("2d");
          ctx.reset();

          const down = downHistory;
          const up = upHistory;
          if (down.length < 2)
            return;

          const w = width;
          const h = height;
          const pad = ScalerService.s(4);
          const chartW = w - pad * 2;
          const chartH = h - pad * 2;

          let peak = 1024;
          for (let i = 0; i < down.length; i++)
            peak = Math.max(peak, down[i].value || 0, up[i]?.value || 0);

          function drawLine(history, color) {
            ctx.strokeStyle = color;
            ctx.lineWidth = ScalerService.s(2);
            ctx.beginPath();

            for (let i = 0; i < history.length; i++) {
              const x = pad + (chartW * i / Math.max(1, history.length - 1));
              const y = pad + chartH - (chartH * (history[i].value || 0) / peak);
              if (i === 0)
                ctx.moveTo(x, y);
              else
                ctx.lineTo(x, y);
            }

            ctx.stroke();
          }

          drawLine(down, theme.normal.blue);
          drawLine(up, theme.normal.green);
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: ScalerService.s(1)
      color: theme.primary.foreground
      opacity: 0.15
    }

    CustomText {
      name: {
        var label = lang?.wifi?.daily_usage || "Total usage";
        if (NetworkSpeedService.interfaceName)
          return label + " · " + NetworkSpeedService.interfaceName;
        return label;
      }
      size: "2xs"
      textColor: theme.primary.dim_foreground
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(16)

      RowLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(4)

        IconText {
          name: "arrow_downward"
          textColor: theme.normal.blue
          opacity: 0.75
        }
        CustomText {
          name: NetworkSpeedService.dailyDownloadText
          size: "small"
          textColor: theme.primary.dim_foreground
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(4)

        IconText {
          name: "arrow_upward"
          textColor: theme.normal.green
          opacity: 0.75
        }
        CustomText {
          name: NetworkSpeedService.dailyUploadText
          size: "small"
          textColor: theme.primary.dim_foreground
        }
      }
    }
  }
}