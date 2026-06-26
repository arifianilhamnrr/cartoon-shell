pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
  id: root

  property string currentMode: ""
  property string currentLabel: ""
  property string currentIcon: "monitor"

  signal updated()

  readonly property var modes: [
    {
      id: "laptop",
      labelKey: "laptop_only",
      icon: "laptop_windows",
      fallback: "PC screen only"
    },
    {
      id: "extend",
      labelKey: "extend",
      icon: "desktop_windows",
      fallback: "Extend"
    },
    {
      id: "mirror",
      labelKey: "mirror",
      icon: "content_copy",
      fallback: "Mirror"
    }
  ]

  function modeById(modeId) {
    for (let i = 0; i < modes.length; i++) {
      if (modes[i].id === modeId)
        return modes[i];
    }
    return null;
  }

  function modeLabel(mode, lang) {
    if (!mode)
      return "";
    return lang?.display?.[mode.labelKey] || mode.fallback;
  }

  function showMode(modeId) {
    const mode = modeById(modeId);
    if (!mode)
      return;

    currentMode = mode.id;
    currentIcon = mode.icon;
    currentLabel = modeLabel(mode, LanguageService.translations);
    updated();
  }

  IpcHandler {
    target: "display"

    function notify(mode: string): void {
      root.showMode(mode);
    }

    function get() {
      return root.currentMode;
    }
  }
}