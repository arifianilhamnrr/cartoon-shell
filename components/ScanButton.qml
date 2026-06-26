import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

CustomRectangle {
  id: root

  property bool scanning: false
  property bool enabled: true
  property string label: "Scan"
  property string scanningLabel: "Scanning..."

  signal clicked()

  implicitWidth: scanRow.implicitWidth + ScalerService.s(16)
  implicitHeight: ScalerService.s(34)
  radius: ScalerService.s(10)
  color: theme.button.background
  border.color: theme.button.border
  border.width: ScalerService.s(2)
  opacity: root.enabled ? (scanMouseArea.pressed ? 0.8 : 1) : 0.5

  RowLayout {
    id: scanRow
    anchors.centerIn: parent
    spacing: ScalerService.s(6)

    Item {
      width: scanIcon.implicitWidth
      height: scanIcon.implicitHeight

      IconText {
        id: scanIcon
        anchors.centerIn: parent
        name: "refresh"
        size: "xs"
        textColor: theme.button.text
        transformOrigin: Item.Center

        RotationAnimation on rotation {
          running: root.scanning
          from: 0
          to: 360
          duration: 900
          loops: Animation.Infinite
        }
      }
    }

    CustomText {
      name: root.scanning ? root.scanningLabel : root.label
      size: "xs"
      isBold: true
      textColor: theme.button.text
    }
  }

  MouseArea {
    id: scanMouseArea
    anchors.fill: parent
    enabled: root.enabled && !root.scanning
    hoverEnabled: true
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.clicked()
  }
}