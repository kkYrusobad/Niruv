pragma Singleton
import QtQuick

/*
 * PanelState - Global singleton to track open panels
 * Enables click-outside-to-close functionality
 */
QtObject {
  id: root

  // Currently open panel (null if none)
  property var currentPanel: null

  // Track if any panel is open
  readonly property bool hasOpenPanel: {
    if (currentPanel === null) {
      return false;
    }

    // PanelPopup-based panels expose isOpen/isClosing; keep backdrop only while truly open.
    if (currentPanel.isOpen !== undefined || currentPanel.isClosing !== undefined) {
      return !!currentPanel.isOpen;
    }

    // Fallback for popup-like components that only expose visible (e.g. tray menu).
    return !!currentPanel.visible;
  }

  // Register a panel as open (closes any existing panel first)
  function openPanel(panel) {
    if (root.currentPanel && root.currentPanel !== panel) {
      root.currentPanel.close();
    }
    root.currentPanel = panel;
  }

  // Close the currently open panel
  function closeOpenPanel() {
    if (root.currentPanel) {
      root.currentPanel.close();
    }
  }

  // Unregister a panel (called when panel closes itself)
  function panelClosed(panel) {
    if (root.currentPanel === panel) {
      root.currentPanel = null;
    }
  }
}
