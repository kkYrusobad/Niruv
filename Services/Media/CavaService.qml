pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

/*
 * Niruv CavaService - Runs cava audio visualizer and provides values
 */
Singleton {
  id: root

  // Run cava only when the visualizer feature is enabled.
  property bool shouldRun: Settings.data.bar.widgets.visualizer

  property var values: Array(barsCount).fill(0)
  property int barsCount: 24

  // Idle detection
  property bool isIdle: true
  property int idleFrameCount: 0
  readonly property int idleThreshold: 30

  onShouldRunChanged: {
    if (!shouldRun) {
      values = Array(barsCount).fill(0);
      isIdle = true;
      idleFrameCount = 0;
    }
  }

  // Cava config
  property var config: ({
    "general": {
      "bars": barsCount,
      "framerate": 30,
      "autosens": 1,
      "sensitivity": 100,
      "lower_cutoff_freq": 50,
      "higher_cutoff_freq": 12000
    },
    "smoothing": {
      "monstercat": 1,
      "noise_reduction": 77
    },
    "output": {
      "method": "raw",
      "data_format": "ascii",
      "ascii_max_range": 100,
      "bit_format": "8bit",
      "channels": "mono",
      "mono_option": "average"
    }
  })

  Process {
    id: process
    stdinEnabled: true
    running: root.shouldRun
    command: ["cava", "-p", "/dev/stdin"]
    
    onExited: {
      stdinEnabled = true;
      values = Array(barsCount).fill(0);
    }
    
    onStarted: {
      for (const k in config) {
        if (typeof config[k] !== "object") {
          write(k + "=" + config[k] + "\n");
          continue;
        }
        write("[" + k + "]\n");
        const obj = config[k];
        for (const k2 in obj) {
          write(k2 + "=" + obj[k2] + "\n");
        }
      }
      stdinEnabled = false;
      values = Array(barsCount).fill(0);
    }
    
    stdout: SplitParser {
      onRead: data => {
        const newValues = data.slice(0, -1).split(";").map(v => parseInt(v, 10) / 100);
        
        // Check if all values are effectively zero
        const allZero = newValues.every(v => v < 0.01);
        
        if (allZero) {
          root.idleFrameCount++;
          if (root.idleFrameCount >= root.idleThreshold) {
            if (!root.isIdle) {
              root.isIdle = true;
              root.values = Array(root.barsCount).fill(0);
            }
            return;
          }
        } else {
          root.idleFrameCount = 0;
          if (root.isIdle) {
            root.isIdle = false;
          }
        }
        
        if (!isIdle) {
          root.values = newValues;
        }
      }
    }
  }
}
