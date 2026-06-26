import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.commons

ColumnLayout {
  id: root

  property string sectionTitle: ""
  property var rows: []

  spacing: ScalerService.s(10)
  Layout.fillWidth: true
  visible: rows.length > 0

  CustomText {
    name: root.sectionTitle
    isBold: true
    size: "small"
    visible: root.sectionTitle !== ""
  }

  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: specColumn.implicitHeight + ScalerService.s(24)
    color: Qt.alpha(theme.primary.dim_background, 0.5)
    radius: ScalerService.s(Settings.appearance.radius2)
    border.color: theme.button.border
    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

    ColumnLayout {
      id: specColumn
      anchors.fill: parent
      anchors.margins: ScalerService.s(12)
      spacing: ScalerService.s(8)

      Repeater {
        model: root.rows

        delegate: RowLayout {
          required property var modelData
          Layout.fillWidth: true
          spacing: ScalerService.s(12)

          CustomText {
            name: modelData.label
            size: "xs"
            textColor: theme.primary.dim_foreground
            Layout.preferredWidth: parent.width * 0.34
          }

          CustomText {
            name: modelData.value || "—"
            size: "small"
            isBold: true
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
            Layout.fillWidth: true
          }
        }
      }
    }
  }
}