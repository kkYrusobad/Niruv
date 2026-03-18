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
  readonly property bool isClosing: false

  visible: isOpen
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

  function toggle() {
    if (isOpen) {
      close();
    } else {
      open();
    }
  }

  function open() {
    if (isOpen) {
      return;
    }

    PanelState.openPanel(root);
    isOpen = true;
  }

  function close() {
    if (!isOpen) {
      return;
    }

    isOpen = false;
    PanelState.panelClosed(root);
  }
}