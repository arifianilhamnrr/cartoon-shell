import QtQuick
import qs.services

Rectangle {
  id: root
  Behavior on implicitHeight {
    NumberAnimation {
      duration: 500
      easing.type: Easing.OutCubic
    }
  }
  Behavior on implicitWidth {
    NumberAnimation {
      duration: 500
      easing.type: Easing.OutCubic
    }
  }
  Behavior on scale {
    NumberAnimation {
      duration: 100
    }
  }
  Behavior on color {
    ColorAnimation {
      duration: ThemeService.themeTransitioning ? 0 : 280
      easing.type: Easing.InOutCubic
    }
  }
  Behavior on border.color {
    ColorAnimation {
      duration: ThemeService.themeTransitioning ? 0 : 280
      easing.type: Easing.InOutCubic
    }
  }
}
