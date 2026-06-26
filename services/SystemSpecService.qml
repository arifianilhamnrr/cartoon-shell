pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool loading: true
  property string hostname: "—"
  property string osName: "—"
  property string kernel: "—"
  property string architecture: "—"
  property string cpuModel: "—"
  property string cpuCores: "—"
  property string memory: "—"
  property string gpu: "—"
  property string storage: "—"

  function refresh() {
    root.loading = true;
    specProcess.running = true;
  }

  function applyLine(line) {
    var sep = line.indexOf("=");
    if (sep < 0)
      return;

    var key = line.slice(0, sep).trim();
    var value = line.slice(sep + 1).trim();
    if (!value)
      return;

    switch (key) {
    case "hostname":
      root.hostname = value;
      break;
    case "os":
      root.osName = value;
      break;
    case "kernel":
      root.kernel = value;
      break;
    case "arch":
      root.architecture = value;
      break;
    case "cpu":
      root.cpuModel = value;
      break;
    case "cores":
      root.cpuCores = value;
      break;
    case "memory":
      root.memory = value;
      break;
    case "gpu":
      root.gpu = value;
      break;
    case "storage":
      root.storage = value;
      break;
    }
  }

  Process {
    id: specProcess
    running: false

    command: [
      "bash",
      "-c",
      "printf 'hostname=%s\\n' \"$(hostname)\"; " +
      "printf 'os=%s\\n' \"$(grep -m1 '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '\"' || echo Unknown)\"; " +
      "printf 'kernel=%s\\n' \"$(uname -sr)\"; " +
      "printf 'arch=%s\\n' \"$(uname -m)\"; " +
      "printf 'cpu=%s\\n' \"$(lscpu 2>/dev/null | awk -F: '/Model name/ {sub(/^ +/, \"\", $2); print $2; exit}')\"; " +
      "printf 'cores=%s\\n' \"$(nproc 2>/dev/null || echo ?)\"; " +
      "printf 'memory=%s\\n' \"$(awk '/MemTotal/ {printf \"%.1f GiB\", $2/1024/1024}' /proc/meminfo)\"; " +
      "printf 'gpu=%s\\n' \"$(lspci -nn 2>/dev/null | grep -iE 'vga|3d|display' | head -1 | sed -E 's/^([0-9:.]+ )?[^:]+: //; s/ \\(rev.*//; s/ \\[[0-9a-f]{4}:[0-9a-f]{4}\\]$//')\"; " +
      "printf 'storage=%s\\n' \"$(df -h / --output=size 2>/dev/null | tail -1 | tr -d ' ')\""
    ]

    stdout: StdioCollector {
      onTextChanged: {
        var lines = text.split("\n");
        for (var i = 0; i < lines.length; i++)
          root.applyLine(lines[i]);
      }
    }

    onExited: root.loading = false
  }

  Component.onCompleted: root.refresh()
}