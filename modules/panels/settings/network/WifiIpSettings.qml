import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

Rectangle {
  id: root
  required property var wifiManager

  Layout.fillWidth: true
  implicitHeight: {
    root.useStatic;
    return ipColumn.implicitHeight + ScalerService.s(24);
  }
  radius: ScalerService.s(Settings.appearance.radius2)
  color: Qt.alpha(theme.primary.dim_background, 0.6)
  border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
  border.color: theme.normal.black
  visible: wifiManager.wifiEnabled && wifiManager.connectionDetails.connected

  property bool useStatic: false
  property string staticIp: ""
  property string staticPrefix: "24"
  property string staticGateway: ""
  property string primaryDns: ""
  property string secondaryDns: ""

  function prefillStaticFields() {
    var details = wifiManager.connectionDetails;

    if (details.ipv4Method === "manual") {
      root.staticIp = details.staticIp || "";
      root.staticPrefix = details.staticPrefix || "24";
      root.staticGateway = details.staticGateway || "";
      root.primaryDns = details.customDns[0] || "";
      root.secondaryDns = details.customDns[1] || "";
      return;
    }

    var ipParts = (details.ip || "").split("/");
    root.staticIp = ipParts[0] || "";
    root.staticPrefix = ipParts[1] || "24";
    root.staticGateway = (details.gateway || "").split("/")[0] || "";
    root.primaryDns = details.dns[0] || "";
    root.secondaryDns = details.dns[1] || "";
  }

  function syncFromConnection() {
    var details = wifiManager.connectionDetails;
    root.useStatic = details.ipv4Method === "manual";
    root.prefillStaticFields();
  }

  ColumnLayout {
    id: ipColumn
    anchors.fill: parent
    anchors.margins: ScalerService.s(12)
    spacing: ScalerService.s(10)

    CustomText {
      name: lang?.wifi?.ip_settings || "IP Configuration"
      isBold: true
      size: "small"
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(12)

      CustomText {
        name: lang?.wifi?.ip_mode || "IP Mode"
        size: "xs"
        Layout.fillWidth: true
      }

      CustomText {
        name: root.useStatic
          ? (lang?.wifi?.ip_static || "Static IP")
          : (lang?.wifi?.ip_dhcp || "DHCP (Automatic)")
        size: "xs"
        isBold: true
        textColor: theme.button.text
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(8)

      CustomRectangle {
        Layout.fillWidth: true
        implicitHeight: ScalerService.s(38)
        radius: ScalerService.s(10)
        color: !root.useStatic
          ? Qt.alpha(theme.button.text, 0.35)
          : Qt.alpha(theme.button.background, 0.6)
        border.color: theme.button.border
        border.width: ScalerService.s(2)

        CustomText {
          anchors.centerIn: parent
          name: lang?.wifi?.ip_dhcp || "DHCP"
          size: "small"
          isBold: !root.useStatic
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.useStatic = false;
            if (wifiManager.connectionDetails.ipv4Method === "manual")
              wifiManager.setIpv4Dhcp();
          }
        }
      }

      CustomRectangle {
        Layout.fillWidth: true
        implicitHeight: ScalerService.s(38)
        radius: ScalerService.s(10)
        color: root.useStatic
          ? Qt.alpha(theme.button.text, 0.35)
          : Qt.alpha(theme.button.background, 0.6)
        border.color: theme.button.border
        border.width: ScalerService.s(2)

        CustomText {
          anchors.centerIn: parent
          name: lang?.wifi?.ip_static || "Static IP"
          size: "small"
          isBold: root.useStatic
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.useStatic = true;
            root.prefillStaticFields();
          }
        }
      }
    }

    CustomText {
      visible: !root.useStatic
      name: lang?.wifi?.ip_dhcp_hint || "IP address, gateway, and DNS are assigned automatically by the router."
      size: "xs"
      textColor: theme.primary.dim_foreground
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    ColumnLayout {
      id: staticFields
      Layout.fillWidth: true
      spacing: ScalerService.s(8)
      visible: root.useStatic

      CustomText {
        name: lang?.wifi?.ip_address || "IP Address"
        size: "xs"
        textColor: theme.primary.dim_foreground
      }

      TextField {
        id: staticIpField
        Layout.fillWidth: true
        text: root.staticIp
        placeholderText: "192.168.0.100"
        color: theme.primary.foreground
        font.family: "ComicShannsMono Nerd Font"
        font.pixelSize: ScalerService.s(13)
        padding: ScalerService.s(8)
        selectByMouse: true
        background: Rectangle {
          radius: ScalerService.s(8)
          color: theme.primary.background
          border.color: theme.button.border
          border.width: ScalerService.s(2)
        }
        onTextChanged: if (text !== root.staticIp) root.staticIp = text
      }

      CustomText {
        name: lang?.wifi?.subnet_prefix || "Subnet Prefix"
        size: "xs"
        textColor: theme.primary.dim_foreground
      }

      TextField {
        id: staticPrefixField
        Layout.fillWidth: true
        text: root.staticPrefix
        placeholderText: "24"
        color: theme.primary.foreground
        font.family: "ComicShannsMono Nerd Font"
        font.pixelSize: ScalerService.s(13)
        padding: ScalerService.s(8)
        selectByMouse: true
        background: Rectangle {
          radius: ScalerService.s(8)
          color: theme.primary.background
          border.color: theme.button.border
          border.width: ScalerService.s(2)
        }
        onTextChanged: if (text !== root.staticPrefix) root.staticPrefix = text
      }

      CustomText {
        name: lang?.wifi?.gateway || "Gateway"
        size: "xs"
        textColor: theme.primary.dim_foreground
      }

      TextField {
        id: staticGatewayField
        Layout.fillWidth: true
        text: root.staticGateway
        placeholderText: "192.168.0.1"
        color: theme.primary.foreground
        font.family: "ComicShannsMono Nerd Font"
        font.pixelSize: ScalerService.s(13)
        padding: ScalerService.s(8)
        selectByMouse: true
        background: Rectangle {
          radius: ScalerService.s(8)
          color: theme.primary.background
          border.color: theme.button.border
          border.width: ScalerService.s(2)
        }
        onTextChanged: if (text !== root.staticGateway) root.staticGateway = text
      }

      CustomText {
        name: lang?.wifi?.primary_dns || "Primary DNS"
        size: "xs"
        textColor: theme.primary.dim_foreground
      }

      TextField {
        id: primaryDnsField
        Layout.fillWidth: true
        text: root.primaryDns
        placeholderText: "1.1.1.1"
        color: theme.primary.foreground
        font.family: "ComicShannsMono Nerd Font"
        font.pixelSize: ScalerService.s(13)
        padding: ScalerService.s(8)
        selectByMouse: true
        background: Rectangle {
          radius: ScalerService.s(8)
          color: theme.primary.background
          border.color: theme.button.border
          border.width: ScalerService.s(2)
        }
        onTextChanged: if (text !== root.primaryDns) root.primaryDns = text
      }

      CustomText {
        name: lang?.wifi?.secondary_dns || "Secondary DNS (optional)"
        size: "xs"
        textColor: theme.primary.dim_foreground
      }

      TextField {
        id: secondaryDnsField
        Layout.fillWidth: true
        text: root.secondaryDns
        placeholderText: "8.8.8.8"
        color: theme.primary.foreground
        font.family: "ComicShannsMono Nerd Font"
        font.pixelSize: ScalerService.s(13)
        padding: ScalerService.s(8)
        selectByMouse: true
        background: Rectangle {
          radius: ScalerService.s(8)
          color: theme.primary.background
          border.color: theme.button.border
          border.width: ScalerService.s(2)
        }
        onTextChanged: if (text !== root.secondaryDns) root.secondaryDns = text
      }

      CustomRectangle {
        Layout.fillWidth: true
        implicitHeight: ScalerService.s(38)
        radius: ScalerService.s(10)
        color: theme.button.text
        border.color: theme.button.border
        border.width: ScalerService.s(2)
        opacity: wifiManager.networkApplying ? 0.6 : 1

        CustomText {
          anchors.centerIn: parent
          name: wifiManager.networkApplying
            ? (lang?.wifi?.applying_ip || "Applying settings...")
            : (lang?.wifi?.apply_static_ip || "Apply Static IP")
          size: "small"
          isBold: true
          textColor: theme.primary.background
        }

        MouseArea {
          anchors.fill: parent
          enabled: !wifiManager.networkApplying
                    && root.staticIp.trim() !== ""
                    && root.staticGateway.trim() !== ""
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: wifiManager.applyStaticIpv4(
            root.staticIp.trim(),
            root.staticPrefix.trim() || "24",
            root.staticGateway.trim(),
            root.primaryDns.trim(),
            root.secondaryDns.trim()
          )
        }
      }
    }
  }

  Component.onCompleted: root.syncFromConnection()
  onVisibleChanged: if (visible) root.syncFromConnection()
}