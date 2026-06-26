pragma Singleton

import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
  id: root

  readonly property var mprisPlayer: Players.pickActivePlayer(Mpris.players.values)

  property bool loading: false
  property bool hasLyrics: false
  property bool synced: false
  property var lines: []
  property int currentIndex: -1
  property string currentLineText: ""
  property string plainText: ""
  property string trackKey: ""

  property string _pendingTitle: ""
  property string _pendingArtist: ""
  property string _pendingAlbum: ""
  property int _pendingDuration: 0
  property bool _searchFallback: false

  function buildGetUrl(title, artist, album, duration) {
    var url = "https://lrclib.net/api/get?track_name=" + encodeURIComponent(title)
      + "&artist_name=" + encodeURIComponent(artist);
    if (album)
      url += "&album_name=" + encodeURIComponent(album);
    if (duration > 0)
      url += "&duration=" + duration;
    return url;
  }

  function buildSearchUrl(title, artist) {
    return "https://lrclib.net/api/search?q=" + encodeURIComponent(title + " " + artist);
  }

  function clearLyrics() {
    root.loading = false;
    root.hasLyrics = false;
    root.synced = false;
    root.lines = [];
    root.currentIndex = -1;
    root.currentLineText = "";
    root.plainText = "";
    root.trackKey = "";
  }

  function refreshCurrentLineText() {
    if (!root.hasLyrics || root.currentIndex < 0 || root.currentIndex >= root.lines.length) {
      root.currentLineText = "";
      return;
    }
    root.currentLineText = root.lines[root.currentIndex].text;
  }

  function updateFromPlayer() {
    var player = root.mprisPlayer;
    if (!player) {
      clearLyrics();
      return;
    }

    var title = (player.trackTitle || "").trim();
    var artist = (player.trackArtist || "").trim();
    var album = (player.trackAlbum || "").trim();
    var duration = Math.round(player.length || 0);

    if (!title) {
      clearLyrics();
      return;
    }

    var key = title.toLowerCase() + "|" + artist.toLowerCase() + "|" + duration;
    if (key === root.trackKey && (root.hasLyrics || root.loading))
      return;

    root.trackKey = key;
    root._pendingTitle = title;
    root._pendingArtist = artist;
    root._pendingAlbum = album;
    root._pendingDuration = duration;
    root._searchFallback = false;
    root.fetchLyrics(buildGetUrl(title, artist, album, duration));
  }

  function fetchLyrics(url) {
    root.loading = true;
    root.hasLyrics = false;
    root.synced = false;
    root.lines = [];
    root.currentIndex = -1;
    root.currentLineText = "";
    root.plainText = "";

    lyricsProcess.command = [
      "curl", "-s", "--max-time", "12",
      url
    ];
    lyricsProcess.running = true;
  }

  function fetchSearchFallback() {
    if (root._searchFallback)
      return;
    root._searchFallback = true;
    root.fetchLyrics(buildSearchUrl(root._pendingTitle, root._pendingArtist));
  }

  function parseSyncedLyrics(text) {
    var parsed = [];
    var rows = String(text).split("\n");

    for (var i = 0; i < rows.length; i++) {
      var row = rows[i].trim();
      if (!row)
        continue;

      var match = row.match(/^\[(\d+):(\d+(?:\.\d+)?)\](.*)$/);
      if (!match)
        continue;

      var textLine = match[3].trim();
      if (!textLine)
        continue;

      parsed.push({
        time: parseInt(match[1], 10) * 60 + parseFloat(match[2]),
        text: textLine
      });
    }

    parsed.sort(function (a, b) {
      return a.time - b.time;
    });

    return parsed;
  }

  function parsePlainLyrics(text) {
    var parsed = [];
    var rows = String(text).split("\n");

    for (var i = 0; i < rows.length; i++) {
      var line = rows[i].trim();
      if (line)
        parsed.push({ time: -1, text: line });
    }

    return parsed;
  }

  function applyLyricsData(data) {
    if (!data)
      return false;

    if (data.code === 404) {
      fetchSearchFallback();
      return false;
    }

    if (Array.isArray(data)) {
      if (data.length === 0) {
        root.loading = false;
        return false;
      }
      return applyLyricsData(data[0]);
    }

    var syncedText = data.syncedLyrics || "";
    var plain = data.plainLyrics || "";

    if (syncedText) {
      var syncedLines = parseSyncedLyrics(syncedText);
      if (syncedLines.length > 0) {
        root.lines = syncedLines;
        root.synced = true;
        root.plainText = syncedLines.map(function (line) {
          return line.text;
        }).join("\n");
        root.hasLyrics = true;
        root.loading = false;
        root.updatePlaybackLine(root.mprisPlayer ? root.mprisPlayer.position : 0);
        return true;
      }
    }

    if (plain) {
      var plainLines = parsePlainLyrics(plain);
      if (plainLines.length > 0) {
        root.lines = plainLines;
        root.synced = false;
        root.plainText = plain;
        root.hasLyrics = true;
        root.currentIndex = 0;
        root.refreshCurrentLineText();
        root.loading = false;
        root.updatePlaybackLine(root.mprisPlayer ? root.mprisPlayer.position : 0);
        return true;
      }
    }

    if (!root._searchFallback)
      fetchSearchFallback();
    else
      root.loading = false;

    return false;
  }

  function indexForTime(position) {
    if (!root.synced || root.lines.length === 0)
      return -1;

    var idx = -1;
    for (var i = 0; i < root.lines.length; i++) {
      if (root.lines[i].time <= position)
        idx = i;
      else
        break;
    }
    return idx;
  }

  function updateCurrentLine(position) {
    if (!root.hasLyrics || !root.synced)
      return;

    var idx = indexForTime(position);
    if (idx !== root.currentIndex) {
      root.currentIndex = idx;
      root.refreshCurrentLineText();
    }
  }

  function updatePlainLine(position) {
    if (!root.hasLyrics || root.synced || root.lines.length === 0)
      return;

    var length = root.mprisPlayer ? root.mprisPlayer.length : 0;
    if (length <= 0)
      return;

    var idx = Math.min(
      root.lines.length - 1,
      Math.max(0, Math.floor((position / length) * root.lines.length))
    );

    if (idx !== root.currentIndex) {
      root.currentIndex = idx;
      root.refreshCurrentLineText();
    }
  }

  function updatePlaybackLine(position) {
    if (!root.hasLyrics)
      return;
    if (root.synced)
      root.updateCurrentLine(position);
    else
      root.updatePlainLine(position);
  }

  Process {
    id: lyricsProcess
    running: false

    stdout: StdioCollector {
      id: lyricsOutput
    }

    onExited: function (exitCode) {
      var text = lyricsOutput.text ? lyricsOutput.text.trim() : "";

      if (!text) {
        if (!root._searchFallback)
          root.fetchSearchFallback();
        else
          root.loading = false;
        return;
      }

      try {
        var data = JSON.parse(text);
        if (!root.applyLyricsData(data) && root._searchFallback)
          root.loading = false;
      } catch (e) {
        if (!root._searchFallback)
          root.fetchSearchFallback();
        else
          root.loading = false;
      }
    }
  }

  Timer {
    id: positionTimer
    interval: 250
    running: !!root.mprisPlayer && root.hasLyrics
    repeat: true
    onTriggered: root.updatePlaybackLine(root.mprisPlayer.position)
  }

  Timer {
    id: trackPollTimer
    interval: 2000
    running: !!root.mprisPlayer
    repeat: true
    onTriggered: root.updateFromPlayer()
  }

  Connections {
    target: root.mprisPlayer
    enabled: !!root.mprisPlayer

    function onTrackTitleChanged() {
      root.updateFromPlayer();
    }

    function onTrackArtistChanged() {
      root.updateFromPlayer();
    }

    function onTrackAlbumChanged() {
      root.updateFromPlayer();
    }

    function onLengthChanged() {
      root.updateFromPlayer();
    }
  }

  Component.onCompleted: Qt.callLater(root.updateFromPlayer)
}