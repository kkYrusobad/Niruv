import QtQuick
import Quickshell
import qs.Commons

/*
 * PanelPopup - shared popup shell for panel components.
 * Provides anchor positioning, panel state lifecycle, and implicit sizing.
 */
PopupWindow {
  id: root

  property Item anchorItem: null
  property ShellScreen screen: null
  property Item panelContentItem: null
  property real panelWidth: 280
  property real panelOpacity: isOpen ? 1.0 : 0.0
  property real panelScale: isOpen ? 1.0 : 0.97

  property bool isOpen: false
  property bool isClosing: false
  property double lastTransitionAtMs: 0
  property int transitionGuardMs: 180

  visible: isOpen || isClosing
  color: "transparent"

  anchor.item: anchorItem
  anchor.rect.x: anchorItem ? (anchorItem.width - panelWidth) / 2 : 0
  anchor.rect.y: anchorItem ? anchorItem.height + Style.marginS : 0

  implicitWidth: panelContentItem ? (panelContentItem.width > 0 ? panelContentItem.width : panelContentItem.implicitWidth) : 0
  implicitHeight: panelContentItem ? (panelContentItem.height > 0 ? panelContentItem.height : panelContentItem.implicitHeight) : 0

  Behavior on panelOpacity {
    NumberAnimation {
      duration: Style.animationFast
      easing.type: Style.easingStandard
    }
  }

  Behavior on panelScale {
    NumberAnimation {
      duration: Style.animationFast
      easing.type: Style.easingEnter
    }
  }

  onPanelContentItemChanged: {
    if (!panelContentItem) {
      return;
    }

    panelContentItem.opacity = panelOpacity;
    panelContentItem.scale = panelScale;
    panelContentItem.transformOrigin = Item.Top;
  }

  onPanelOpacityChanged: {
    if (panelContentItem) {
      panelContentItem.opacity = panelOpacity;
    }
  }

  onPanelScaleChanged: {
    if (panelContentItem) {
      panelContentItem.scale = panelScale;
    }
  }

  Timer {
    id: closeCleanupTimer
    interval: Style.animationFast + 40
    running: false
    repeat: false
    onTriggered: {
      if (!root.isOpen) {
        root.isClosing = false;
        PanelState.panelClosed(root);
      }
    }
  }

  function toggle() {
    const now = Date.now();
    if ((now - lastTransitionAtMs) < transitionGuardMs) {
      return;
    }

    if (isOpen) {
      close();
    } else {
      open();
    }
  }

  function open() {
    const now = Date.now();
    if ((now - lastTransitionAtMs) < transitionGuardMs) {
      return;
    }

    lastTransitionAtMs = now;
    PanelState.openPanel(root);
    closeCleanupTimer.stop();
    isClosing = false;
    isOpen = true;
  }

  function close() {
    const now = Date.now();
    if ((now - lastTransitionAtMs) < transitionGuardMs) {
      return;
    }

    if (!isOpen && !isClosing) {
      return;
    }

    lastTransitionAtMs = now;
    isOpen = false;
    isClosing = true;
    closeCleanupTimer.restart();
  }
}