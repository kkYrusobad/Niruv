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
  Rectangle {
    id: panelContent
    width: root.panelWidth
    height: contentColumn.implicitHeight + Style.marginL * 2
    radius: Style.radiusL
    color: Color.mSurface
    border.color: Color.mOutline
    border.width: Style.borderS

    // Shadow effect simulation
    Rectangle {
      anchors.fill: parent
      anchors.margins: -2
      z: -1
      radius: parent.radius + 2
      color: Qt.alpha(Color.mShadow, 0.3)
    }

    ColumnLayout {
      id: contentColumn
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

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

    // Animation
    scale: root.visible ? 1.0 : 0.95
    opacity: root.visible ? 1.0 : 0.0
    transformOrigin: Item.Top

    Behavior on scale {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
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


