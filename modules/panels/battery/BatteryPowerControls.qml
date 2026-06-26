import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.commons

ColumnLayout {
  id: root

  property var lang: LanguageService.translations

  spacing: ScalerService.s(10)
  Layout.fillWidth: true

  CustomText {
    name: lang?.battery_power?.title || "Power"
    isBold: true
    size: "small"
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: ScalerService.s(12)

    ColumnLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(2)

      CustomText {
        name: lang?.battery_power?.keep_awake || "Keep Awake"
        size: "small"
      }

      CustomText {
        name: lang?.battery_power?.keep_awake_hint || "Prevent screen from sleeping"
        size: "xs"
        textColor: theme.primary.dim_foreground
      }
    }

    CustomToggleSwitch {
      adapter: PowerService.keepAwake
      onClicked: PowerService.setKeepAwake(!PowerService.keepAwake)
    }
  }

  Rectangle {
    visible: PowerService.keepAwake
    Layout.fillWidth: true
    Layout.preferredHeight: activeRow.implicitHeight + ScalerService.s(14)
    radius: ScalerService.s(Settings.appearance.radius3)
    color: Qt.alpha(theme.normal.green, 0.12)
    border.color: Qt.alpha(theme.normal.green, 0.35)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

    RowLayout {
      id: activeRow
      anchors.fill: parent
      anchors.margins: ScalerService.s(10)
      spacing: ScalerService.s(8)

      Rectangle {
        Layout.preferredWidth: ScalerService.s(8)
        Layout.preferredHeight: ScalerService.s(8)
        radius: ScalerService.s(4)
        color: theme.normal.green
      }

      IconText {
        name: "schedule"
        size: "small"
        textColor: theme.normal.green
      }

      CustomText {
        name: PowerService.keepAwakeStatusDisplay
        size: "xs"
        textColor: theme.primary.foreground
        Layout.fillWidth: true
      }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: ScalerService.s(1)
    color: theme.primary.foreground
    opacity: 0.15
  }

  CustomText {
    name: lang?.battery_power?.profile_title || "Power Profile"
    isBold: true
    size: "small"
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: ScalerService.s(8)
    visible: PowerService.profileAvailable

    Repeater {
      model: PowerService.profiles

      delegate: Rectangle {
        required property var modelData
        required property int index

        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(72)
        radius: ScalerService.s(Settings.appearance.radius3)
        color: PowerService.activeProfile === modelData.id
          ? Qt.alpha(theme.button.background_select, 0.9)
          : (profileMouse.containsMouse
            ? Qt.alpha(theme.button.background_select, 0.55)
            : Qt.alpha(theme.primary.dim_background, 0.45))
        border.color: PowerService.activeProfile === modelData.id
          ? theme.button.border_select
          : theme.button.border
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
        scale: profileMouse.containsPress ? 0.97 : 1

        ColumnLayout {
          anchors.centerIn: parent
          spacing: ScalerService.s(4)

          IconText {
            name: modelData.icon
            size: "small"
            textColor: PowerService.activeProfile === modelData.id
              ? theme.primary.bright_foreground
              : theme.primary.foreground
            Layout.alignment: Qt.AlignHCenter
          }

          CustomText {
            name: PowerService.profileLabel(modelData, root.lang)
            size: "xs"
            isBold: PowerService.activeProfile === modelData.id
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
          }
        }

        MouseArea {
          id: profileMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: PowerService.setProfile(modelData.id)
        }
      }
    }
  }

  CustomText {
    visible: !PowerService.profileAvailable
    name: lang?.battery_power?.profile_unavailable || "Power profiles unavailable"
    size: "xs"
    textColor: theme.primary.dim_foreground
  }
}