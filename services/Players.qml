pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
  id: root

  readonly property var playersList: Mpris.players.values

  function pickActivePlayer(players) {
    if (!players || players.length === 0)
      return null;

    var playing = null;
    var withTitle = null;

    for (var i = 0; i < players.length; i++) {
      var player = players[i];
      var title = (player.trackTitle || "").trim();

      if (player.isPlaying) {
        if (title)
          return player;
        if (!playing)
          playing = player;
      }

      if (title && !withTitle)
        withTitle = player;
    }

    return playing || withTitle || players[0];
  }

  readonly property var mprisPlayer: pickActivePlayer(playersList)

  function getArtUrl(player: MprisPlayer): string {
    if (!player)
      return "";
    if (player.trackArtUrl)
      return player.trackArtUrl;

    const url = player.metadata["xesam:url"] ?? "";
    if (url.startsWith("https://www.youtube.com/watch")) {
      const id = url.match(/[?&]v=([\w-]{11})/)?.[1];
      return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : "";
    }
    return "";
  }

  function getProgress() {
    if (!root.mprisPlayer)
      return 0;

    var pos = root.mprisPlayer.position ?? 0;
    var len = root.mprisPlayer.length ?? 0;

    if (len <= 0 || pos < 0)
      return 0;

    var progress = pos / len;
    return Math.max(0, Math.min(1, progress));
  }

  function formatTime(seconds) {
    if (isNaN(seconds) || seconds < 0)
      return "00:00";

    var totalSeconds = Math.floor(seconds);
    var minutes = Math.floor(totalSeconds / 60);
    var secs = totalSeconds % 60;

    function pad(n) {
      return n < 10 ? "0" + n : n;
    }

    return pad(minutes) + ":" + pad(secs);
  }

  function playPause(): void {
    const active = root.mprisPlayer;
    if (active?.canTogglePlaying)
      active.togglePlaying();
  }

  function previous(): void {
    const active = root.mprisPlayer;
    if (active?.canGoPrevious)
      active.previous();
  }

  function next(): void {
    const active = root.mprisPlayer;
    if (!active) {
      console.warn("Cannot go next: no active player");
      return;
    }
    if (active.canGoNext === true)
      active.next();
    else
      console.warn("Cannot go next: canGoNext is false");
  }

  function stop(): void {
    root.mprisPlayer?.stop();
  }
}