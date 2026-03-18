pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Niruv Settings - Configuration singleton with JSON persistence
 * Settings are stored in ~/.config/niruv/settings.json with live reload
 */
Singleton {
  id: root

  // Debug mode (check environment variable)
  readonly property bool isDebug: {
    return (Quickshell.env("NIRUV_DEBUG") ?? "") === "1";
  }

  // Configuration directories
  readonly property string configDir: {
    var envDir = Quickshell.env("NIRUV_CONFIG_DIR");
    if (envDir && envDir.length > 0) {
      return envDir.endsWith("/") ? envDir : envDir + "/";
    }
    return Quickshell.env("HOME") + "/.config/niruv/";
  }

  // Project directory resolution
  readonly property string projectDir: {
    // 1. Check environment variable (highest priority)
    var envPath = Quickshell.env("NIRUV_PROJECT_DIR");
    if (envPath && envPath.length > 0) {
      return envPath.endsWith("/") ? envPath : envPath + "/";
    }

    // 2. Check settings property
    if (adapter.general.projectRoot && adapter.general.projectRoot.length > 0) {
      let p = adapter.general.projectRoot;
      return p.endsWith("/") ? p : p + "/";
    }

    // 3. Try to resolve via QML url (only use if it's a file:// url)
    const url = Qt.resolvedUrl("../..").toString();
    if (url.startsWith("file://")) {
      let path = url.substring(7);
      return path.endsWith("/") ? path : path + "/";
    }

    // 4. No fallback - require explicit configuration if other methods fail
    return "";
  }

  readonly property string scriptsDir: projectDir + "Niruv/Scripts/"
  readonly property string oNIgiRIBinDir: projectDir + "oNIgiRI/bin/"

  readonly property string cacheDir: {
    var envDir = Quickshell.env("NIRUV_CACHE_DIR");
    if (envDir && envDir.length > 0) {
      return envDir.endsWith("/") ? envDir : envDir + "/";
    }
    return Quickshell.env("HOME") + "/.cache/niruv/";
  }

  property bool isSettingsLoaded: false

  readonly property string settingsFile: configDir + "settings.json"

  // Access via Settings.data.xxx.yyy
  readonly property alias data: adapter

  Component.onCompleted: {
    // Ensure directories exist
    Quickshell.execDetached(["mkdir", "-p", configDir]);
    Quickshell.execDetached(["mkdir", "-p", cacheDir]);

    // Set path to FileView to trigger loading
    settingsFileView.adapter = adapter;
    settingsFileView.path = settingsFile;
  }

  // Timer to debounced saving
  Timer {
    id: saveTimer
    interval: 500
    onTriggered: root.save()
  }

  function save() {
    if (isSettingsLoaded) {
      settingsFileView.writeAdapter();
    }
  }

  FileView {
    id: settingsFileView
    watchChanges: true
    printErrors: true

    function migrateSchemaIfNeeded() {
      const raw = text();
      if (!raw || !raw.length) return;

      let needsSave = false;

      // Legacy settings.json files may miss newer nested defaults like bar.widgets.
      if (raw.indexOf('"widgets"') === -1) {
        Logger.i("Settings", "Migrating settings schema: adding missing bar.widgets defaults");
        needsSave = true;
      }

      if (raw.indexOf('"edgeIcons"') === -1) {
        Logger.i("Settings", "Migrating settings schema: adding missing bar.edgeIcons defaults");
        needsSave = true;
      }

      if (raw.indexOf('"sectionGapLeft"') === -1 || raw.indexOf('"sectionGapRight"') === -1) {
        Logger.i("Settings", "Migrating settings schema: adding missing bar.edgeIcons side-specific gap defaults");
        needsSave = true;
      }

      if (raw.indexOf('"themeVariant"') === -1) {
        Logger.i("Settings", "Migrating settings schema: adding missing general.themeVariant default");
        needsSave = true;
      }

      if (raw.indexOf('"animationMode"') === -1) {
        Logger.i("Settings", "Migrating settings schema: adding missing general.animationMode default");
        needsSave = true;
      }

      if (needsSave) {
        save();
      }
    }
    
    // When the file changes on disk, reload into adapter
    onFileChanged: reload()
    
    // When the adapter changes in memory, save to disk (debounced)
    onAdapterUpdated: saveTimer.restart()

    onLoaded: {
      if (!root.isSettingsLoaded) {
        Logger.i("Settings", "Settings loaded from " + settingsFile);
        root.isSettingsLoaded = true;
      }

      migrateSchemaIfNeeded();
    }

    onLoadFailed: function(error) {
      // If file doesn't exist, it will be created on the first write
      if (error === 2) { // ENOENT
        Logger.i("Settings", "Settings file not found, creating from defaults");
        root.isSettingsLoaded = true;
        save(); // Create the file with initial values
      } else {
        Logger.e("Settings", "Failed to load settings: " + error);
      }
    }
    
    adapter: adapter
  }

  JsonAdapter {
    id: adapter

    property JsonObject general: JsonObject {
      property string projectRoot: ""
      property real scaleRatio: 1.0
      property string themeVariant: "soft" // soft, medium, hard
      property real animationSpeed: 1.0
      property string animationMode: "balanced" // subtle, balanced, expressive
      property real radiusRatio: 1.0
      property real screenRadiusRatio: 1.0
      property int shadowOffsetX: 2
      property int shadowOffsetY: 2
      property bool animationDisabled: false
    }

    property JsonObject bar: JsonObject {
      property bool enabled: true
      property string position: "top"
      property string density: "default"
      property bool showCapsule: true
      property real capsuleOpacity: 0.5

      property JsonObject edgeIcons: JsonObject {
        property bool enabled: true
        property string left: ""
        property string right: ""
        property real opacity: 1.0
        property int edgeInset: 2
        property int sectionGap: 14 // legacy fallback
        property int sectionGapLeft: 14
        property int sectionGapRight: 14
      }

      property JsonObject widgets: JsonObject {
        property bool media: true
        property bool visualizer: false
        property bool workspace: true
        property bool systemMonitor: true
        property bool activeWindow: true
        property bool tray: true
        property bool wallpaper: false
        property bool wifi: true
        property bool bluetooth: true
        property bool screenRecorder: false
        property bool volume: true
        property bool brightness: true
        property bool nightLight: false
        property bool battery: true
      }
    }
  }
}
