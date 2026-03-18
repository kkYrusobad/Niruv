import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.System
import qs.Modules.Panels.SystemMonitorPanel

/*
 * Niruv SystemMonitor Widget - Compact system stats display
 * Shows: CPU%, RAM%, Temperature, Load Average
 */
Item {
  id: root

  property ShellScreen screen: null

  // Track hover state for expansion
  property bool isHovered: false

  // Dimensions
  implicitWidth: contentRow.width + Style.marginS * 2
  implicitHeight: Style.barHeight

  // System Monitor Panel
  SystemMonitorPanel {
    id: systemMonitorPanel
    anchorItem: root
    screen: root.screen
  }

  // Capsule background (Noctalia-style like Media widget)
  Rectangle {
    id: capsule
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    width: contentRow.width + Style.marginS * 4
    height: 20
    radius: height / 2
    color: mouseArea.containsMouse ? Color.mBlue : Color.mSurfaceVariant

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

  // Content row with all stats
  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: Style.marginS

    SystemMonitorStat {
      icon: "󰘚"
      value: Math.round(SystemStatService.cpuUsage) + "%"
      hovered: mouseArea.containsMouse
      danger: SystemStatService.cpuUsage > 80
    }

    SystemMonitorStat {
      icon: ""
      value: Math.round(SystemStatService.memPercent) + "%"
      hovered: mouseArea.containsMouse
      danger: SystemStatService.memPercent > 80
    }

    SystemMonitorStat {
      icon: ""
      value: Math.round(SystemStatService.cpuTemp) + "°"
      hovered: mouseArea.containsMouse
      danger: SystemStatService.cpuTemp > 80
      visible: SystemStatService.cpuTemp > 0
    }

    SystemMonitorStat {
      icon: ""
      value: SystemStatService.loadAvg.toFixed(2)
      hovered: mouseArea.containsMouse
    }
  }

  // Mouse interaction
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: isHovered = true
    onExited: isHovered = false

    onClicked: {
      systemMonitorPanel.toggle();
    }
  }
}
