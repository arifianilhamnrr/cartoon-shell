pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import QtMultimedia
import qs.commons
import qs.services
import qs.utils

Variants {
  id: backgroundVariants
  model: Quickshell.screens

  delegate: Loader {
    id: loader
    required property ShellScreen modelData

    active: modelData && Settings.wallpaper.enabled

    sourceComponent: PanelWindow {
      id: root

      property string futureWallpaper: ""
      property string pendingSource: ""
      property string nextSource: ""
      property bool pendingTransitionStart: false

      property real transitionProgress: 0
      readonly property bool transitioning: transitionAnimation.running
      readonly property bool useTransition: Settings.wallpaper.transitionDuration > 0

      property string currentWallpaperType: "image"
      property string currentSource: ""

      readonly property bool videoMuted: Settings.wallpaper.videoMuted !== undefined ? Settings.wallpaper.videoMuted : true
      readonly property bool videoLoop: Settings.wallpaper.videoLoop !== undefined ? Settings.wallpaper.videoLoop : true
      readonly property real videoPlaybackRate: Settings.wallpaper.videoPlaybackRate !== undefined ? Settings.wallpaper.videoPlaybackRate : 1.0

      readonly property var wallpaperSourceSize: calculateOptimalWallpaperSize(loader.modelData.width, loader.modelData.height)

      color: "transparent"
      screen: loader.modelData
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "quickshell:wallpaper-" + (screen?.name || "unknown")

      anchors {
        bottom: true
        top: true
        right: true
        left: true
      }

      Timer {
        id: debounceTimer
        interval: 333
        running: false
        repeat: false
        onTriggered: root.changeWallpaper()
      }

      Component.onCompleted: setWallpaperInitial()

      Component.onDestruction: {
        transitionAnimation.stop()
        debounceTimer.stop()
        currentImage.source = ""
        currentVideo.source = ""
        nextImage.source = ""
      }

      Connections {
        target: WallpaperService
        function onWallpaperChanged(screenName, path) {
          if (screenName === loader.modelData.name) {
            root.futureWallpaper = path
            debounceTimer.restart()
          }
        }
      }

      Connections {
        target: CompositorService
        function onDisplayScalesChanged() {
          root.setWallpaperInitial()
        }
      }

      Rectangle {
        anchors.fill: parent
        color: Settings.wallpaper.fillColor
        z: 0
      }

      Item {
        id: currentWallpaperContainer
        anchors.fill: parent
        z: 1

        Image {
          id: currentImage
          anchors.fill: parent
          fillMode: Image.PreserveAspectCrop
          smooth: false
          mipmap: false
          cache: true
          asynchronous: true
          sourceSize: root.wallpaperSourceSize
          visible: root.currentWallpaperType === "image"

          onStatusChanged: {
            if (status === Image.Error) {
              console.log("Current wallpaper failed to load:", source)
            }
          }
        }

        Video {
          id: currentVideo
          anchors.fill: parent
          fillMode: VideoOutput.PreserveAspectCrop
          muted: root.videoMuted
          loops: root.videoLoop ? MediaPlayer.Infinite : 1
          autoPlay: true
          playbackRate: root.videoPlaybackRate
          visible: root.currentWallpaperType === "video"

          onErrorOccurred: function(error, errorString) {
            console.error("Video error:", error, errorString)
            if (WallpaperService && WallpaperService.isInitialized) {
              const fallback = WallpaperService.getWallpaper(loader.modelData.name)
              if (fallback) {
                root.setWallpaperImmediate(fallback)
              }
            }
          }

          Component.onDestruction: {
            if (playbackState === MediaPlayer.PlayingState) {
              stop()
            }
          }
        }
      }

      // Preloads next wallpaper, then fades in on top (single decode, no shader)
      Image {
        id: nextImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: false
        mipmap: false
        cache: true
        asynchronous: true
        sourceSize: root.wallpaperSourceSize
        z: 2
        visible: root.transitioning
        opacity: root.transitionProgress

        onStatusChanged: {
          if (status !== Image.Ready) {
            return
          }

          const loaded = root.normalizePath(source)
          const pending = root.normalizePath(root.pendingSource)
          if (pending === "" || loaded !== pending) {
            return
          }

          if (root.pendingTransitionStart || root.transitioning) {
            root.startTransitionAnimation()
            return
          }

          if (root.useTransition && root.currentSource !== "" && root.currentWallpaperType === "image") {
            root.startTransitionAnimation()
          } else {
            root.commitWallpaper(pending)
          }
        }
      }

      NumberAnimation {
        id: transitionAnimation
        target: root
        property: "transitionProgress"
        from: 0.0
        to: 1.0
        duration: Settings.wallpaper.transitionDuration
        easing.type: Easing.OutCubic

        onFinished: {
          root.commitWallpaper(root.nextSource || root.pendingSource)
        }
      }

      function normalizePath(path) {
        if (!path) {
          return ""
        }
        return FileUtils.trimFileProtocol(path.toString())
      }

      function setWallpaperInitial() {
        if (!WallpaperService || !WallpaperService.isInitialized) {
          Qt.callLater(setWallpaperInitial)
          return
        }

        currentImage.asynchronous = false
        setWallpaperImmediate(WallpaperService.getWallpaper(loader.modelData.name))
        currentImage.asynchronous = true
      }

      function setWallpaperImmediate(source) {
        transitionAnimation.stop()
        pendingTransitionStart = false
        transitionProgress = 0.0
        pendingSource = ""
        nextSource = ""
        nextImage.source = ""

        const path = normalizePath(source)
        if (!path) {
          return
        }

        commitWallpaper(path)
      }

      function requestWallpaper(source) {
        const path = normalizePath(source)
        if (!path || path === currentSource || transitioning) {
          return
        }

        if (isVideoFile(path) || !useTransition || currentWallpaperType !== "image" || currentSource === "") {
          setWallpaperImmediate(path)
          return
        }

        pendingSource = path
        nextSource = path
        nextImage.source = path
      }

      function startTransitionAnimation() {
        const path = normalizePath(nextSource || pendingSource)
        if (!useTransition || path === "" || currentSource === "" || currentImage.status !== Image.Ready) {
          commitWallpaper(path)
          return
        }

        if (nextImage.status !== Image.Ready) {
          pendingTransitionStart = true
          return
        }

        pendingTransitionStart = false
        transitionProgress = 0.0
        transitionAnimation.start()
      }

      function commitWallpaper(source) {
        const path = normalizePath(source)
        transitionAnimation.stop()
        pendingTransitionStart = false
        transitionProgress = 0.0
        pendingSource = ""
        nextSource = ""

        if (!path) {
          nextImage.source = ""
          return
        }

        currentSource = path
        currentWallpaperType = "image"
        currentImage.asynchronous = false
        currentImage.source = path
        currentImage.asynchronous = true
        nextImage.source = ""
        currentVideo.source = ""
        if (currentVideo.playbackState === MediaPlayer.PlayingState) {
          currentVideo.stop()
        }
      }

      function calculateOptimalWallpaperSize(wpWidth, wpHeight) {
        const compositorScale = CompositorService.getDisplayScale(loader.modelData.name)
        const screenWidth = loader.modelData.width * compositorScale
        const screenHeight = loader.modelData.height * compositorScale

        if (wpWidth <= screenWidth || wpHeight <= screenHeight || wpWidth <= 0 || wpHeight <= 0) {
          return
        }

        const imageAspectRatio = wpWidth / wpHeight
        var dim = Qt.size(0, 0)
        if (screenWidth >= screenHeight) {
          const w = Math.min(screenWidth, wpWidth)
          dim = Qt.size(w, w / imageAspectRatio)
        } else {
          const h = Math.min(screenHeight, wpHeight)
          dim = Qt.size(h * imageAspectRatio, h)
        }

        return dim
      }

      function changeWallpaper() {
        requestWallpaper(futureWallpaper)
        futureWallpaper = ""
      }

      function isVideoFile(source) {
        if (!source) return false
        const videoExtensions = ["mp4", "webm", "mkv", "avi", "mov", "flv", "wmv", "m4v", "mpg", "mpeg"]
        const sourceStr = source.toString()
        const extension = sourceStr.split('.').pop().toLowerCase()
        return videoExtensions.includes(extension)
      }
    }
  }
}