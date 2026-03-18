import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.Commons
import qs.Services.System

/*
 * Niruv ActiveWindow Widget - Shows focused window title and icon
 * Uses Niri IPC to get focused window information
 */
Item {
  id: root

  property ShellScreen screen: null
  
  // Window info properties
  property string windowTitle: ""
  property string windowAppId: ""
  property string windowIcon: ""
  property bool hasWindow: windowTitle !== ""

  function buildIconLookupKeys(appId, title) {
    let raw = (appId || "").toString().trim();
    if (raw.endsWith(".desktop")) {
      raw = raw.slice(0, -8);
    }

    const keys = [];
    const pushKey = key => {
      const value = (key || "").toString().trim().toLowerCase();
      if (!value || keys.indexOf(value) !== -1) return;
      keys.push(value);
    };

    pushKey(raw);

    // Common package/channel suffixes that desktop IDs often omit.
    if (raw.endsWith("-stable")) {
      pushKey(raw.slice(0, -7));
    }
    if (raw.endsWith("-bin")) {
      pushKey(raw.slice(0, -4));
    }

    if (raw.indexOf(".") !== -1) {
      const dotParts = raw.split(".");
      pushKey(dotParts[dotParts.length - 1]);
      pushKey(dotParts.join("-"));
    }

    const lowerTitle = (title || "").toLowerCase();
    if (lowerTitle.indexOf("visual studio code") !== -1) {
      pushKey("code");
      pushKey("vscode");
    }
    if (lowerTitle.indexOf("vivaldi") !== -1) {
      pushKey("vivaldi");
      pushKey("vivaldi-stable");
    }

    return keys;
  }

  function findIconFromDesktopEntries(keys) {
    ApplicationsService.ensureLoaded();

    if (!ApplicationsService.isLoaded || !ApplicationsService.allApps || ApplicationsService.allApps.length === 0) {
      return "";
    }

    const apps = ApplicationsService.allApps;
    const keySet = [];
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (keySet.indexOf(key) === -1) keySet.push(key);
      if (keySet.indexOf(key + ".desktop") === -1) keySet.push(key + ".desktop");
    }

    for (let i = 0; i < apps.length; i++) {
      const app = apps[i];
      const icon = app && app.icon ? app.icon : "";
      if (!icon) continue;

      const id = (app.id || "").toLowerCase();
      const execName = (app.execName || "").toLowerCase();
      const name = (app.name || "").toLowerCase();

      for (let k = 0; k < keySet.length; k++) {
        const key = keySet[k];
        if (id === key || execName === key || name === key) {
          return icon;
        }
      }
    }

    for (let i = 0; i < apps.length; i++) {
      const app = apps[i];
      const icon = app && app.icon ? app.icon : "";
      if (!icon) continue;

      const id = (app.id || "").toLowerCase();
      const execName = (app.execName || "").toLowerCase();

      for (let k = 0; k < keys.length; k++) {
        const key = keys[k];
        if ((id && id.indexOf(key) !== -1) || (execName && execName.indexOf(key) !== -1)) {
          return icon;
        }
      }
    }

    return "";
  }

  function resolveWindowIcon(appId, title) {
    const fallbackIcon = "application-x-executable";
    const keys = buildIconLookupKeys(appId, title);
    const desktopIcon = findIconFromDesktopEntries(keys);
    if (desktopIcon && desktopIcon.length > 0) {
      return desktopIcon;
    }

    let raw = (appId || "").toString().trim();
    if (raw.endsWith(".desktop")) {
      raw = raw.slice(0, -8);
    }

    const key = raw.toLowerCase();
    const map = {
      "code": "code",
      "code-oss": "code",
      "code-url-handler": "code",
      "visual-studio-code": "code",
      "com.visualstudio.code": "code",
      "codium": "vscodium",
      "vscodium": "vscodium",
      "com.vscodium.codium": "vscodium",
      "vivaldi-stable": "vivaldi",
      "vivaldi": "vivaldi"
    };

    let preferred = map[key] || raw;
    if ((!preferred || preferred.length === 0) && title && title.toLowerCase().indexOf("visual studio code") !== -1) {
      preferred = "code";
    }

    return preferred && preferred.length > 0 ? preferred : fallbackIcon;
  }

  // Dimensions - add extra left margin for spacing from SystemMonitor
  implicitWidth: hasWindow ? contentRow.width + Style.marginS * 2 + Style.marginM : 0
  implicitHeight: Style.barHeight
  visible: hasWindow

  // Poll for focused window info
  Timer {
    id: pollTimer
    interval: 500
    running: true
    repeat: true
    onTriggered: focusedWindowProcess.running = true
  }

  // Get focused window info via niri msg
  Process {
    id: focusedWindowProcess
    command: ["niri", "msg", "-j", "focused-window"]
    
    stdout: SplitParser {
      onRead: data => {
        try {
          const windowData = JSON.parse(data.trim());
          if (windowData) {
            root.windowTitle = windowData.title || "";
            root.windowAppId = windowData.app_id || "";
            root.windowIcon = root.resolveWindowIcon(root.windowAppId, root.windowTitle);
          } else {
            root.windowTitle = "";
            root.windowAppId = "";
            root.windowIcon = "";
          }
        } catch (e) {
          // No window focused or parse error
          root.windowTitle = "";
          root.windowAppId = "";
          root.windowIcon = "";
        }
      }
    }
  }

  // Initial fetch
  Component.onCompleted: {
    focusedWindowProcess.running = true;
  }

  // Capsule background
  Rectangle {
    id: capsule
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    width: contentRow.width + Style.marginS * 4
    height: 20
    radius: height / 2
    color: mouseArea.containsMouse ? Color.mPrimary : Color.mSurfaceVariant
    visible: hasWindow

    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.InOutQuad
      }
    }

    Behavior on width {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }
    }
  }

  // Content row
  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: Style.marginXS
    visible: hasWindow

    // Window icon
    IconImage {
      id: windowIconImage
      anchors.verticalCenter: parent.verticalCenter
      width: 14
      height: 14
      source: hasWindow ? Quickshell.iconPath(root.windowIcon, "application-x-executable") : ""
      asynchronous: true
    }

    // Window title (truncated)
    Text {
      id: titleText
      anchors.verticalCenter: parent.verticalCenter
      text: {
        const maxLen = 30;
        if (root.windowTitle.length > maxLen) {
          return root.windowTitle.substring(0, maxLen) + "…";
        }
        return root.windowTitle;
      }
      color: mouseArea.containsMouse ? Color.mOnPrimary : Color.mOnSurface
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeS
      font.weight: Style.fontWeightMedium

      Behavior on color {
        ColorAnimation { duration: Style.animationFast }
      }
    }
  }

  // Mouse interaction (future: click to focus, right-click for options)
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    visible: hasWindow
  }
}
