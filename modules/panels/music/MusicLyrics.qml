import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.components

Rectangle {
  id: root

  property real animationProgress: 0

  Layout.fillWidth: true
  Layout.preferredHeight: ScalerService.s(220)
  radius: ScalerService.s(12)
  color: Qt.alpha(theme.primary.dim_background, 0.35)
  border.color: theme.button.border
  border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
  clip: true
  opacity: root.animationProgress > 0.55 ? 1 : 0

  Behavior on opacity {
    NumberAnimation {
      duration: 200
      easing.type: Easing.OutCubic
    }
  }

  Component.onCompleted: LyricsService.updateFromPlayer()

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: ScalerService.s(12)
    spacing: ScalerService.s(8)

    CustomText {
      name: lang?.music?.lyrics || "Lyrics"
      size: "small"
      isBold: true
      textColor: theme.button.text
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true

      CustomText {
        anchors.centerIn: parent
        visible: LyricsService.loading
        name: lang?.music?.loading_lyrics || "Loading lyrics..."
        size: "small"
        textColor: theme.primary.dim_foreground
      }

      CustomText {
        anchors.centerIn: parent
        visible: !LyricsService.loading && !LyricsService.hasLyrics
        name: lang?.music?.no_lyrics || "No lyrics found"
        size: "small"
        textColor: theme.primary.dim_foreground
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        width: parent.width - ScalerService.s(16)
      }

      ScrollView {
        anchors.fill: parent
        visible: !LyricsService.loading && LyricsService.hasLyrics
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ListView {
          id: lyricsList
          width: parent.width
          model: LyricsService.lines
          spacing: ScalerService.s(6)
          boundsBehavior: Flickable.StopAtBounds
          currentIndex: LyricsService.synced ? LyricsService.currentIndex : -1
          highlightFollowsCurrentItem: true
          highlightMoveDuration: 180
          highlightRangeMode: ListView.StrictlyEnforceRange
          preferredHighlightBegin: height * 0.38
          preferredHighlightEnd: height * 0.38

          onCurrentIndexChanged: {
            if (currentIndex >= 0)
              positionViewAtIndex(currentIndex, ListView.Center);
          }

          delegate: CustomText {
            required property int index
            required property var modelData

            width: lyricsList.width
            name: modelData.text
            size: LyricsService.synced && index === LyricsService.currentIndex ? "small" : "xs"
            isBold: LyricsService.synced && index === LyricsService.currentIndex
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            textColor: LyricsService.synced && index === LyricsService.currentIndex
              ? theme.button.text
              : theme.primary.dim_foreground
            opacity: LyricsService.synced
              ? (index === LyricsService.currentIndex ? 1 : 0.45)
              : 0.85
          }
        }
      }
    }
  }
}