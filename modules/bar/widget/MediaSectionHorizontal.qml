import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.services
import qs.commons
import qs.components

Item {
  Component.onCompleted: LyricsService.updateFromPlayer()

  readonly property bool isPlaying: Players.mprisPlayer?.isPlaying ?? false

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: ScalerService.s(8)
    anchors.rightMargin: ScalerService.s(8)
    spacing: ScalerService.s(8)

    // Album art
    Item {
      Layout.preferredWidth: ScalerService.s(36)
      Layout.preferredHeight: ScalerService.s(36)
      Layout.alignment: Qt.AlignVCenter

      Item {
        id: artClip
        anchors.fill: parent

        ClippingRectangle {
          anchors.fill: parent
          radius: width / 2
          color: theme.primary.dim_background
          border.color: theme.button.border
          border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

          Image {
            id: albumImage
            anchors.fill: parent
            source: Players.getArtUrl(Players.mprisPlayer)
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
            asynchronous: true
            smooth: true
          }

          IconText {
            anchors.centerIn: parent
            name: "music_note"
            size: "small"
            visible: albumImage.status !== Image.Ready
          }
        }

        RotationAnimation on rotation {
          from: 0
          to: 360
          duration: 12000
          loops: Animation.Infinite
          running: root.isPlaying && albumImage.status === Image.Ready
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: VisibleService.togglePanel("music")
      }
    }

    // Song info — expands to fill empty bar space
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.alignment: Qt.AlignVCenter
      spacing: ScalerService.s(2)

      Item {
        id: songContainer
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(17)
        clip: true

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true
          onClicked: VisibleService.togglePanel("music")
          onEntered: songContainer.opacity = 0.8
          onExited: songContainer.opacity = 1.0
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width
          text: Players.mprisPlayer?.trackTitle ?? "Not Playing"
          color: theme.primary.foreground
          font.family: "ComicShannsMono Nerd Font"
          font.pixelSize: ScalerService.s(13)
          font.bold: true
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
        }

        Behavior on opacity {
          NumberAnimation { duration: 100 }
        }
      }

      Item {
        id: subtitleContainer
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(12)
        clip: true

        property string subtitleText: {
          if (LyricsService.loading)
            return lang?.music?.loading_lyrics || "Loading lyrics...";
          if (LyricsService.currentLineText !== "")
            return LyricsService.currentLineText;
          return Players.mprisPlayer
            ? (Players.mprisPlayer.trackArtist || "Unknown Artist")
            : "Unknown Artist";
        }

        property bool showingLyrics: LyricsService.currentLineText !== "" || LyricsService.loading

        ScrollingText {
          anchors.fill: parent
          text: subtitleContainer.subtitleText
          textColor: subtitleContainer.showingLyrics ? theme.button.text : theme.primary.dim_foreground
          textOpacity: subtitleContainer.showingLyrics ? 0.9 : 1
          fontSize: 10
          italic: subtitleContainer.showingLyrics
          scrollEnabled: subtitleContainer.showingLyrics
        }
      }
    }

    // Controls
    RowLayout {
      Layout.alignment: Qt.AlignVCenter
      spacing: ScalerService.s(0)

      ButtonIconText {
        name: "skip_previous"
        size: "small"
        Layout.alignment: Qt.AlignVCenter
        onClicked: Players.mprisPlayer?.previous()
      }

      ButtonIconText {
        name: root.isPlaying ? "pause" : "play_arrow"
        size: "small"
        Layout.alignment: Qt.AlignVCenter
        onClicked: Players.mprisPlayer?.togglePlaying()
      }

      ButtonIconText {
        name: "skip_next"
        size: "small"
        Layout.alignment: Qt.AlignVCenter
        onClicked: Players.mprisPlayer?.next()
      }
    }
  }
}