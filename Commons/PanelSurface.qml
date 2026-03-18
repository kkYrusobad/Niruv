import QtQuick
import QtQuick.Layouts
import qs.Commons

Rectangle {
  id: root

  property bool showShadow: true
  property int contentMargins: Style.marginL
  property int contentSpacing: Style.marginM

  default property alias contentData: contentColumn.data

  implicitWidth: contentColumn.implicitWidth + contentMargins * 2
  implicitHeight: contentColumn.implicitHeight + contentMargins * 2

  radius: Style.radiusL
  color: Qt.alpha(Color.mSurface, 0.95)
  border.color: Qt.alpha(Color.mOutline, 0.8)
  border.width: Style.borderS

  Rectangle {
    anchors.fill: parent
    anchors.margins: -2
    z: -1
    radius: parent.radius + 2
    color: Qt.alpha(Color.mShadow, 0.3)
    visible: root.showShadow
  }

  ColumnLayout {
    id: contentColumn
    anchors.fill: parent
    anchors.margins: root.contentMargins
    spacing: root.contentSpacing
  }
}
