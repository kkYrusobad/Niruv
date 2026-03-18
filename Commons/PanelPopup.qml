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

  visible: false
  color: "transparent"

  anchor.item: anchorItem
  anchor.rect.x: anchorItem ? (anchorItem.width - panelWidth) / 2 : 0
  anchor.rect.y: anchorItem ? anchorItem.height + Style.marginS : 0

  implicitWidth: panelContentItem ? panelContentItem.width : 0
  implicitHeight: panelContentItem ? panelContentItem.height : 0

  function toggle() {
    if (visible) {
      close();
    } else {
      open();
    }
  }

  function open() {
    PanelState.openPanel(root);
    visible = true;
  }

  function close() {
    visible = false;
    PanelState.panelClosed(root);
  }
}