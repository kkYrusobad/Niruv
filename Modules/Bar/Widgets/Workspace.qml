import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Compositor

/*
 * Niruv Workspace Widget - Displays workspace indicators in the bar
 * Click to switch workspaces, scroll to navigate
 */
Item {
  id: root

  property ShellScreen screen: null

  // Reference to the Niri service
  property var niriService: null

  implicitWidth: workspaceRow.width
  implicitHeight: Style.barHeight

  Component.onCompleted: {
    // Find or create NiriService
    if (!niriService) {
      niriService = niriServiceComponent.createObject(root);
      niriService.initialize();
    }
    refreshWorkspaces();
  }

  Component {
    id: niriServiceComponent
    NiriService {}
  }



  property ListModel localWorkspaces: ListModel {}

  function refreshWorkspaces() {
    if (!niriService) return;

    localWorkspaces.clear();

    for (var i = 0; i < niriService.workspaces.count; i++) {
      const ws = niriService.workspaces.get(i);
      // Filter by screen if needed
      if (screen && ws.output.toLowerCase() === screen.name.toLowerCase()) {
        localWorkspaces.append(ws);
      } else if (!screen) {
        localWorkspaces.append(ws);
      }
    }
  }

  function switchByOffset(offset) {
    if (localWorkspaces.count === 0) return;

    var currentIdx = -1;
    for (var i = 0; i < localWorkspaces.count; i++) {
      if (localWorkspaces.get(i).isFocused) {
        currentIdx = i;
        break;
      }
    }

    if (currentIdx < 0) currentIdx = 0;

    var nextIdx = (currentIdx + offset + localWorkspaces.count) % localWorkspaces.count;
    const ws = localWorkspaces.get(nextIdx);
    if (ws && niriService) {
      niriService.switchToWorkspace(ws);
    }
  }

  // Workspace icons (Nerd Font) - Edit this array to customize icons!
  // Find icons at: https://www.nerdfonts.com/cheat-sheet
  property var workspaceIcons: ["", "", "", "", "5", "6", "7", "8", "9", "10"]

  // Base dimensions
  property real pillHeight: 18
  property real pillBaseWidth: 18
  property real pillActiveMultiplier: 1.8

  // Burst effect properties (Noctalia-style)
  property real masterProgress: 0.0
  property bool effectsActive: false
  property color effectColor: Color.mPrimary

  function triggerBurstEffect() {
    effectColor = Color.mPrimary;
    burstAnimation.restart();
  }

  // Master animation for burst effect
  SequentialAnimation {
    id: burstAnimation
    PropertyAction {
      target: root
      property: "effectsActive"
      value: true
    }
    NumberAnimation {
      target: root
      property: "masterProgress"
      from: 0.0
      to: 1.0
      duration: Style.animationSlow
      easing.type: Style.easingEnter
    }
    PropertyAction {
      target: root
      property: "effectsActive"
      value: false
    }
    PropertyAction {
      target: root
      property: "masterProgress"
      value: 0.0
    }
  }

  // Trigger burst on workspace change
  Connections {
    target: niriService
    function onWorkspacesUpdated() {
      refreshWorkspaces();
      triggerBurstEffect();
    }
  }

  Row {
    id: workspaceRow
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.marginXS

    Repeater {
      model: localWorkspaces

      Item {
        id: pillContainer
        width: model.isFocused ? pillBaseWidth * pillActiveMultiplier : pillBaseWidth
        height: pillHeight

        Rectangle {
          id: workspacePill
          anchors.centerIn: parent
          width: parent.width
          height: parent.height
          radius: Style.radiusS

          // Scale: Active = 1.0, Inactive = 0.9 (Noctalia style)
          scale: model.isFocused ? 1.0 : 0.9

          color: {
            if (model.isFocused) return Color.mPrimary;
            return Color.transparent;  // All inactive/empty are transparent
          }

          Text {
            anchors.centerIn: parent
            text: {
              var idx = model.idx - 1;
              if (idx >= 0 && idx < workspaceIcons.length) {
                return workspaceIcons[idx];
              }
              return "󰎤";
            }
            color: {
              if (model.isFocused) return Color.mOnPrimary;
              return Color.mOnSurface;
            }
            font.family: Style.fontFamily
            font.pixelSize: 14
            font.weight: Style.fontWeightBold
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (niriService) {
                niriService.switchToWorkspace(model);
              }
            }
          }

          // Noctalia-style animations with OutBack easing
          Behavior on scale {
            NumberAnimation {
              duration: Style.animationFast
              easing.type: Style.easingEmphasized
            }
          }
          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
              easing.type: Style.easingStandard
            }
          }
        }

        // Container width animation for smooth expand/collapse
        Behavior on width {
          NumberAnimation {
            duration: Style.animationFast
            easing.type: Style.easingStandard
          }
        }

        // Burst effect overlay (Noctalia-style expanding ring)
        Rectangle {
          id: pillBurst
          anchors.centerIn: parent
          width: pillContainer.width + 18 * root.masterProgress
          height: pillContainer.height + 18 * root.masterProgress
          radius: Style.radiusS + 4 * root.masterProgress
          color: Color.transparent
          border.color: root.effectColor
          border.width: Math.max(1, Math.round(2 + 4 * (1.0 - root.masterProgress)))
          opacity: root.effectsActive && model.isFocused ? (1.0 - root.masterProgress) * 0.8 : 0
          visible: root.effectsActive && model.isFocused
          z: 1
        }
      }
    }
  }
}
