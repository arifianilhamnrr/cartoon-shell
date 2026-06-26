import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.services
import qs.commons
import qs.components
import "./widget/" as Com

Rectangle {
  id: root
  color: theme.primary.background
  border.color: theme.button.border
  border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
  radius: ScalerService.s(Settings.appearance.radius2)
  width: root.animationProgress > 0.2 ? parent.width : 0
  height: root.animationProgress > 0.2 ? parent.height : 0
  anchors.centerIn: parent
  property real animationProgress: 0
  SequentialAnimation on animationProgress {
    running: true
    NumberAnimation {
      from: 0
      to: 1
      duration: 1000
      easing.type: Easing.Linear
    }
  }
  Behavior on height {
    NumberAnimation {
      id: heightAnim
      duration: 500
      easing.type: Easing.OutCubic
    }
  }
  Behavior on width {
    NumberAnimation {
      id: widthAnim
      duration: 500
      easing.type: Easing.OutCubic
    }
  }

  property bool isVertical: Settings.bar.position === "left" || Settings.bar.position === "right"

  Component {
    id: horizontalLayout
    Com.MediaSectionHorizontal{}
  }

  Component {
    id: verticalLayout
    Com.MediaSectionVertical{}
  }
  // UI Layout
  Loader {
    anchors.fill: parent
    sourceComponent: isVertical ? verticalLayout : horizontalLayout
  }

}
