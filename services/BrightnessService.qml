pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property real brightness: 0
  property int brightnessPercent: 0
  property string deviceName: ""
  property string sysfsPath: ""

  signal updated()

  Process {
    id: readProcess
    command: ["brightnessctl", "-m"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        const line = text.trim().split("\n")[0];
        if (!line)
          return;

        const parts = line.split(",");
        if (parts.length < 5)
          return;

        const current = parseInt(parts[2], 10);
        const max = parseInt(parts[4], 10);
        if (!max || isNaN(current))
          return;

        const nextDevice = parts[0];
        if (nextDevice && nextDevice !== root.deviceName) {
          root.deviceName = nextDevice;
          root.sysfsPath = "/sys/class/backlight/" + nextDevice + "/brightness";
        }

        const nextPercent = Math.round((current / max) * 100);
        const nextBrightness = current / max;

        if (root.brightnessPercent === nextPercent && Math.abs(root.brightness - nextBrightness) < 0.001)
          return;

        root.brightnessPercent = nextPercent;
        root.brightness = nextBrightness;
        root.updated();
      }
    }
  }

  FileView {
    path: root.sysfsPath
    printErrors: false
    watchChanges: root.sysfsPath !== ""
    onFileChanged: root.refresh()
  }

  function refresh() {
    readProcess.running = true;
  }

  Component.onCompleted: refresh()

  IpcHandler {
    target: "brightness"

    function notify() {
      root.refresh();
    }

    function get() {
      return root.brightnessPercent;
    }
  }
}