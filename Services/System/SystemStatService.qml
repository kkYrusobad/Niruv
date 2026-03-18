pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

/*
 * Niruv SystemStatService - Collects system statistics from /proc/ filesystem
 * Provides: CPU usage, CPU temperature, RAM usage, Load average
 */
Singleton {
  id: root

  // Configuration
  readonly property int pollingIntervalMs: 3000

  // Public values
  property real cpuUsage: 0
  property real cpuTemp: 0
  property real memGb: 0
  property real memPercent: 0
  property real loadAvg: 0

  // Internal state for CPU calculation
  property var prevCpuStats: null

  // CPU temperature sensor detection
  readonly property var supportedTempSensorNames: ["coretemp", "k10temp", "zenpower"]
  property string cpuTempSensorName: ""
  property string cpuTempHwmonPath: ""

  // For Intel coretemp averaging
  property var intelTempValues: []
  property int intelTempFilesChecked: 0
  property int intelTempMaxFiles: 20

  // --------------------------------------------
  Component.onCompleted: {
    Logger.i("SystemStat", "Service started");
    // Start CPU temperature sensor detection
    cpuTempNameReader.checkNext();
  }

  // --------------------------------------------
  // Single heartbeat for all periodic stats updates.
  Timer {
    id: pollTimer
    interval: root.pollingIntervalMs
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: {
      cpuStatFile.reload();
      memInfoFile.reload();
      loadAvgFile.reload();
      updateCpuTemperature();
    }
  }

  // --------------------------------------------
  // FileView components for reading system files
  FileView {
    id: memInfoFile
    path: "/proc/meminfo"
    onLoaded: parseMemoryInfo(text())
  }

  FileView {
    id: cpuStatFile
    path: "/proc/stat"
    onLoaded: calculateCpuUsage(text())
  }

  FileView {
    id: loadAvgFile
    path: "/proc/loadavg"
    onLoaded: parseLoadAverage(text())
  }

  // --------------------------------------------
  // CPU Temperature Sensor Detection
  FileView {
    id: cpuTempNameReader
    property int currentIndex: 0
    printErrors: false

    function checkNext() {
      if (currentIndex >= 16) {
        Logger.w("SystemStat", "No supported temperature sensor found");
        return;
      }

      cpuTempNameReader.path = `/sys/class/hwmon/hwmon${currentIndex}/name`;
      cpuTempNameReader.reload();
    }

    onLoaded: {
      const name = text().trim();
      if (root.supportedTempSensorNames.includes(name)) {
        root.cpuTempSensorName = name;
        root.cpuTempHwmonPath = `/sys/class/hwmon/hwmon${currentIndex}`;
        Logger.i("SystemStat", `Found ${root.cpuTempSensorName} CPU thermal sensor at ${root.cpuTempHwmonPath}`);
        // Prime temperature immediately instead of waiting for next heartbeat.
        root.updateCpuTemperature();
      } else {
        currentIndex++;
        Qt.callLater(() => checkNext());
      }
    }

    onLoadFailed: function(error) {
      currentIndex++;
      Qt.callLater(() => checkNext());
    }
  }

  // CPU Temperature Reader
  FileView {
    id: cpuTempReader
    printErrors: false

    onLoaded: {
      const data = text().trim();
      if (root.cpuTempSensorName === "coretemp") {
        // For Intel, collect all temperature values
        const temp = parseInt(data) / 1000.0;
        root.intelTempValues.push(temp);
        Qt.callLater(() => checkNextIntelTemp());
      } else {
        // For AMD sensors (k10temp and zenpower), directly set the temperature
        root.cpuTemp = Math.round(parseInt(data) / 1000.0);
      }
    }

    onLoadFailed: function(error) {
      Qt.callLater(() => checkNextIntelTemp());
    }
  }

  // --------------------------------------------
  // Parse memory info from /proc/meminfo
  function parseMemoryInfo(text) {
    if (!text) return;

    const lines = text.split('\n');
    let memTotal = 0;
    let memAvailable = 0;

    for (const line of lines) {
      if (line.startsWith('MemTotal:')) {
        memTotal = parseInt(line.split(/\s+/)[1]) || 0;
      } else if (line.startsWith('MemAvailable:')) {
        memAvailable = parseInt(line.split(/\s+/)[1]) || 0;
      }
    }

    if (memTotal > 0) {
      const usageKb = memTotal - memAvailable;
      root.memGb = (usageKb / 1048576).toFixed(1); // 1024*1024
      root.memPercent = Math.round((usageKb / memTotal) * 100);
    }
  }

  // --------------------------------------------
  // Calculate CPU usage from /proc/stat
  function calculateCpuUsage(text) {
    if (!text) return;

    const lines = text.split('\n');
    const cpuLine = lines[0];

    if (!cpuLine.startsWith('cpu ')) return;

    const parts = cpuLine.split(/\s+/);
    const stats = {
      user: parseInt(parts[1]) || 0,
      nice: parseInt(parts[2]) || 0,
      system: parseInt(parts[3]) || 0,
      idle: parseInt(parts[4]) || 0,
      iowait: parseInt(parts[5]) || 0,
      irq: parseInt(parts[6]) || 0,
      softirq: parseInt(parts[7]) || 0,
      steal: parseInt(parts[8]) || 0,
      guest: parseInt(parts[9]) || 0,
      guestNice: parseInt(parts[10]) || 0
    };

    const totalIdle = stats.idle + stats.iowait;
    const total = Object.values(stats).reduce((sum, val) => sum + val, 0);

    if (root.prevCpuStats) {
      const prevTotalIdle = root.prevCpuStats.idle + root.prevCpuStats.iowait;
      const prevTotal = Object.values(root.prevCpuStats).reduce((sum, val) => sum + val, 0);

      const diffTotal = total - prevTotal;
      const diffIdle = totalIdle - prevTotalIdle;

      if (diffTotal > 0) {
        root.cpuUsage = (((diffTotal - diffIdle) / diffTotal) * 100).toFixed(1);
      }
    }

    root.prevCpuStats = stats;
  }

  // --------------------------------------------
  // Parse load average from /proc/loadavg
  function parseLoadAverage(text) {
    if (!text) return;

    const parts = text.trim().split(/\s+/);
    if (parts.length >= 1) {
      root.loadAvg = parseFloat(parts[0]) || 0;
    }
  }

  // --------------------------------------------
  // Update CPU temperature
  function updateCpuTemperature() {
    if (root.cpuTempSensorName === "k10temp" || root.cpuTempSensorName === "zenpower") {
      cpuTempReader.path = `${root.cpuTempHwmonPath}/temp1_input`;
      cpuTempReader.reload();
    } else if (root.cpuTempSensorName === "coretemp") {
      root.intelTempValues = [];
      root.intelTempFilesChecked = 0;
      checkNextIntelTemp();
    }
  }

  // --------------------------------------------
  // Check next Intel temperature sensor
  function checkNextIntelTemp() {
    if (root.intelTempFilesChecked >= root.intelTempMaxFiles) {
      // Calculate average of all found temperatures
      if (root.intelTempValues.length > 0) {
        let sum = 0;
        for (var i = 0; i < root.intelTempValues.length; i++) {
          sum += root.intelTempValues[i];
        }
        root.cpuTemp = Math.round(sum / root.intelTempValues.length);
      } else {
        root.cpuTemp = 0;
      }
      return;
    }

    root.intelTempFilesChecked++;
    cpuTempReader.path = `${root.cpuTempHwmonPath}/temp${root.intelTempFilesChecked}_input`;
    cpuTempReader.reload();
  }
}
