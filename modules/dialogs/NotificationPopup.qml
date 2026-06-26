import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.services
import qs.commons
import qs.components

PanelWindow {
  id: root

  readonly property int cardWidth: ScalerService.s(300)
  readonly property int cardMinHeight: ScalerService.s(56)
  readonly property int cardMaxHeight: ScalerService.s(132)
  readonly property int bodyMaxLines: 3
  readonly property int cardSpacing: ScalerService.s(8)
  readonly property int bottomMargin: ScalerService.s(110)
  readonly property int contentMargin: ScalerService.s(12)
  readonly property int iconSize: ScalerService.s(22)
  readonly property int titleSize: ScalerService.s(13)
  readonly property int bodySize: ScalerService.s(11)
  readonly property int appSize: ScalerService.s(10)
  readonly property int progressHeight: ScalerService.s(3)

  implicitWidth: cardWidth
  anchors {
    bottom: true
  }
  margins {
    bottom: bottomMargin
  }
  exclusiveZone: 0
  visible: notificationModel.count > 0
  color: "transparent"
  mask: Region {}

  property int maxNotifications: 1
  property int defaultDismissMs: 5000
  property int lowDismissMs: 4000
  property int criticalDismissMs: 8000
  property int residentDismissMs: 10000
  property int fadeInMs: 280
  property int fadeOutMs: 280
  property var pendingNotification: null

  property var notificationRefs: ({})

  function dismissTimeoutFor(notification) {
    if (notification.expireTimeout > 0)
      return Math.round(notification.expireTimeout * 1000);

    if (notification.resident)
      return residentDismissMs;

    switch (notification.urgency) {
      case NotificationUrgency.Critical:
      return criticalDismissMs;
      case NotificationUrgency.Low:
      return lowDismissMs;
      default:
      return defaultDismissMs;
    }
  }

  function urgencyColor(urgency) {
    switch (urgency) {
      case NotificationUrgency.Critical:
      return theme.normal.red;
      case NotificationUrgency.Low:
      return theme.normal.green;
      default:
      return theme.normal.blue;
    }
  }

  function clearNotificationRef(notificationId) {
    const nextRefs = Object.assign({}, notificationRefs);
    delete nextRefs[notificationId];
    notificationRefs = nextRefs;
  }

  function expireNotificationById(notificationId) {
    const notification = notificationRefs[notificationId];
    if (notification)
      notification.expire();
    clearNotificationRef(notificationId);
  }

  function dismissNotificationById(notificationId) {
    const notification = notificationRefs[notificationId];
    if (notification)
      notification.dismiss();
    clearNotificationRef(notificationId);
  }

  function appendNotification(notification) {
    const dismissMs = dismissTimeoutFor(notification);
    const iconSource = notification.image || notification.appIcon || "";

    notificationRefs = {
      [notification.id]: notification
    };

    notificationModel.append({
      notificationId: notification.id,
      appName: notification.appName || "",
      summary: notification.summary || "",
      body: notification.body || "",
      urgency: notification.urgency,
      dismissMs: dismissMs,
      iconSource: iconSource
    });

    notification.tracked = true;
  }

  function fadeOutCurrentNotification() {
    const currentItem = notificationList.itemAtIndex(0);
    if (currentItem && typeof currentItem.removeNotification === "function") {
      currentItem.removeNotification(true);
      return true;
    }

    return false;
  }

  function queueOrShowNotification(notification) {
    notification.tracked = true;

    if (notificationModel.count > 0) {
      pendingNotification = notification;

      if (!fadeOutCurrentNotification()) {
        notificationModel.clear();
        notificationRefs = {};
        pendingNotification = null;
        appendNotification(notification);
      }

      return;
    }

    appendNotification(notification);
  }

  function showPendingNotification() {
    if (!pendingNotification)
      return;

    const notification = pendingNotification;
    pendingNotification = null;
    appendNotification(notification);
  }

  implicitHeight: notificationList.height

  Behavior on implicitHeight {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  ListView {
    id: notificationList
    width: cardWidth
    height: Math.min(
      contentHeight,
      maxNotifications * (cardMaxHeight + cardSpacing) - cardSpacing
    )
    spacing: cardSpacing
    clip: true
    interactive: false
    verticalLayoutDirection: ListView.BottomToTop

    model: ListModel {
      id: notificationModel
    }

    Behavior on height {
      NumberAnimation {
        duration: 180
        easing.type: Easing.OutCubic
      }
    }

    delegate: Rectangle {
      id: notificationDelegate

      required property int index
      required property var notificationId
      required property string appName
      required property string summary
      required property string body
      required property int urgency
      required property int dismissMs
      required property string iconSource

      width: notificationList.width
      height: Math.max(
        cardMinHeight,
        Math.min(
          cardMaxHeight,
          contentColumn.implicitHeight + contentMargin * 2 + progressHeight + ScalerService.s(8)
        )
      )
      border.color: theme.button.border
      radius: ScalerService.s(Settings.appearance.radius2)
      border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
      color: theme.primary.background

      opacity: 0
      property bool entered: false

      Behavior on opacity {
        NumberAnimation {
          duration: notificationDelegate.entered ? root.fadeInMs : root.fadeOutMs
          easing.type: Easing.OutCubic
        }
      }

      Component.onCompleted: {
        entered = true;
        opacity = 1;
      }

      HoverHandler {
        onHoveredChanged: {
          if (hovered) {
            autoDismiss.stop();
            dismissAnim.stop();
          } else if (!autoDismiss.running && notificationDelegate.opacity > 0) {
            autoDismiss.restart();
            dismissAnim.start();
          }
        }
      }

      Timer {
        id: autoDismiss
        interval: dismissMs
        running: true
        repeat: false
        onTriggered: removeNotification(true)
      }

      NumberAnimation {
        id: dismissAnim
        target: progressFill
        property: "fillRatio"
        from: 1
        to: 0
        duration: dismissMs
        running: true
        easing.type: Easing.Linear
      }

      ColumnLayout {
        id: contentColumn
        anchors {
          left: parent.left
          right: parent.right
          top: parent.top
          margins: contentMargin
        }
        spacing: ScalerService.s(4)

        RowLayout {
          Layout.fillWidth: true
          spacing: ScalerService.s(8)

          Item {
            Layout.preferredWidth: iconSize
            Layout.preferredHeight: iconSize
            Layout.alignment: Qt.AlignTop

            Image {
              anchors.fill: parent
              visible: iconSource !== ""
              source: iconSource
              fillMode: Image.PreserveAspectFit
              smooth: true
              asynchronous: true
            }

            Rectangle {
              anchors.fill: parent
              visible: iconSource === ""
              radius: iconSize / 2
              color: root.urgencyColor(urgency)

              Text {
                anchors.centerIn: parent
                text: appName ? appName.charAt(0).toUpperCase() : "N"
                font.bold: true
                color: theme.primary.background
                font.pixelSize: ScalerService.s(10)
                font.family: Settings.appearance.font
              }
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(2)

            Text {
              Layout.fillWidth: true
              text: summary || "Notification"
              color: theme.primary.foreground
              font.family: Settings.appearance.font
              font.pixelSize: titleSize
              font.bold: true
              wrapMode: Text.Wrap
              maximumLineCount: 2
              elide: Text.ElideRight
            }

            Text {
              Layout.fillWidth: true
              visible: body !== ""
              text: body
              color: theme.primary.dim_foreground
              font.family: Settings.appearance.font
              font.pixelSize: bodySize
              wrapMode: Text.Wrap
              maximumLineCount: bodyMaxLines
              elide: Text.ElideRight
              lineHeight: 1.25
            }

            Text {
              Layout.fillWidth: true
              visible: appName !== ""
              text: appName
              color: theme.primary.dim_foreground
              font.family: Settings.appearance.font
              font.pixelSize: appSize
              opacity: 0.75
              elide: Text.ElideRight
              maximumLineCount: 1
            }
          }
        }
      }

      Rectangle {
        id: progressTrack
        anchors {
          left: parent.left
          right: parent.right
          bottom: parent.bottom
          leftMargin: contentMargin
          rightMargin: contentMargin
          bottomMargin: ScalerService.s(6)
        }
        height: progressHeight
        radius: progressHeight / 2
        color: theme.primary.dim_background

        Rectangle {
          id: progressFill
          anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
          }
          property real fillRatio: 1
          width: parent.width * Math.max(0, Math.min(fillRatio, 1))
          radius: parent.radius
          color: root.urgencyColor(urgency)

          Behavior on width {
            NumberAnimation {
              duration: 120
              easing.type: Easing.OutCubic
            }
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function (mouse) {
          if (mouse.button === Qt.RightButton)
            removeNotification(false);
        }
      }

      function removeNotification(expired) {
        if (removeTimer.running)
          return;

        autoDismiss.stop();
        dismissAnim.stop();
        if (expired)
          root.expireNotificationById(notificationId);
        else
          root.dismissNotificationById(notificationId);
        entered = false;
        notificationDelegate.opacity = 0;
        removeTimer.start();
      }

      Timer {
        id: removeTimer
        interval: root.fadeOutMs
        onTriggered: {
          notificationModel.remove(index);
          Qt.callLater(root.showPendingNotification);
        }
      }
    }
  }

  NotificationServer {
    id: server
    actionsSupported: true
    imageSupported: true
    inlineReplySupported: true

    onNotification: function (notification) {
      root.queueOrShowNotification(notification);
    }
  }
}