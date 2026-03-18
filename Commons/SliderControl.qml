import QtQuick
import QtQuick.Layouts
import qs.Commons

Rectangle {
  id: root

  property real value: 0
  property real minValue: 0
  property real maxValue: 1
  property color accentColor: Color.mPrimary
  property color trackColor: Color.mOutline
  property color iconColor: Color.mOnSurfaceVariant
  property color handleBorderColor: Color.mSurface
  property string leftIcon: ""
  property string rightIcon: ""
  property real trackHeight: 6
  property real handleSize: 16

  signal valueChangeRequested(real value)

  function normalize(v) {
    if (maxValue <= minValue) {
      return 0;
    }
    return Math.max(0, Math.min(1, (v - minValue) / (maxValue - minValue)));
  }

  function denormalize(n) {
    const clamped = Math.max(0, Math.min(1, n));
    return minValue + clamped * (maxValue - minValue);
  }

  function requestValueFromX(mouseX, width) {
    if (width <= 0) {
      return;
    }
    valueChangeRequested(denormalize(mouseX / width));
  }

  radius: Style.radiusM
  color: Color.mSurfaceVariant
  border.color: Color.mOutline
  border.width: Style.borderS

  RowLayout {
    anchors.fill: parent
    anchors.margins: Style.marginM
    spacing: Style.marginS

    Text {
      text: root.leftIcon
      color: root.iconColor
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeL
    }

    Item {
      id: sliderTrackItem
      Layout.fillWidth: true
      Layout.preferredHeight: 24

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: root.trackHeight
        radius: root.trackHeight / 2
        color: root.trackColor
      }

      Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * root.normalize(root.value)
        height: root.trackHeight
        radius: root.trackHeight / 2
        color: root.accentColor

        Behavior on width {
          NumberAnimation {
            duration: Style.animationFaster
            easing.type: Style.easingStandard
          }
        }
      }

      Rectangle {
        x: parent.width * root.normalize(root.value) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: root.handleSize
        height: root.handleSize
        radius: width / 2
        color: root.accentColor
        border.color: root.handleBorderColor
        border.width: Style.borderM

        Behavior on x {
          NumberAnimation {
            duration: Style.animationFaster
            easing.type: Style.easingStandard
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPressed: function(mouse) {
          root.requestValueFromX(mouse.x, width);
        }

        onPositionChanged: function(mouse) {
          if (pressed) {
            root.requestValueFromX(mouse.x, width);
          }
        }
      }
    }

    Text {
      text: root.rightIcon
      color: root.iconColor
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeL
    }
  }
}
