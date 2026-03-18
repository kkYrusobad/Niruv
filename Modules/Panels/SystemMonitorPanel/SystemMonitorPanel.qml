import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons

/*
 * SystemMonitorPanel - Popup panel with detailed system stats
 * Shows: CPU, RAM, Temperature, Load Average, Uptime
 */
PanelPopup {
  id: root

  property real panelWidth: 300
  panelContentItem: panelContent

  // System stats
  property real cpuPercent: 0
  property real memPercent: 0
  property real memUsed: 0
  property real memTotal: 0
  property real temperature: 0
  property string loadAvg: "0.00"
  property string uptime: "0h 0m"

  // Update stats
  Timer {
    interval: 2000
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      cpuProcess.running = true;
      memProcess.running = true;
      tempProcess.running = true;
      loadProcess.running = true;
      uptimeProcess.running = true;
    }
  }

  Process {
    id: cpuProcess
    command: ["sh", "-c", "grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}'"]
    stdout: SplitParser {
      onRead: data => {
        root.cpuPercent = parseFloat(data.trim()) || 0;
      }
    }
  }

  Process {
    id: memProcess
    command: ["sh", "-c", "free -b | awk '/^Mem:/ {print $3\" \"$2}'"]
    stdout: SplitParser {
      onRead: data => {
        const parts = data.trim().split(" ");
        if (parts.length >= 2) {
          root.memUsed = parseFloat(parts[0]) / (1024 * 1024 * 1024);
          root.memTotal = parseFloat(parts[1]) / (1024 * 1024 * 1024);
          root.memPercent = (root.memUsed / root.memTotal) * 100;
        }
      }
    }
  }

  Process {
    id: tempProcess
    command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0"]
    stdout: SplitParser {
      onRead: data => {
        root.temperature = parseFloat(data.trim()) / 1000 || 0;
      }
    }
  }

  Process {
    id: loadProcess
    command: ["sh", "-c", "cat /proc/loadavg | cut -d' ' -f1"]
    stdout: SplitParser {
      onRead: data => {
        root.loadAvg = data.trim();
      }
    }
  }

  Process {
    id: uptimeProcess
    command: ["sh", "-c", "uptime -p | sed 's/up //'"]
    stdout: SplitParser {
      onRead: data => {
        root.uptime = data.trim();
      }
    }
  }

  // Panel background
  PanelSurface {
    id: panelContent
    width: root.panelWidth
    height: implicitHeight

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        Text {
          text: "󰍛"
          color: Color.mPrimary
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSizeL
        }

        Text {
          text: "System Monitor"
          color: Color.mOnSurface
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSizeL
          font.weight: Style.fontWeightBold
          Layout.fillWidth: true
        }
      }

      // CPU Card
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        radius: Style.radiusM
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS

        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          Text {
            text: "󰻠"
            color: Color.mPrimary
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeXL
          }

          Column {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
              width: parent.width

              Text {
                text: "CPU"
                color: Color.mOnSurface
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeS
                font.weight: Style.fontWeightMedium
              }

              Item { Layout.fillWidth: true }

              Text {
                text: root.cpuPercent.toFixed(0) + "%"
                color: root.cpuPercent > 80 ? Color.mError : Color.mPrimary
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeS
                font.weight: Style.fontWeightBold
              }
            }

            // Progress bar
            Rectangle {
              width: parent.width
              height: 4
              radius: 2
              color: Qt.alpha(Color.mOnSurface, 0.2)

              Rectangle {
                width: parent.width * (root.cpuPercent / 100)
                height: parent.height
                radius: 2
                color: root.cpuPercent > 80 ? Color.mError : Color.mPrimary

                Behavior on width {
                  NumberAnimation { duration: Style.animationFast }
                }
              }
            }
          }
        }
      }

      // RAM Card
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        radius: Style.radiusM
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS

        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          Text {
            text: "󰘚"
            color: Color.mSecondary
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeXL
          }

          Column {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
              width: parent.width

              Text {
                text: "RAM"
                color: Color.mOnSurface
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeS
                font.weight: Style.fontWeightMedium
              }

              Item { Layout.fillWidth: true }

              Text {
                text: root.memUsed.toFixed(1) + " / " + root.memTotal.toFixed(1) + " GB"
                color: Color.mOnSurfaceVariant
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeXS
              }

              Text {
                text: root.memPercent.toFixed(0) + "%"
                color: root.memPercent > 80 ? Color.mError : Color.mSecondary
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeS
                font.weight: Style.fontWeightBold
              }
            }

            // Progress bar
            Rectangle {
              width: parent.width
              height: 4
              radius: 2
              color: Qt.alpha(Color.mOnSurface, 0.2)

              Rectangle {
                width: parent.width * (root.memPercent / 100)
                height: parent.height
                radius: 2
                color: root.memPercent > 80 ? Color.mError : Color.mSecondary

                Behavior on width {
                  NumberAnimation { duration: Style.animationFast }
                }
              }
            }
          }
        }
      }

      // Temperature and Load Row
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        // Temperature
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 60
          radius: Style.radiusM
          color: Color.mSurfaceVariant
          border.color: Color.mOutline
          border.width: Style.borderS

          Column {
            anchors.centerIn: parent
            spacing: 2

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "󰔏"
              color: root.temperature > 70 ? Color.mError : Color.mOrange
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeXL
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.temperature.toFixed(0) + "°C"
              color: root.temperature > 70 ? Color.mError : Color.mOnSurface
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeM
              font.weight: Style.fontWeightBold
            }
          }
        }

        // Load Average
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 60
          radius: Style.radiusM
          color: Color.mSurfaceVariant
          border.color: Color.mOutline
          border.width: Style.borderS

          Column {
            anchors.centerIn: parent
            spacing: 2

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "󰊚"
              color: Color.mTertiary
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeXL
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.loadAvg
              color: Color.mOnSurface
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeM
              font.weight: Style.fontWeightBold
            }
          }
        }
      }

      // Uptime
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        radius: Style.radiusS
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS

        MetricRow {
          anchors.fill: parent
          anchors.margins: Style.marginS
          icon: "󰅐"
          label: "Uptime"
          value: root.uptime
          valueColor: Color.mOnSurface
        }
      }

    // Animation
    scale: root.visible ? 1.0 : 0.95
    opacity: root.visible ? 1.0 : 0.0
    transformOrigin: Item.Top

    Behavior on scale {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Style.easingEnter
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Style.easingEnter
      }
    }
  }

  // Close on Escape key
  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.close()
  }
}
