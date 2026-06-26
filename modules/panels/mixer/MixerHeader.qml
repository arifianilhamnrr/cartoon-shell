import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
  id: root

  CustomText {
    name: lang?.mixer?.title || "Audio Mixer"
    size: "large"
    isBold: true
    anchors.centerIn: parent
  }
  CloseButton{
    onClicked: VisibleService.togglePanel("mixer")
  }
}
