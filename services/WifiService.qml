import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: wifiManager

  property var wifiList: []
  property bool wifiEnabled: true
  property string connectedWifi: "Not connected"
  property bool isScanning: false
  property string openSsid: ""     // SSID đang mở hộp mật khẩu
  property bool userTyping: false  // true khi đang nhập password
  property bool enabled: false
  property string connectionError: ""
  property string currentPassword: ""
  property string requestedSsid: ""
  property bool networkApplying: false
  property var connectionDetails: ({
      connected: false,
      ssid: "",
      device: "",
      ip: "",
      gateway: "",
      dns: [],
      dnsText: "-",
      signal: 0,
      signalText: "-",
      frequency: "",
      channel: "",
      bssid: "",
      security: "",
      rate: "",
      mac: "",
      ipv4Method: "auto",
      staticIp: "",
      staticPrefix: "24",
      staticGateway: "",
      dnsAuto: true,
      customDns: []
  })

  // =============================
  //   WIFI PROCESS HANDLERS
  // =============================
  Process {
    id: getPasswordProcess
    stdout: StdioCollector {
      onStreamFinished: {
        if (this.text) {
          wifiManager.currentPassword = this.text.trim();
        } else {
          wifiManager.currentPassword = "";
        }
      }
    }
  }
  Process {
    id: wifiToggleProcess
    onRunningChanged: if (!running) {
      checkWifiStatus();
      if (wifiEnabled)
      scanWifiNetworks();
    }
  }

  Process {
    id: wifiStatusProcess
    command: ["nmcli", "radio", "wifi"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (this.text) {
          wifiManager.wifiEnabled = (this.text.trim() === "enabled");
        }
      }
    }
  }

  Process {
    id: connectionDetailsProcess
    command: ["bash", "-c", ""]
    stdout: StdioCollector {
      onStreamFinished: {
        if (this.text) {
          wifiManager.parseConnectionDetails(this.text);
        }
      }
    }
  }

  Process {
    id: networkApplyProcess
    onRunningChanged: {
      wifiManager.networkApplying = running;
      if (!running) {
        Qt.callLater(function () {
            wifiManager.refreshConnectionDetails();
            wifiManager.checkConnectedWifi();
        });
      }
    }
  }

  Timer {
    id: scanFeedbackTimer
    interval: 900
    onTriggered: wifiManager.finishScanFeedback()
  }

  Process {
    id: wifiScanProcess

    command: ["bash", "-c", wifiManager.wifiListScript()]

    onRunningChanged: if (!running)
      wifiManager.finishScanFeedback()

    stdout: StdioCollector {
      onStreamFinished: {
        if (this.text)
          parseWifiList(this.text);
      }
    }
  }

  Process {
    id: wifiConnectProcess
    stdout: SplitParser {
      splitMarker: "\n"
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text && this.text.includes("Error")) {
          wifiManager.connectionError = "Wrong password or unable to connect";
          forgetPassword(wifiManager.requestedSsid);
        }
      }
    }
    onRunningChanged: {
      if (!running) {
        Qt.callLater(function () {
            checkConnectedWifi();
            refreshConnectionDetails();
        });
      }
    }
  }

  Process {
    id: connectedWifiProcess
    command: ["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (this.text) {
          const lines = this.text.trim().split('\n');
          for (var i = 0; i < lines.length; i++) {
            var conn = lines[i];
            if (conn && conn !== "lo" && !conn.startsWith("Wired")) {
              wifiManager.connectedWifi = conn;
              return;
            }
          }
          wifiManager.connectedWifi = "Not connected";
        }
      }
    }
  }

  // =============================
  //   WIFI FUNCTIONS
  // =============================
  function checkWifiStatus() {
    if (!wifiStatusProcess.running)
    wifiStatusProcess.running = true;
  }

  function wifiListScript() {
    return 'printf "%s\\n" "SSID|SIGNAL|SECURITY|FREQ|CHAN|RATE|PASSWORD"; ' +
      'nmcli -t -f SSID,SIGNAL,SECURITY,FREQ,CHAN,RATE device wifi list | awk -F: \'{print $1"|"$2"|"$3"|"$4"|"$5"|"$6}\' | ' +
      'while IFS="|" read -r SSID SIGNAL SECURITY FREQ CHAN RATE; do ' +
      'PASS=$(nmcli -s -g 802-11-wireless-security.psk connection show "$SSID" 2>/dev/null); ' +
      '[ -z "$PASS" ] && PASS="--"; ' +
      'printf "%s|%s|%s|%s|%s|%s|%s\\n" "$SSID" "$SIGNAL" "$SECURITY" "$FREQ" "$CHAN" "$RATE" "$PASS"; ' +
      'done';
  }

  function finishScanFeedback() {
    if (!wifiScanProcess.running && !scanFeedbackTimer.running)
      wifiManager.isScanning = false;
  }

  function scanWifiNetworks(forceRescan, silent) {
    if (!wifiManager.wifiEnabled)
      return;

    const rescan = forceRescan === true
    const quiet = silent === true

    if (wifiScanProcess.running) {
      if (!rescan)
        return;
      wifiScanProcess.running = false;
    }

    if (!quiet) {
      wifiManager.isScanning = true;
      scanFeedbackTimer.restart();
    }

    var script = wifiManager.wifiListScript();
    if (rescan)
      script = "nmcli device wifi rescan 2>/dev/null; sleep 1; " + script;

    wifiScanProcess.command = ["bash", "-c", script];
    wifiScanProcess.running = true;
  }

  function toggleWifi() {
    var cmd = wifiManager.wifiEnabled ? "off" : "on";
    wifiToggleProcess.command = ["nmcli", "radio", "wifi", cmd];
    wifiToggleProcess.running = true;
  }

  function connectToWifi(ssid, password) {
    wifiManager.connectionError = "";
    wifiManager.requestedSsid = ssid;

    if (password) {
      wifiConnectProcess.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
    } else {
      wifiConnectProcess.command = ["nmcli", "device", "wifi", "connect", ssid];
    }
    wifiConnectProcess.running = true;
  }

  function getSavedPassword(ssid) {
    // Lấy mật khẩu từ NetworkManager
    wifiManager.requestedSsid = ssid;
    getPasswordProcess.command = ["nmcli", "-s", "-g", "802-11-wireless-security.psk", "connection", "show", ssid];
    getPasswordProcess.running = true;

    // Trả về mật khẩu hiện tại (có thể rỗng nếu đang loading)
    return wifiManager.currentPassword;
  }

  function forgetPassword(ssid) {
    var forgetProcess = Qt.createQmlObject('import Quickshell.Io; Process {}', wifiManager);
    forgetProcess.command = ["nmcli", "connection", "delete", ssid];
    forgetProcess.running = true;
  }

  function disconnectWifi() {
    wifiConnectProcess.command = ["nmcli", "device", "disconnect"];
    wifiConnectProcess.running = true;
    wifiManager.connectedWifi = "Not connected";
  }

  function checkConnectedWifi() {
    if (!connectedWifiProcess.running)
    connectedWifiProcess.running = true;
  }

  function signalLabel(signal) {
    if (signal >= 80) return "Excellent";
    if (signal >= 65) return "Good";
    if (signal >= 45) return "Fair";
    if (signal > 0) return "Weak";
    return "-";
  }

  function formatFrequency(freq) {
    if (!freq || freq === "")
      return "-";
    var mhz = parseInt(freq);
    if (isNaN(mhz))
      return freq;
    if (mhz >= 5000)
      return (mhz / 1000).toFixed(2) + " GHz (5 GHz)";
    return (mhz / 1000).toFixed(2) + " GHz (2.4 GHz)";
  }

  function refreshConnectionDetails() {
    if (!wifiManager.wifiEnabled || connectionDetailsProcess.running)
      return;

    connectionDetailsProcess.command = ["bash", "-c",
      'DEV=$(nmcli -t -f DEVICE,TYPE device status | awk -F: \'$2=="wifi"{print $1; exit}\'); ' +
      'if [ -z "$DEV" ]; then echo "CONNECTED:false"; exit 0; fi; ' +
      'echo "CONNECTED:true"; ' +
      'nmcli -t device show "$DEV"; ' +
      'echo "__AP__"; ' +
      'nmcli -t -f ACTIVE,SSID,BSSID,SIGNAL,FREQ,CHAN,RATE,SECURITY device wifi list | grep "^yes:" | head -1; ' +
      'echo "__DNS__"; ' +
      'CONN=$(nmcli -t -f GENERAL.CONNECTION device show "$DEV" | head -1 | cut -d: -f2-); ' +
      'nmcli -t -f ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns,ipv4.ignore-auto-dns connection show "$CONN" 2>/dev/null'
    ];
    connectionDetailsProcess.running = true;
  }

  function parseConnectionDetails(text) {
    var details = {
      connected: false,
      ssid: "",
      device: "",
      ip: "",
      gateway: "",
      dns: [],
      dnsText: "-",
      signal: 0,
      signalText: "-",
      frequency: "",
      channel: "",
      bssid: "",
      security: "",
      rate: "",
      mac: "",
      ipv4Method: "auto",
      staticIp: "",
      staticPrefix: "24",
      staticGateway: "",
      dnsAuto: true,
      customDns: []
    };

    var section = "device";
    var lines = text.trim().split('\n');

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line === "__AP__") {
        section = "ap";
        continue;
      }
      if (line === "__DNS__") {
        section = "dns";
        continue;
      }
      if (line === "CONNECTED:false") {
        wifiManager.connectionDetails = details;
        return;
      }
      if (line === "CONNECTED:true") {
        details.connected = true;
        continue;
      }

      if (section === "device") {
        if (line.indexOf("GENERAL.DEVICE:") === 0)
          details.device = line.split(":").slice(1).join(":");
        if (line.indexOf("GENERAL.CONNECTION:") === 0)
          details.ssid = line.split(":").slice(1).join(":");
        if (line.indexOf("GENERAL.HWADDR:") === 0)
          details.mac = line.split(":").slice(1).join(":");
        if (line.indexOf("IP4.ADDRESS") === 0)
          details.ip = line.split(":").slice(1).join(":");
        if (line.indexOf("IP4.GATEWAY:") === 0)
          details.gateway = line.split(":").slice(1).join(":");
        if (line.indexOf("IP4.DNS") === 0) {
          var dnsValue = line.split(":").slice(1).join(":");
          if (dnsValue)
            details.dns.push(dnsValue);
        }
      } else if (section === "ap" && line.indexOf("yes:") === 0) {
        var apParts = line.substring(4).split(":");
        if (apParts.length >= 7) {
          details.ssid = apParts[0] || details.ssid;
          details.bssid = apParts.slice(1, 7).join(":").replace(/\\:/g, ":");
          details.signal = parseInt(apParts[7]) || details.signal;
          details.frequency = formatFrequency(apParts[8] || "");
          details.channel = apParts[9] || "";
          details.rate = apParts[10] || "";
          details.security = apParts[11] || details.security;
        }
      } else if (section === "dns") {
        if (line.indexOf("ipv4.method:") === 0)
          details.ipv4Method = line.split(":").slice(1).join(":") || "auto";
        if (line.indexOf("ipv4.addresses:") === 0) {
          var addressValue = line.split(":").slice(1).join(":");
          if (addressValue && addressValue.indexOf("/") >= 0) {
            var addressParts = addressValue.split("/");
            details.staticIp = addressParts[0];
            details.staticPrefix = addressParts[1] || "24";
          }
        }
        if (line.indexOf("ipv4.gateway:") === 0) {
          var gatewayValue = line.split(":").slice(1).join(":");
          if (gatewayValue)
            details.staticGateway = gatewayValue;
        }
        if (line.indexOf("ipv4.ignore-auto-dns:") === 0)
          details.dnsAuto = line.split(":")[1] !== "yes";
        if (line.indexOf("ipv4.dns") === 0) {
          var custom = line.split(":").slice(1).join(":");
          if (custom)
            details.customDns.push(custom);
        }
      }
    }

    if (details.dns.length > 0)
      details.dnsText = details.dns.join(", ");
    if (details.signal > 0)
      details.signalText = details.signal + "% (" + signalLabel(details.signal) + ")";
    if (details.ipv4Method === "manual" && details.customDns.length > 0)
      details.dnsText = details.customDns.join(", ");
    else if (details.ipv4Method === "manual" && details.dns.length > 0)
      details.dnsText = details.dns.join(", ");

    wifiManager.connectionDetails = details;
  }

  function connectionName() {
    var conn = wifiManager.connectionDetails.ssid || wifiManager.connectedWifi;
    if (!conn || conn === "Not connected")
      return "";
    return conn;
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'";
  }

  function setIpv4Dhcp() {
    var conn = connectionName();
    if (!conn)
      return;

    networkApplyProcess.command = ["bash", "-c",
      "nmcli connection modify " + shellQuote(conn) +
      " ipv4.method auto ipv4.addresses '' ipv4.gateway '' ipv4.dns '' ipv4.ignore-auto-dns no && " +
      "nmcli connection up " + shellQuote(conn)
    ];
    networkApplyProcess.running = true;
  }

  function applyStaticIpv4(ip, prefix, gateway, primaryDns, secondaryDns) {
    var conn = connectionName();
    if (!conn || !ip || !gateway)
      return;

    var address = ip + "/" + (prefix || "24");
    var dnsArg = "";
    if (primaryDns) {
      dnsArg = primaryDns;
      if (secondaryDns)
        dnsArg += "," + secondaryDns;
    }

    var cmd = "nmcli connection modify " + shellQuote(conn) +
      " ipv4.method manual ipv4.addresses " + shellQuote(address) +
      " ipv4.gateway " + shellQuote(gateway);

    if (dnsArg !== "")
      cmd += " ipv4.dns " + shellQuote(dnsArg) + " ipv4.ignore-auto-dns yes";
    else
      cmd += " ipv4.dns '' ipv4.ignore-auto-dns no";

    cmd += " && nmcli connection up " + shellQuote(conn);

    networkApplyProcess.command = ["bash", "-c", cmd];
    networkApplyProcess.running = true;
  }

  function parseWifiList(text) {
    var lines = text.trim().split('\n');
    var networksMap = {};

    for (var i = 1; i < lines.length; i++) {
      var line = lines[i].trim();
      if (!line || line.indexOf("|") < 0)
        continue;

      var parts = line.split("|");
      if (parts.length < 6)
        continue;

      var ssid = parts[0].trim();
      var signal = parseInt(parts[1].trim()) || 0;
      var security = parts[2].trim() || "Open";
      var freq = parts[3].trim();
      var channel = parts[4].trim();
      var rate = parts[5].trim();
      var saved_password = parts.length >= 7 ? parts[6].trim() : "--";

      if (ssid && ssid !== "--" && ssid !== "SSID") {
        if (!networksMap[ssid] || signal > networksMap[ssid].signal) {
          networksMap[ssid] = {
            ssid: ssid,
            signal: signal,
            signalLabel: signalLabel(signal),
            security: security,
            frequency: formatFrequency(freq),
            channel: channel,
            rate: rate,
            isConnected: ssid === wifiManager.connectedWifi,
            saved_password: saved_password
          };
        }
      }
    }

    var networks = Object.values(networksMap).sort((a, b) => b.signal - a.signal);
    wifiManager.wifiList = networks;
  }

  // =============================
  //   AUTO REFRESH
  // =============================
  Component.onCompleted: start()

  Timer {
    interval: 10000
    running: wifiManager.enabled
    repeat: true
    onTriggered: {
      if (wifiManager.userTyping)
        return;

      checkWifiStatus();
      checkConnectedWifi();
      refreshConnectionDetails();

      if (wifiManager.wifiEnabled)
        scanWifiNetworks(false, true);
    }
  }

  Timer {
    interval: 30000
    running: wifiManager.enabled && wifiManager.wifiEnabled
    repeat: true
    onTriggered: {
      if (wifiManager.userTyping || wifiScanProcess.running)
        return;

      scanWifiNetworks(true, true);
    }
  }

  function start() {
    enabled = true;
    checkWifiStatus();
    checkConnectedWifi();
    refreshConnectionDetails();

    Qt.callLater(function () {
      if (!wifiManager.wifiEnabled)
        return;

      const needsRescan = wifiManager.wifiList.length === 0;
      scanWifiNetworks(needsRescan, true);
    });
  }

  // Hàm dừng manager
  function stop() {
    enabled = false;

    wifiStatusProcess.running = false;
    wifiScanProcess.running = false;
    wifiConnectProcess.running = false;
    connectedWifiProcess.running = false;
    wifiToggleProcess.running = false;

    isScanning = false;
    userTyping = false;
    openSsid = "";
  }
}
