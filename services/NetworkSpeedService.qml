pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool enabled: true
  property string interfaceName: ""
  property real downloadBps: 0
  property real uploadBps: 0
  property real dailyDownloadBytes: 0
  property real dailyUploadBytes: 0
  property string dailyDownloadText: "0 B"
  property string dailyUploadText: "0 B"
  property var downloadHistory: []
  property var uploadHistory: []
  property int maxHistoryLength: 40

  property real _prevRx: -1
  property real _prevTx: -1

  function formatSpeed(bps) {
    if (!bps || bps < 1)
      return "0 B/s";

    const units = ["B/s", "KB/s", "MB/s", "GB/s"];
    var value = bps;
    var unit = 0;

    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }

    if (unit === 0)
      return Math.round(value) + " " + units[unit];

    return value.toFixed(1) + " " + units[unit];
  }

  function formatBytesTotal(bytes) {
    if (!bytes || bytes < 1)
      return "0 B";

    if (bytes < 1024 * 1024)
      return Math.round(bytes / 1024) + " KB";

    if (bytes < 1024 * 1024 * 1024)
      return (bytes / (1024 * 1024)).toFixed(1) + " MB";

    return (bytes / (1024 * 1024 * 1024)).toFixed(2) + " GB";
  }

  function refreshDailyDisplay(force) {
    const downText = root.formatBytesTotal(root.dailyDownloadBytes);
    const upText = root.formatBytesTotal(root.dailyUploadBytes);

    if (!force
        && downText === root.dailyDownloadText
        && upText === root.dailyUploadText)
      return;

    root.dailyDownloadText = downText;
    root.dailyUploadText = upText;
  }

  function updateInterfaceTotals(rx, tx) {
    root.dailyDownloadBytes = rx;
    root.dailyUploadBytes = tx;

    const deltaDown = rx - root._displayedDailyDown;
    const deltaUp = tx - root._displayedDailyUp;
    if (forceDisplayRefresh(deltaDown, deltaUp))
      root.refreshDailyDisplay(true);
  }

  function forceDisplayRefresh(deltaDown, deltaUp) {
    return deltaDown >= 5 * 1024 * 1024 || deltaUp >= 5 * 1024 * 1024;
  }

  property real _displayedDailyDown: 0
  property real _displayedDailyUp: 0

  function pushHistory(download, upload) {
    const downHist = root.downloadHistory.slice();
    const upHist = root.uploadHistory.slice();

    downHist.push({
      value: download
    });
    upHist.push({
      value: upload
    });

    if (downHist.length > root.maxHistoryLength)
      downHist.shift();
    if (upHist.length > root.maxHistoryLength)
      upHist.shift();

    root.downloadHistory = downHist;
    root.uploadHistory = upHist;
  }

  function parseStats(text) {
    if (!text)
      return;

    const parts = text.trim().split(/\s+/);
    if (parts.length < 2)
      return;

    const rx = parseFloat(parts[0]);
    const tx = parseFloat(parts[1]);

    if (isNaN(rx) || isNaN(tx))
      return;

    root.updateInterfaceTotals(rx, tx);

    if (root._prevRx < 0) {
      root._prevRx = rx;
      root._prevTx = tx;
      root.refreshDailyDisplay(true);
      return;
    }

    const down = Math.max(0, rx - root._prevRx);
    const up = Math.max(0, tx - root._prevTx);

    root._prevRx = rx;
    root._prevTx = tx;
    root.downloadBps = down;
    root.uploadBps = up;
    root.pushHistory(down, up);
  }

  function refreshInterface() {
    if (!ifaceProcess.running)
      ifaceProcess.running = true;
  }

  function pollStats() {
    if (!root.interfaceName || statsProcess.running)
      return;

    statsProcess.command = ["bash", "-c",
      "awk -v iface='" + root.interfaceName + "' '$0 ~ iface\":\" { print $2, $10 }' /proc/net/dev"
    ];
    statsProcess.running = true;
  }

  Process {
    id: ifaceProcess
    command: ["bash", "-c",
      "IFACE=$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2 == \"wifi\" && $1 != \"lo\" { print $1; exit }'); " +
      "if [ -z \"$IFACE\" ]; then IFACE=$(ls /sys/class/net 2>/dev/null | grep -E '^wl' | head -1); fi; " +
      "if [ -z \"$IFACE\" ]; then IFACE=$(ip route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i == \"dev\") { print $(i + 1); exit }}'); fi; " +
      "echo \"$IFACE\""
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        const iface = this.text ? this.text.trim() : "";
        if (!iface)
          return;

        if (iface === root.interfaceName)
          return;

        root.interfaceName = iface;
        root._prevRx = -1;
        root._prevTx = -1;
        root.downloadBps = 0;
        root.uploadBps = 0;
        root.dailyDownloadBytes = 0;
        root.dailyUploadBytes = 0;
        root.refreshDailyDisplay(true);
        root.pollStats();
      }
    }
  }

  Timer {
    id: dailyDisplayTimer
    interval: 30000
    repeat: true
    running: root.enabled
    triggeredOnStart: true
    onTriggered: {
      root.refreshDailyDisplay(true);
      root._displayedDailyDown = root.dailyDownloadBytes;
      root._displayedDailyUp = root.dailyUploadBytes;
    }
  }

  Process {
    id: statsProcess
    stdout: StdioCollector {
      onStreamFinished: root.parseStats(this.text)
    }
  }

  Timer {
    interval: 5000
    repeat: true
    running: root.enabled
    triggeredOnStart: true
    onTriggered: root.refreshInterface()
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.enabled && root.interfaceName !== ""
    triggeredOnStart: true
    onTriggered: root.pollStats()
  }
}