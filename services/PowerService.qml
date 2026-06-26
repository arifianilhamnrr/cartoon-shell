pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
  id: root

  property bool keepAwake: false
  property var keepAwakeSince: null
  property string keepAwakeSinceText: ""
  property string keepAwakeElapsedText: ""
  property string keepAwakeStatusDisplay: ""
  property string activeProfile: ""
  property bool profileAvailable: false

  onKeepAwakeChanged: {
    if (keepAwake) {
      keepAwakeSince = new Date();
      updateKeepAwakeDisplay();
    } else {
      keepAwakeSince = null;
      keepAwakeSinceText = "";
      keepAwakeElapsedText = "";
      keepAwakeStatusDisplay = "";
    }
  }

  readonly property var profiles: [
    {
      id: "power-saver",
      labelKey: "power_saver",
      icon: "eco",
      fallback: "Power Saver"
    },
    {
      id: "balanced",
      labelKey: "balanced",
      icon: "balance",
      fallback: "Balanced"
    },
    {
      id: "performance",
      labelKey: "performance",
      icon: "bolt",
      fallback: "Performance"
    }
  ]

  Process {
    id: inhibitProcess
    command: [
      "systemd-inhibit",
      "--what=idle:sleep:handle-lid-switch",
      "--who=cartoon-shell",
      "--why=Keep screen awake",
      "sleep",
      "infinity"
    ]
    running: root.keepAwake
  }

  Process {
    id: profileReadProcess
    command: ["powerprofilesctl", "get"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        const profile = text.trim();
        if (profile)
          root.activeProfile = profile;
      }
    }
  }

  Process {
    id: profileCheckProcess
    command: ["sh", "-c", "command -v powerprofilesctl >/dev/null"]
    running: true

    onExited: function (exitCode) {
      root.profileAvailable = exitCode === 0;
      if (root.profileAvailable)
        root.refreshProfile();
    }
  }

  Timer {
    id: profileRefreshTimer
    interval: 250
    repeat: false
    onTriggered: profileReadProcess.running = true
  }

  Timer {
    id: keepAwakeTimer
    interval: 1000
    running: root.keepAwake
    repeat: true
    onTriggered: root.updateKeepAwakeDisplay()
  }

  function updateKeepAwakeDisplay() {
    if (!keepAwakeSince)
      return;

    keepAwakeSinceText = Qt.formatDateTime(keepAwakeSince, "HH:mm:ss");

    const elapsedMs = Date.now() - keepAwakeSince.getTime();
    const totalSeconds = Math.max(0, Math.floor(elapsedMs / 1000));
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;

    if (hours > 0)
      keepAwakeElapsedText = hours + "h " + minutes + "m " + seconds + "s";
    else if (minutes > 0)
      keepAwakeElapsedText = minutes + "m " + seconds + "s";
    else
      keepAwakeElapsedText = seconds + "s";

    const lang = LanguageService.translations;
    const sinceLabel = (lang?.battery_power?.keep_awake_active_since || "Active since {time}")
      .replace("{time}", keepAwakeSinceText);
    const elapsedLabel = (lang?.battery_power?.keep_awake_elapsed || "On for {duration}")
      .replace("{duration}", keepAwakeElapsedText);
    keepAwakeStatusDisplay = sinceLabel + " · " + elapsedLabel;
  }

  function toggleKeepAwake() {
    keepAwake = !keepAwake;
  }

  function setKeepAwake(enabled) {
    keepAwake = enabled;
  }

  function setProfile(profileId) {
    if (!profileAvailable || !profileId || profileId === activeProfile)
      return;

    Quickshell.execDetached(["powerprofilesctl", "set", profileId]);
    activeProfile = profileId;
    profileRefreshTimer.restart();
  }

  function refreshProfile() {
    if (profileAvailable)
      profileReadProcess.running = true;
  }

  function profileLabel(profile, lang) {
    if (!profile)
      return "";
    return lang?.battery_power?.[profile.labelKey] || profile.fallback;
  }
}