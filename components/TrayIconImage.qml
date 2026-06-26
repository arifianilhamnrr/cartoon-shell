import QtQuick
import Qt5Compat.GraphicalEffects
import qs.commons
import qs.services

Image {
  id: root

  property string trayId: ""
  property string trayTitle: ""
  property string trayTooltip: ""

  readonly property var lightIconTrayMatchers: [
    "telegram",
    "obs",
    "nextcloud",
    "keepass",
    "syncthing",
    "flameshot",
    "copyq",
    "ulauncher",
    "ulauncher-rs"
  ]

  readonly property bool needsLightModeTint: {
    if (Settings.appearance.mode !== "light" || source === "")
      return false;

    const haystack = (trayId + " " + trayTitle + " " + trayTooltip).toLowerCase();
    for (let i = 0; i < lightIconTrayMatchers.length; i++) {
      if (haystack.indexOf(lightIconTrayMatchers[i]) >= 0)
        return true;
    }

    return false;
  }

  fillMode: Image.PreserveAspectFit
  smooth: true
  mipmap: true

  layer.enabled: needsLightModeTint
  layer.effect: ColorOverlay {
    color: theme.primary.foreground
  }
}