import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Cards

/*
 * ClockPanel - Popup panel with calendar and timer
 * Opens below the bar clock, contains CalendarHeaderCard, CalendarMonthCard, TimerCard
 */
PanelPopup {
  id: root

  property real panelWidth: 320
  panelContentItem: panelContent



  // Panel background
  PanelSurface {
    id: panelContent
    width: root.panelWidth
    height: implicitHeight

      // Calendar Header
      CalendarHeaderCard {
        Layout.fillWidth: true
      }

      // Calendar Month Grid
      CalendarMonthCard {
        Layout.fillWidth: true
      }

      // Timer Card
      TimerCard {
        Layout.fillWidth: true
      }
  }

  // Close on Escape key
  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.close()
  }
}


