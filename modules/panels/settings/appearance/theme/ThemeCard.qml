// components/Settings/ThemeCard.qml
import QtQuick
import qs.services
import qs.commons
import qs.components

Rectangle {
  id: themeCard

  property string type: "light"
  property bool isSelected: false
  property string label: ""
  property bool isEnabled: Settings.appearance.theme === "matugen" || Settings.appearance.dynamic

  signal clicked

  width: ScalerService.s(100)
  height: ScalerService.s(80)
  radius: ScalerService.s(12)

  color: type === "light" ? "#f5eee6" : "#24273a"
  border.color: isSelected ? theme.button.text : theme.button.border
  border.width: isSelected ? ScalerService.s(3) : ScalerService.s(2)
  opacity: isEnabled ? 1.0 : 0.45
  scale: cardMouseArea.pressed ? 0.96 : 1

  Behavior on scale {
    NumberAnimation {
      duration: 140
      easing.type: Easing.OutCubic
    }
  }

  Behavior on border.color {
    ColorAnimation {
      duration: ThemeService.themeTransitioning ? 0 : 320
      easing.type: Easing.InOutCubic
    }
  }

  Behavior on border.width {
    NumberAnimation {
      duration: 220
      easing.type: Easing.OutCubic
    }
  }

  Column {
    anchors.centerIn: parent
    spacing: ScalerService.s(6)

    Rectangle {
      width: ScalerService.s(60)
      height: ScalerService.s(24)
      radius: ScalerService.s(8)
      color: type === "light" ? "#2b2530" : "#cad3f5"
    }

    Rectangle {
      width: ScalerService.s(60)
      height: ScalerService.s(10)
      radius: ScalerService.s(3)
      color: type === "light" ? "#b0a89e" : "#494d64"
    }
  }

  MouseArea {
    id: cardMouseArea
    anchors.fill: parent
    enabled: isEnabled && !ThemeService.themeTransitioning
    cursorShape: isEnabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
    onClicked: themeCard.clicked()
  }

  Text {
    text: label
    color: type === "light" ? "#2b2530" : "#cad3f5"
    opacity: isEnabled ? 1 : 0.6
    font {
      family: "ComicShannsMono Nerd Font"
      pixelSize: ScalerService.s(12)
      bold: true
    }
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: ScalerService.s(8)
  }

  Rectangle {
    visible: isSelected && isEnabled
    width: ScalerService.s(20)
    height: ScalerService.s(20)
    radius: ScalerService.s(10)
    color: theme.button.text
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: ScalerService.s(5)
    scale: visible ? 1 : 0

    Behavior on scale {
      NumberAnimation {
        duration: 220
        easing.type: Easing.OutBack
      }
    }

    IconText {
      name: "check"
      size: "xs"
      anchors.centerIn: parent
      textColor: theme.button.background
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: theme.primary.foreground
    opacity: ThemeService.themeTransitioning && isSelected ? 0.06 : 0
    visible: opacity > 0

    Behavior on opacity {
      NumberAnimation {
        duration: 180
      }
    }
  }
}