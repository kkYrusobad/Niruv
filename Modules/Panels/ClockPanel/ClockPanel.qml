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


