pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons
import qs.services

Singleton {
  id: root

  readonly property string themesDirectory: Quickshell.shellDir + "/assets/themes"
  readonly property string stateFilePath: Directories.shellConfigColoursPath
  readonly property string matugenFilePath: Directories.assetsPath + "/themes/matugen.json"

  property list<string> themeFiles: []
  property bool loading: false
  property alias palette: adapter

  // Theme property - sẽ chứa theme theo format mới
  property var theme: getFallbackTheme()
  property bool themeTransitioning: false
  property real themeTransition: 1
  property bool _themeReady: false
  property var _transitionFrom: null
  property var _transitionTarget: null
  property var _lastMatugenJson: null
  property var _pendingRefreshReasons: []

  readonly property bool isInitialized: true

  NumberAnimation {
    id: themeTransitionAnim
    target: root
    property: "themeTransition"
    from: 0
    to: 1
    duration: 280
    easing.type: Easing.OutCubic
    onStarted: {
      root.themeTransitioning = true;
      root._transitionFrom = root.cloneTheme(root.theme);
    }
    onStopped: root.finishThemeTransition()
  }

  onThemeTransitionChanged: {
    if (!root.themeTransitioning || !root._transitionTarget)
      return;
    root.theme = root.blendThemes(
      root._transitionFrom,
      root._transitionTarget,
      root.themeTransition
    );
  }
  property Timer reloadTimer: Timer {
    interval: 200
    repeat: false
    onTriggered: {
      root.refresh();
    }
  }

  Timer {
    id: refreshCoalesce
    interval: 24
    repeat: false
    onTriggered: root.performRefresh()
  }

  signal themeReloaded

  readonly property list<string> validMatugenSchemes: ["scheme-content", "scheme-expressive", "scheme-fidelity", "scheme-fruit-salad", "scheme-monochrome", "scheme-neutral", "scheme-rainbow", "scheme-tonal-spot", "scheme-vibrant"]

  readonly property var matugenMap: ({
      primary: "mPrimary",
      on_primary: "mOnPrimary",
      primary_container: "mPrimaryContainer",
      on_primary_container: "mOnPrimaryContainer",
      secondary: "mSecondary",
      on_secondary: "mOnSecondary",
      tertiary: "mTertiary",
      on_tertiary: "mOnTertiary",
      background: "mBackground",
      on_background: "mOnBackground",
      surface: "mSurface",
      on_surface: "mOnSurface",
      surface_variant: "mSurfaceVariant",
      on_surface_variant: "mOnSurfaceVariant",
      surface_container: "mSurfaceContainer",
      surface_container_low: "mSurfaceContainerLow",
      surface_container_high: "mSurfaceContainerHigh",
      surface_container_highest: "mSurfaceContainerHighest",
      surface_tint: "mSurfaceTint",
      outline: "mOutline",
      shadow: "mShadow",
      error: "mError",
      on_error: "mOnError",
      error_container: "mErrorContainer",
      on_error_container: "mOnErrorContainer"
  })

  // Thêm map cho theme mới sang Material Design 3
  readonly property var themeToMaterialMap: ({
      "primary.background": "mBackground",
      "primary.foreground": "mOnBackground",
      "primary.dim_background": "mSurfaceContainerLow",
      "primary.dim_foreground": "mOnSurfaceVariant",
      "primary.bright_foreground": "mPrimary",
      "button.background": "mSurfaceVariant",
      "button.text": "mPrimary",
      "button.background_select": "mOutline",
      "button.border": "mOutline",
      "button.border_select": "mOutline",
      "normal.red": "mError",
      "normal.green": "mPrimary",
      "normal.yellow": "mTertiary",
      "normal.cyan": "mTertiary",
      "normal.white": "mOnSurface",
      "bright.red": "mError",
      "bright.green": "mPrimary",
      "bright.yellow": "mTertiary",
      "bright.cyan": "mTertiary",
      "bright.white": "mOnSurface"
  })

  function init() {
    root.loading = true;

    // First find all theme files
    findProcess.running = true;
  }

  // Đổi tên hàm này để tránh trùng
  function loadThemeFile() {
    // Alias cho compatibility
    root.refresh();
  }

  function changeTheme(newTheme) {
    if (newTheme !== Settings.appearance.theme) {
      Settings.appearance.theme = newTheme;
      // If theme is matugen, set dynamic to true
      Settings.appearance.dynamic = (newTheme === "matugen");
    }
    return root.theme;
  }

  function isDarkAppearance() {
    if (root.theme && root.theme.type)
      return root.theme.type === "dark";
    return Settings.appearance.mode !== "light";
  }

  function menuItemBackground(active) {
    const palette = root.theme;
    if (!palette)
      return "transparent";

    if (isDarkAppearance()) {
      if (active)
        return Qt.alpha(palette.button.text, 0.16);
      return Qt.alpha(palette.primary.foreground, 0.05);
    }

    if (active)
      return Qt.alpha(palette.button.background_select, 0.6);
    return Qt.alpha(palette.button.background, 0.6);
  }

  function menuItemBorder(active) {
    const palette = root.theme;
    if (!palette)
      return "transparent";

    if (isDarkAppearance()) {
      if (active)
        return Qt.alpha(palette.button.text, 0.42);
      return Qt.alpha(palette.button.border, 0.28);
    }

    if (active)
      return palette.button.border_select;
    return palette.button.border;
  }

  function menuItemText(active) {
    const palette = root.theme;
    if (!palette)
      return "#ffffff";

    if (active)
      return palette.primary.bright_foreground;
    return palette.primary.foreground;
  }

  function getStaticFallbackThemeName() {
    return Settings.appearance.mode === "light"
      ? (Settings.appearance.light || "gruvbox")
      : (Settings.appearance.dark || "macchiato");
  }

  function parseMatugenJsonText(text) {
    if (!text)
      return null;

    var trimmed = text.trim();
    if (trimmed.endsWith("ok"))
      trimmed = trimmed.slice(0, -2).trim();

    try {
      return JSON.parse(trimmed);
    } catch (e) {
      try {
        var okIndex = trimmed.indexOf("\nok");
        if (okIndex >= 0)
          trimmed = trimmed.substring(0, okIndex).trim();
        return JSON.parse(trimmed);
      } catch (e2) {
        console.error("Matugen JSON parse error:", e, e2);
        return null;
      }
    }
  }

  function resolveWallpaper() {
    var wallpaper = "";

    for (let i = 0; i < Quickshell.screens.length; i++) {
      if (Quickshell.screens[i].primary) {
        wallpaper = WallpaperService.getWallpaper(Quickshell.screens[i].name);
        break;
      }
    }

    if (!wallpaper && Quickshell.screens.length > 0) {
      wallpaper = WallpaperService.getWallpaper(Quickshell.screens[0].name);
    }

    if (!wallpaper || wallpaper === "") {
      wallpaper = Settings.wallpaper.defaultWallpaper || "";
    }

    return wallpaper;
  }

  function cloneTheme(source) {
    if (!source)
      return null;
    try {
      return JSON.parse(JSON.stringify(source));
    } catch (e) {
      return source;
    }
  }

  function parseHexColor(color) {
    if (!color || typeof color !== "string")
      return null;

    var hex = color.trim();
    if (!hex.startsWith("#"))
      return null;

    hex = hex.substring(1);
    if (hex.length === 3) {
      hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
    }
    if (hex.length !== 6)
      return null;

    return {
      r: parseInt(hex.substring(0, 2), 16),
      g: parseInt(hex.substring(2, 4), 16),
      b: parseInt(hex.substring(4, 6), 16)
    };
  }

  function toHexChannel(value) {
    var channel = Math.max(0, Math.min(255, Math.round(value)));
    var hex = channel.toString(16);
    return hex.length === 1 ? "0" + hex : hex;
  }

  function lerpHexColor(fromColor, toColor, progress) {
    var fromRgb = parseHexColor(fromColor);
    var toRgb = parseHexColor(toColor);

    if (!fromRgb && !toRgb)
      return fromColor || toColor || "#000000";
    if (!fromRgb)
      return toColor;
    if (!toRgb)
      return fromColor;

    var t = Math.max(0, Math.min(1, progress));
    return "#"
      + toHexChannel(fromRgb.r + (toRgb.r - fromRgb.r) * t)
      + toHexChannel(fromRgb.g + (toRgb.g - fromRgb.g) * t)
      + toHexChannel(fromRgb.b + (toRgb.b - fromRgb.b) * t);
  }

  function blendValue(fromValue, toValue, progress) {
    if (typeof toValue === "string" && toValue.startsWith("#"))
      return lerpHexColor(fromValue, toValue, progress);

    if (toValue && typeof toValue === "object" && !Array.isArray(toValue)) {
      var blended = {};
      for (var key in toValue)
        blended[key] = blendValue(fromValue ? fromValue[key] : null, toValue[key], progress);
      return blended;
    }

    return toValue;
  }

  function blendThemes(fromTheme, toTheme, progress) {
    if (!fromTheme)
      return cloneTheme(toTheme);
    if (!toTheme)
      return cloneTheme(fromTheme);
    return blendValue(fromTheme, toTheme, progress);
  }

  function applyPaletteFromThemeData(data) {
    if (!data)
      return;

    if (data.type && data.primary && data.normal) {
      var materialData = mapThemeToMaterial(data);
      var changed = false;
      for (const key in materialData) {
        if (palette.hasOwnProperty(key) && palette[key] !== materialData[key]) {
          palette[key] = materialData[key];
          changed = true;
        }
      }
      if (changed)
        stateFileView.writeAdapter();
      return;
    }

    var paletteChanged = false;
    for (const key in data) {
      if (palette.hasOwnProperty(key) && palette[key] !== data[key]) {
        palette[key] = data[key];
        paletteChanged = true;
      }
    }
    if (paletteChanged) {
      stateFileView.writeAdapter();
      createMatugenJsonFile();
    }
  }

  function startThemeTransition(targetTheme) {
    if (!targetTheme) {
      root.loading = false;
      return;
    }

    if (themeTransitionAnim.running)
      themeTransitionAnim.stop();

    root._transitionTarget = cloneTheme(targetTheme);
    root.themeTransition = 0;
    themeTransitionAnim.start();
  }

  function finishThemeTransition() {
    if (!root._transitionTarget) {
      root.themeTransitioning = false;
      root.loading = false;
      return;
    }

    root._currentTheme = cloneTheme(root._transitionTarget);
    root.theme = cloneTheme(root._transitionTarget);
    root.applyPaletteFromThemeData(root._transitionTarget);
    root.themeTransition = 1;
    root.themeTransitioning = false;
    root._transitionFrom = null;
    root._transitionTarget = null;
    root.loading = false;
    themeReloaded();
  }

  function commitThemeData(data) {
    if (!data) {
      root.loading = false;
      return;
    }

    if (data.type && data.primary && data.normal) {
      root._currentTheme = cloneTheme(data);
      if (root._themeReady)
        root.startThemeTransition(data);
      else {
        root.theme = cloneTheme(data);
        root.applyPaletteFromThemeData(data);
        root._themeReady = true;
        root.loading = false;
        themeReloaded();
      }
      return;
    }

    root.applyPaletteFromThemeData(data);
    root._currentTheme = null;
    var paletteTheme = getThemeFromPalette();
    root._currentTheme = paletteTheme;
    if (root._themeReady)
      root.startThemeTransition(paletteTheme);
    else {
      root.theme = paletteTheme;
      root._themeReady = true;
      root.loading = false;
      themeReloaded();
    }
  }

  function getFallbackTheme() {
    return {
      "type": "dark",
      "primary": {
        "background": "#13140d",
        "foreground": "#e5e3d6",
        "dim_background": "#101410",
        "dim_foreground": "#b1cead",
        "bright_foreground": "#92d792"
      },
      "button": {
        "background": "#41493f",
        "text": "#92d792",
        "background_select": "#8a9387",
        "border": "#c0c9bc",
        "border_select": "#c0c9bc"
      },
      "cursor": {
        "cursor": "#cad3f5",
        "text": "#24273a"
      },
      "normal": {
        "black": "#494d64",
        "red": "#ed8796",
        "green": "#a6da95",
        "yellow": "#eed49f",
        "blue": "#8aadf4",
        "magenta": "#f5bde6",
        "cyan": "#8bd5ca",
        "white": "#b8c0e0"
      },
      "bright": {
        "black": "#5b6078",
        "red": "#ed8796",
        "green": "#a6da95",
        "yellow": "#eed49f",
        "blue": "#8aadf4",
        "magenta": "#f5bde6",
        "cyan": "#8bd5ca",
        "white": "#a5adcb"
      }
    };
  }

  function getThemeFromPalette() {
    // Chuyển đổi từ Material Design 3 sang theme format mới
    var currentMode = Settings.appearance.mode || "dark";

    // Nếu đã có theme mới được load, trả về nó
    if (root._currentTheme && root._currentTheme.type) {
      return root._currentTheme;
    }

    // Fallback: tạo theme từ palette
    return {
      "type": currentMode,
      "primary": {
        "background": adapter.mBackground ? adapter.mBackground.toString() : "#13140d",
        "foreground": adapter.mOnBackground ? adapter.mOnBackground.toString() : "#e5e3d6",
        "dim_background": adapter.mSurfaceContainerLow ? adapter.mSurfaceContainerLow.toString() : "#101410",
        "dim_foreground": adapter.mOnSurfaceVariant ? adapter.mOnSurfaceVariant.toString() : "#b1cead",
        "bright_foreground": adapter.mPrimary ? adapter.mPrimary.toString() : "#92d792"
      },
      "button": {
        "background": adapter.mSurfaceVariant ? adapter.mSurfaceVariant.toString() : "#41493f",
        "text": adapter.mPrimary ? adapter.mPrimary.toString() : "#92d792",
        "background_select": adapter.mOutline ? adapter.mOutline.toString() : "#8a9387",
        "border": adapter.mOnSurfaceVariant ? adapter.mOnSurfaceVariant.toString() : "#c0c9bc",
        "border_select": adapter.mOnSurfaceVariant ? adapter.mOnSurfaceVariant.toString() : "#c0c9bc"
      },
      "cursor": {
        "cursor": "#cad3f5",
        "text": "#24273a"
      },
      "normal": {
        "black": "#494d64",
        "red": adapter.mError ? adapter.mError.toString() : "#ed8796",
        "green": adapter.mPrimary ? adapter.mPrimary.toString() : "#a6da95",
        "yellow": adapter.mTertiary ? adapter.mTertiary.toString() : "#eed49f",
        "blue": "#8aadf4",
        "magenta": "#f5bde6",
        "cyan": adapter.mTertiary ? adapter.mTertiary.toString() : "#8bd5ca",
        "white": adapter.mOnSurface ? adapter.mOnSurface.toString() : "#b8c0e0"
      },
      "bright": {
        "black": "#5b6078",
        "red": adapter.mError ? adapter.mError.toString() : "#ed8796",
        "green": adapter.mPrimary ? adapter.mPrimary.toString() : "#a6da95",
        "yellow": adapter.mTertiary ? adapter.mTertiary.toString() : "#eed49f",
        "blue": "#8aadf4",
        "magenta": "#f5bde6",
        "cyan": adapter.mTertiary ? adapter.mTertiary.toString() : "#8bd5ca",
        "white": adapter.mOnSurface ? adapter.mOnSurface.toString() : "#a5adcb"
      }
    };
  }

  function refresh() {
    root.loading = true;
    root._currentTheme = null;

    // Check if theme is matugen or dynamic
    if (Settings.appearance.theme === "matugen" || Settings.appearance.dynamic) {
      generateFromWallpaper(Settings.appearance.mode, Settings.appearance.matugenType);
    } else {
      // Load static theme
      var themeName = Settings.appearance.theme;

      if (themeName && themeName !== "") {
        loadThemeByName(themeName);
      } else {
        // Use fallback theme based on mode
        var fallbackTheme = getStaticFallbackThemeName();
        loadThemeByName(fallbackTheme);
      }
    }
  }

  function loadThemeByName(name) {
    if (!name || name === "") {
      root.loading = false;
      return;
    }

    // First check if it's a built-in theme file
    var path = "";

    // Check if file exists in themes directory
    for (var i = 0; i < themeFiles.length; i++) {
      var fileName = themeFiles[i].split("/").pop().replace(".json", "");
      if (fileName === name) {
        path = themeFiles[i];
        break;
      }
    }

    if (path) {
      themeReader.path = "";
      themeReader.path = path;
    } else {
      var staticFallback = getStaticFallbackThemeName();
      var staticPath = "";
      for (var j = 0; j < themeFiles.length; j++) {
        var staticName = themeFiles[j].split("/").pop().replace(".json", "");
        if (staticName === staticFallback) {
          staticPath = themeFiles[j];
          break;
        }
      }

      if (staticPath) {
        themeReader.path = "";
        themeReader.path = staticPath;
      } else {
        root.updateColors(getFallbackTheme());
      }
    }
  }

  function updateColors(data) {
    root.commitThemeData(data);
  }

  // Hàm ánh xạ theme mới sang Material Design 3
  function mapThemeToMaterial(themeData) {
    var result = {};

    // Ánh xạ các màu từ theme mới sang Material Design 3
    for (var key in themeToMaterialMap) {
      var materialKey = themeToMaterialMap[key];
      var keys = key.split(".");
      var value = themeData;

      // Lấy giá trị theo path
      for (var i = 0; i < keys.length; i++) {
        if (value && typeof value === 'object') {
          value = value[keys[i]];
        } else {
          value = null;
          break;
        }
      }

      if (value && materialKey) {
        result[materialKey] = value;
      }
    }

    // Set mode-based colors
    var mode = themeData.type || "dark";
    if (mode === "light") {
      // Điều chỉnh một số màu cho light mode nếu cần
      if (!result.mBackground && themeData.primary && themeData.primary.background) {
        result.mBackground = themeData.primary.background;
      }
      if (!result.mOnBackground && themeData.primary && themeData.primary.foreground) {
        result.mOnBackground = themeData.primary.foreground;
      }
    }

    return result;
  }

  function generateFromWallpaper(mode, type) {
    if (!ProgramCheckerService.matugenAvailable) {
      root.loading = false;
      loadThemeByName(getStaticFallbackThemeName());
      return;
    }

    var wallpaper = resolveWallpaper();

    if (!wallpaper || wallpaper === "") {
      root.loading = false;
      loadThemeByName(getStaticFallbackThemeName());
      return;
    }

    const matugenType = validMatugenSchemes.includes(type) ? type : "scheme-tonal-spot";
    const targetMode = mode === "light" ? "light" : "dark";

    generateProcess.command = [
    "matugen",
    "image",
    wallpaper,
    "-j",
    "hex",
    "-m",
    targetMode,
    "--prefer=darkness"
    ];
    generateProcess.running = true;
  }

  function parseMatugenForMode(json, mode) {
    const result = {};
    const colors = json.colors || {};
    const targetMode = mode === "light" ? "light" : "dark";

    for (const key in matugenMap) {
      const colorObj = colors[key];
      var colorValue = null;

      if (colorObj && colorObj[targetMode] && colorObj[targetMode].color) {
        colorValue = colorObj[targetMode].color;
      } else if (colorObj && colorObj.default && colorObj.default.color) {
        colorValue = colorObj.default.color;
      }

      if (colorValue) {
        result[matugenMap[key]] = colorValue;
      } else {
        console.warn("Missing color for key:", key);
      }
    }
    return result;
  }

  function parseMatugen(json) {
    const mode = Settings.appearance.mode === "light" ? "light" : "dark";
    return parseMatugenForMode(json, mode);
  }

  function themeFromMatugenJson(jsonData, mode) {
    if (!jsonData)
      return null;

    var matugenPalette = parseMatugenForMode(jsonData, mode);
    applyPaletteFromThemeData(matugenPalette);
    root._currentTheme = null;
    var paletteTheme = getThemeFromPalette();
    paletteTheme.type = mode === "light" ? "light" : "dark";
    return paletteTheme;
  }

  function cacheMatugenJson(jsonData) {
    if (!jsonData || !jsonData.colors)
      return;

    root._lastMatugenJson = jsonData;
  }

  function applyCachedMatugenMode(mode) {
    if (!root._lastMatugenJson)
      return false;

    var themeData = themeFromMatugenJson(root._lastMatugenJson, mode);
    if (!themeData)
      return false;

    root.commitThemeData(themeData);
    return true;
  }

  function scheduleRefresh(reason) {
    const refreshReason = reason || "general";
    if (root._pendingRefreshReasons.indexOf(refreshReason) < 0)
      root._pendingRefreshReasons.push(refreshReason);
    refreshCoalesce.restart();
  }

  function performRefresh() {
    const reasons = root._pendingRefreshReasons;
    root._pendingRefreshReasons = [];
    const modeOnly = reasons.length === 1 && reasons[0] === "mode";

    if (modeOnly && (Settings.appearance.theme === "matugen" || Settings.appearance.dynamic)) {
      if (applyCachedMatugenMode(Settings.appearance.mode))
        return;
    }

    root.refresh();
  }

  function getDisplayName(path) {
    if (!path)
    return "";
    return path.split("/").pop().replace(/\.json$/i, "").split("-").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
  }

  // Tạo file matugen.json từ palette hiện tại
  function createMatugenJsonFile() {
    const themeData = root.theme;
    const themeJson = JSON.stringify(themeData, null, 2);

    // Create a temporary file and then move it
    var tempFile = "/tmp/matugen_temp_" + Date.now() + ".json";
    var cmd = `echo '${themeJson.replace(/'/g, "'\"'\"'")}' > "${tempFile}" && mv "${tempFile}" "${matugenFilePath}"`;

    try {
      var writeProcess = Qt.createQmlObject(`
        import QtQuick
        import Quickshell.Io
        Process {
        id: writeProcess
        command: ["bash", "-c", "${cmd.replace(/"/g, '\\"')}"]
        onExited: function(exitCode) {
        if (exitCode === 0) {
        console.log("matugen.json created successfully")
      } else {
        console.error("Failed to create matugen.json")
      }
        writeProcess.destroy()
      }
      }
        `, root, "CreateMatugenFileProcess");

      writeProcess.running = true;
    } catch (e) {
      console.error("Error creating matugen.json:", e);
    }
  }

  // Functions cho compatibility với code cũ
  function triggerMatugenOnThemeChange(themeMode) {
    if (!Settings.appearance)
      return;

    Settings.appearance.mode = themeMode;
    Settings.appearance.theme = "matugen";
    Settings.appearance.dynamic = true;
    scheduleRefresh("mode");
  }

  function triggerMatugenOnWallpaperChange(currentWallpaper) {

    if (!currentWallpaper || currentWallpaper === "") {
      return;
    }

    if (Settings.appearance.theme === "matugen" || Settings.appearance.dynamic) {
      root.refresh();
    }
  }

  // Simple connection to Settings changes
  Connections {
    target: Settings

    function onReadyChanged() {
      if (Settings.ready) {
        // When settings are ready, refresh theme
        Qt.callLater(function () {
            root.refresh();
        });
      }
    }
  }

  Connections {
    target: Settings.appearance

    function onThemeChanged() {
      scheduleRefresh("theme");
    }

    function onModeChanged() {
      scheduleRefresh("mode");
    }

    function onDynamicChanged() {
      scheduleRefresh("dynamic");
    }

    function onMatugenTypeChanged() {
      if (Settings.appearance.dynamic || Settings.appearance.theme === "matugen")
        scheduleRefresh("matugenType");
    }
  }

  Connections {
    target: WallpaperService
    function onWallpaperChanged() {
      if (Settings.appearance.dynamic || Settings.appearance.theme === "matugen")
        scheduleRefresh("wallpaper");
    }
  }

  Process {
    id: findProcess
    command: ["find", root.themesDirectory, "-name", "*.json", "-type", "f"]
    onExited: exitCode => {
      if (exitCode === 0) {
        themeFiles = stdout.text.trim().split("\n").filter(Boolean);

        // Now refresh theme based on settings
        if (Settings.ready) {
          root.refresh();
        } else {
          // Wait for settings to be ready
          settingsReadyTimer.start();
        }
      } else {
        root.loading = false;
      }
    }
    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  Timer {
    id: settingsReadyTimer
    interval: 100
    repeat: true
    onTriggered: {
      if (Settings.ready) {
        root.refresh();
        settingsReadyTimer.stop();
      } else {
        console.log("Still waiting for settings...");
      }
    }
  }

  Process {
    id: generateProcess
    workingDirectory: Quickshell.shellDir
    running: false
    onExited: exitCode => {
      if (exitCode === 0) {
        var jsonData = root.parseMatugenJsonText(stdout.text);
        if (jsonData) {
          var resolvedMode = jsonData.mode || (Settings.appearance.mode === "light" ? "light" : "dark");
          root.cacheMatugenJson(jsonData);
          var paletteTheme = root.themeFromMatugenJson(jsonData, resolvedMode);
          root.commitThemeData(paletteTheme);
          root.createMatugenJsonFile();
        } else {
          console.error("Matugen returned invalid output");
          root.loading = false;
          root.loadThemeByName(root.getStaticFallbackThemeName());
        }
      } else {
        console.error("Matugen Error:", stderr.text);
        root.loading = false;
        root.loadThemeByName(root.getStaticFallbackThemeName());
      }
    }
    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  FileView {
    id: themeReader
    onLoaded: {
      try {
        var jsonText = text();
        if (jsonText) {
          root.updateColors(JSON.parse(jsonText));
        } else {
          console.error("Theme file is empty");
          root.loading = false;
        }
      } catch (e) {
        console.error("Theme Load Error:", e);
        root.loading = false;
      }
    }
  }

  FileView {
    id: fallbackThemeReader
    onLoaded: {
      try {
        var jsonText = text();
        if (jsonText) {
          root.updateColors(JSON.parse(jsonText));
        } else {
          console.error("Fallback theme file is empty");
          // Load default fallback theme
          root.updateColors(root.getFallbackTheme());
        }
      } catch (e) {
        console.error("Fallback Theme Load Error:", e);
        // Load default fallback theme
        root.updateColors(root.getFallbackTheme());
      }
    }
  }

  FileView {
    id: stateFileView
    path: root.stateFilePath
    watchChanges: true
    onFileChanged: reload()
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound)
      writeAdapter();
      else
      console.error("State File Error:", error);
    }

    JsonAdapter {
      id: adapter
      property color mPrimary: "#c4cd7b"
      property color mOnPrimary: "#2e3300"
      property color mPrimaryContainer: "#444b05"
      property color mOnPrimaryContainer: "#e0e994"
      property color mSecondary: "#c7c9a7"
      property color mOnSecondary: "#2f321a"
      property color mTertiary: "#a2d0c1"
      property color mOnTertiary: "#06372d"
      property color mBackground: "#13140d"
      property color mOnBackground: "#e5e3d6"
      property color mSurface: "#13140d"
      property color mOnSurface: "#e5e3d6"
      property color mSurfaceVariant: "#47483b"
      property color mOnSurfaceVariant: "#c8c7b7"
      property color mSurfaceTint: "#c4cd7b"
      property color mOutline: "#929282"
      property color mShadow: "#000000"
      property color mError: "#ffb4ab"
      property color mOnError: "#690005"
      property color mErrorContainer: "#93000a"
      property color mOnErrorContainer: "#ffdad6"
      property color mSurfaceContainer: "#202018"
      property color mSurfaceContainerLow: "#1c1c14"
      property color mSurfaceContainerHigh: "#2a2b22"
      property color mSurfaceContainerHighest: "#35352d"
    }
  }

  // Private property để lưu theme hiện tại
  property var _currentTheme: null

  // Thêm Component.onCompleted để tự động gọi init()
  Component.onCompleted: {
    Qt.callLater(function () {
        init();
    });
  }
}
