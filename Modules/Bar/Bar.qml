import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Widgets
import qs.Modules.Panels.ClockPanel
import qs.Modules.Panels.NetworkPanel

/*
 * Niruv Bar - Main bar component with workspaces and clock
 */
Item {
  id: root

  property ShellScreen screen: null
  readonly property var widgetCfg: (Settings.data.bar && Settings.data.bar.widgets) ? Settings.data.bar.widgets : null
  readonly property var widgetDefaults: ({
    media: true,
    visualizer: false,
    workspace: true,
    systemMonitor: true,
    activeWindow: true,
    tray: true,
    wallpaper: false,
    wifi: true,
    bluetooth: true,
    screenRecorder: false,
    volume: true,
    brightness: true,
    nightLight: false,
    battery: true
  })

  function widgetEnabled(name) {
    if (!root.widgetCfg || root.widgetCfg[name] === undefined || root.widgetCfg[name] === null) {
      return !!root.widgetDefaults[name];
    }
    return !!root.widgetCfg[name];
  }

  anchors.fill: parent

  // Bar background (Gruvbox Material Dark)
  Rectangle {
    id: barBackground
    anchors.fill: parent
    // color: Color.mSurface
    color: "transparent"
  }

  // Left logo icon with backdrop
  Item {
    id: leftLogoContainer
    anchors.left: parent.left
    anchors.leftMargin: Style.marginM - 6
    anchors.verticalCenter: parent.verticalCenter
    //width: leftLogoCapsule.width
    width: 30
    height: Style.barHeight
    z: 10

    Rectangle {
      id: leftLogoCapsule
      anchors.verticalCenter: parent.verticalCenter
      width: leftLogoText.width + Style.marginS * 4
      height: 20
      radius: height / 2
      color: Color.mSurfaceVariant
    }

    Text {
      id: leftLogoText
      anchors.centerIn: leftLogoCapsule
      text: ""
      color: Color.mOnSurface
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeL
    }
  }

  // Right logo icon with backdrop
  Item {
    id: rightLogoContainer
    anchors.right: parent.right
    anchors.rightMargin: Style.marginM
    anchors.verticalCenter: parent.verticalCenter
    //width: rightLogoCapsule.width
    width: 30
    height: Style.barHeight
    z: 10

    Rectangle {
      id: rightLogoCapsule
      anchors.verticalCenter: parent.verticalCenter
      width: rightLogoText.width + Style.marginS * 4
      height: 20
      radius: height / 2
      color: Color.mSurfaceVariant
    }

    Text {
      id: rightLogoText
      anchors.centerIn: rightLogoCapsule
      text: ""
      color: Color.mOnSurface
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeL
    }
  }

  // Clock Panel (popup with calendar and timer)
  ClockPanel {
    id: clockPanel
    anchorItem: clockArea
    screen: root.screen
  }

  // Shared Network Panel (for WiFi and Bluetooth widgets)
  NetworkPanel {
    id: sharedNetworkPanel
    anchorItem: wifiWidgetLoader.item ? wifiWidgetLoader.item : (bluetoothWidgetLoader.item ? bluetoothWidgetLoader.item : networkAnchor)
    screen: root.screen
  }

  // Clock (absolutely centered, click to open ClockPanel)
  MouseArea {
    id: clockArea
    anchors.centerIn: parent
    width: clockContent.width + Style.marginM * 2
    height: parent.height
    cursorShape: Qt.PointingHandCursor
    z: 10

    onClicked: {
      clockPanel.toggle();
    }

    Row {
      id: clockContent
      anchors.centerIn: parent
      spacing: Style.marginS

      // Timer indicator (pulsing dot when timer is running)
      Rectangle {
        visible: Time.timerRunning
        width: 6
        height: 6
        radius: 3
        color: Color.mPrimary
        anchors.verticalCenter: parent.verticalCenter

        SequentialAnimation on opacity {
          running: Time.timerRunning
          loops: Animation.Infinite
          NumberAnimation { to: 0.3; duration: 500 }
          NumberAnimation { to: 1.0; duration: 500 }
        }
      }

      Text {
        id: clockTextCenter
        anchors.verticalCenter: parent.verticalCenter
        color: Time.timerRunning ? Color.mPrimary : Color.mOnSurface
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSizeM
        font.weight: Style.fontWeightSemiBold

        text: {
          // Show timer countdown when running
          if (Time.timerRunning) {
            if (Time.timerStopwatchMode) {
              return "󱎫 " + Time.formatTimerDisplay(Time.timerElapsedSeconds, false);
            } else {
              return "󱎫 " + Time.formatTimerDisplay(Time.timerRemainingSeconds, false);
            }
          }
          // Normal clock display
          var now = Time.now;
          var date = now.toLocaleDateString(Qt.locale(), "ddd, MMM d");
          var time = now.toLocaleTimeString(Qt.locale(), "hh:mm");
          return date + "  " + time;
        }
      }
    }
  }

  // Media widget (anchored to the left of the clock)
  Loader {
    id: mediaWidgetLoader
    active: root.widgetEnabled("media")
    anchors.verticalCenter: parent.verticalCenter
    anchors.right: clockArea.left
    anchors.rightMargin: Style.marginS
    z: 10

    sourceComponent: Component {
      Media {
        screen: root.screen
      }
    }
  }

  // Visualizer widget (anchored to the right of the clock)
  Loader {
    id: visualizerWidgetLoader
    active: root.widgetEnabled("visualizer")
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: clockArea.right
    anchors.leftMargin: Style.marginS
    z: 10

    sourceComponent: Component {
      Visualizer {
        screen: root.screen
      }
    }
  }


  // Bar content layout
  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 42
    anchors.rightMargin: 48
    spacing: Style.marginM

    // Left section - Workspaces, SystemMonitor, and ActiveWindow
    Item {
      Layout.fillHeight: true
      Layout.preferredWidth: leftRow.width

      Row {
        id: leftRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.marginM

        Loader {
          id: workspaceWidgetLoader
          active: root.widgetEnabled("workspace")
          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: Component {
            Workspace {
              anchors.verticalCenter: parent.verticalCenter
              screen: root.screen
            }
          }
        }

        Loader {
          active: root.widgetEnabled("systemMonitor")
          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: Component {
            SystemMonitor {
              anchors.verticalCenter: parent.verticalCenter
              screen: root.screen
            }
          }
        }

        Loader {
          active: root.widgetEnabled("activeWindow")
          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: Component {
            ActiveWindow {
              anchors.verticalCenter: parent.verticalCenter
              screen: root.screen
            }
          }
        }
      }
    }

    // Spacer to push right section to the end
    Item {
      Layout.fillWidth: true
    }

    // Right section - Battery and Clock
    Item {
      Layout.fillHeight: true
      Layout.preferredWidth: rightRow.width + Style.marginM

      Row {
        id: rightRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.marginM

        Item {
          id: networkAnchor
          width: 1
          height: 1
        }

        // System Tray (first - system apps)
        Loader {
          active: root.widgetEnabled("tray")
          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: Component {
            Tray {
              anchors.verticalCenter: parent.verticalCenter
              screen: root.screen
            }
          }
        }

        // Wallpaper widget
        Loader {
          active: root.widgetEnabled("wallpaper")
          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: Component {
            Wallpaper {
              anchors.verticalCenter: parent.verticalCenter
              screen: root.screen
            }
          }
        }

        // WiFi widget
        Loader {
          id: wifiWidgetLoader
          active: root.widgetEnabled("wifi")
          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: Component {
            WiFi {
              anchors.verticalCenter: parent.verticalCenter
              screen: root.screen
              networkPanel: sharedNetworkPanel
            }
          }
        }

        // Bluetooth widget
        Loader {
          id: bluetoothWidgetLoader
          active: root.widgetEnabled("bluetooth")
          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: Component {
            Bluetooth {
              anchors.verticalCenter: parent.verticalCenter
              screen: root.screen
              networkPanel: sharedNetworkPanel
            }
          }
        }

        // Screen Recorder
        Loader {
          active: root.widgetEnabled("screenRecorder")
          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: Component {
            ScreenRecorder {
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        // Volume widget
        Loader {
          active: root.widgetEnabled("volume")
          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: Component {
            Volume {
              anchors.verticalCenter: parent.verticalCenter
              screen: root.screen
            }
          }
        }

        // Brightness widget
        Loader {
          active: root.widgetEnabled("brightness")
          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: Component {
            Brightness {
              anchors.verticalCenter: parent.verticalCenter
              screen: root.screen
            }
          }
        }

        // Night Light widget
        Loader {
          active: root.widgetEnabled("nightLight")
          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: Component {
            NightLight {
              anchors.verticalCenter: parent.verticalCenter
              screen: root.screen
            }
          }
        }

        // Battery widget
        Loader {
          active: root.widgetEnabled("battery")
          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: Component {
            Battery {
              anchors.verticalCenter: parent.verticalCenter
              screen: root.screen
            }
          }
        }


      }
    }
  }
}
