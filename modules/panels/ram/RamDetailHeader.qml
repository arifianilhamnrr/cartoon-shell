import QtQuick
import qs.services
import qs.components

Item {
  id: header
  signal closeClicked

  property real animationProgress: 0

  CustomText{
    anchors.centerIn: parent

    name: lang?.ram?.panel_title || "RAM Manager"
    size: "large"
    isBold: true
  }
  CloseButton{
    onClicked: VisibleService.togglePanel("ram")
  }
}
