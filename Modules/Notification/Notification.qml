import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services.System

Variants {
  model: Quickshell.screens

  delegate: PanelWindow {
    id: notifWindow
    screen: modelData

    WlrLayershell.namespace: "niruv-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    color: "transparent"

    anchors {
      top: true
      right: true
    }

    margins {
      top: Style.marginL + Style.barHeight
      right: Style.marginL
    }

    implicitWidth: 350
    implicitHeight: notificationStack.implicitHeight + Style.marginL

    ColumnLayout {
      id: notificationStack
      width: 350
      spacing: Style.marginS

      Repeater {
        model: NotificationService.activeList

        delegate: Rectangle {
          id: notifCard
          required property var model

          Layout.preferredWidth: 350
          Layout.preferredHeight: contentLayout.implicitHeight + Style.marginL * 2

          property bool hovered: false

          radius: Style.radiusM
          color: hovered ? Qt.lighter(Color.mSurface, 1.06) : Color.mSurface
          border.color: Color.mOutline
          border.width: Style.borderS
          opacity: 0.0
          scale: 0.97

          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
              easing.type: Style.easingStandard
            }
          }

          Behavior on opacity {
            NumberAnimation {
              duration: Style.animationFast
              easing.type: Style.easingStandard
            }
          }

          Behavior on scale {
            NumberAnimation {
              duration: Style.animationFast
              easing.type: Style.easingEnter
            }
          }

          Component.onCompleted: {
            opacity = 1.0;
            scale = 1.0;
          }

          // Shadow effect
          Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            z: -1
            radius: parent.radius + 2
            color: Qt.alpha(Color.mShadow, 0.3)
          }

          RowLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            Rectangle {
              Layout.preferredWidth: 32
              Layout.preferredHeight: 32
              radius: Style.radiusS
              color: Color.mSurfaceVariant
              
              Text {
                anchors.centerIn: parent
                text: "󰂚" // Notification icon
                font.family: Style.fontFamily
                font.pointSize: 14
                color: model.urgency === 2 ? Color.mError : Color.mPrimary
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              Text {
                Layout.fillWidth: true
                text: model.summary
                font.family: Style.fontFamily
                font.pointSize: Style.fontSizeM
                font.weight: Font.Bold
                color: Color.mOnSurface
                elide: Text.ElideRight
                maximumLineCount: 1
              }

              Text {
                Layout.fillWidth: true
                text: model.body
                font.family: Style.fontFamily
                font.pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: notifCard.hovered = true
            onExited: notifCard.hovered = false

            onClicked: {
              notifCard.opacity = 0.0;
              notifCard.scale = 0.97;
              dismissTimer.restart();
            }
          }

          Timer {
            id: dismissTimer
            interval: Style.animationFast + 30
            running: false
            repeat: false
            onTriggered: NotificationService.removeNotification(notifCard.model.id)
          }
        }
      }
    }
  }
}
