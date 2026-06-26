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

  readonly property bool hasPlayer: !!Players.mprisPlayer
  readonly property bool isPlaying: Players.mprisPlayer?.isPlaying ?? false

  ColumnLayout {
    anchors.fill: parent
    spacing: ScalerService.s(8)

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true

      Item {
        anchors.centerIn: parent
        width: parent.height
        height: parent.width
        rotation: -90
        transformOrigin: Item.Center

        ColumnLayout {
          anchors.fill: parent
          spacing: ScalerService.s(6)

          Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: ScalerService.s(36)
            Layout.preferredHeight: ScalerService.s(36)

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

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(12)
            clip: true

            Text {
              anchors.fill: parent
              text: Players.mprisPlayer?.trackTitle ?? "Not Playing"
              color: theme.primary.foreground
              font.family: "ComicShannsMono Nerd Font"
              font.pixelSize: ScalerService.s(11)
              font.bold: true
              verticalAlignment: Text.AlignVCenter
              elide: Text.ElideRight
            }
          }

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(11)
            clip: true

            property string subtitleText: {
              if (LyricsService.loading)
                return lang?.music?.loading_lyrics || "Loading...";
              if (LyricsService.currentLineText !== "")
                return LyricsService.currentLineText;
              return Players.mprisPlayer?.trackArtist || "Unknown Artist";
            }

            property bool showingLyrics: LyricsService.currentLineText !== "" || LyricsService.loading

            ScrollingText {
              anchors.fill: parent
              text: parent.subtitleText
              textColor: parent.showingLyrics ? theme.button.text : theme.primary.dim_foreground
              textOpacity: parent.showingLyrics ? 0.9 : 1
              fontSize: 9
              italic: parent.showingLyrics
              scrollEnabled: parent.showingLyrics
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true
          onClicked: VisibleService.togglePanel("music")
        }
      }
    }

    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: ScalerService.s(6)
      Layout.preferredHeight: ScalerService.s(72)

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