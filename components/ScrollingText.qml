import QtQuick
import qs.services

Item {
  id: root

  property string text: ""
  property color textColor: theme.primary.foreground
  property real fontSize: 11
  property string fontFamily: "ComicShannsMono Nerd Font"
  property bool italic: false
  property bool scrollEnabled: true
  property real textOpacity: 1
  property int horizontalAlignment: Text.AlignLeft

  implicitHeight: Math.max(label.implicitHeight, ScalerService.s(root.fontSize + 2))
  clip: true

  TextMetrics {
    id: metrics
    font.family: root.fontFamily
    font.pixelSize: ScalerService.s(root.fontSize)
    font.italic: root.italic
    text: root.text
  }

  readonly property bool shouldScroll: root.scrollEnabled
    && root.width > 0
    && metrics.width > root.width

  Text {
    id: label
    height: parent.height
    anchors.verticalCenter: parent.verticalCenter
    text: root.text
    color: root.textColor
    opacity: root.textOpacity
    font.family: root.fontFamily
    font.pixelSize: ScalerService.s(root.fontSize)
    font.italic: root.italic
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: root.shouldScroll ? Text.AlignLeft : root.horizontalAlignment
    elide: root.shouldScroll ? Text.ElideNone : Text.ElideRight
    width: root.shouldScroll ? metrics.width : root.width

    x: root.shouldScroll ? scrollX : 0
    property real scrollX: 0

    SequentialAnimation {
      id: scrollOnceAnim
      loops: 1
      running: false

      PauseAnimation {
        duration: 1200
      }
      NumberAnimation {
        target: label
        property: "scrollX"
        from: 0
        to: -(metrics.width - root.width + ScalerService.s(16))
        duration: Math.max(2000, (metrics.width - root.width) * 14)
        easing.type: Easing.Linear
      }
    }
  }

  function restartScroll() {
    label.scrollX = 0;
    scrollOnceAnim.stop();
    if (root.shouldScroll)
      scrollOnceAnim.start();
  }

  onTextChanged: restartScroll()
  onShouldScrollChanged: restartScroll()
}