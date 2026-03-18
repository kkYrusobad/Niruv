import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Commons
import qs.Services.System

/*
 * Launcher - Minimalist app launcher + menu for Niruv
 * Clean, compact, Gruvbox-themed
 */
Item {
  id: root

  // Panel state
  property bool isOpen: false
  property int selectedIndex: 0
  property string searchText: ""
  property string currentMode: "apps"  // "apps" or "menu"

  // Reactive list model
  property var listModel: {
    const menuCategory = MenuService.currentCategory;
    const menuSearch = MenuService.menuSearchText;
    if (currentMode === "apps") {
      return ApplicationsService.filteredApps;
    } else {
      return MenuService.getCurrentItems();
    }
  }

  // Animation
  opacity: isOpen ? 1.0 : 0.0
  visible: opacity > 0

  Behavior on opacity {
    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
  }

  // Backdrop click to close
  MouseArea {
    anchors.fill: parent
    enabled: root.isOpen
    onClicked: root.close()
  }

  // Public API
  function open(mode) {
    if (isOpen) return;
    Logger.i("Launcher", "Opening launcher");
    isOpen = true;
    currentMode = mode || "apps";
    searchText = "";
    selectedIndex = 0;
    searchInput.text = "";  // Clear search input

    // Keep startup lean: load on first open, refresh only when stale.
    if (!ApplicationsService.isLoaded) {
      ApplicationsService.ensureLoaded();
    } else if ((Date.now() - ApplicationsService.lastLoadedAtMs) > 120000) {
      ApplicationsService.refreshApplications();
    }
    
    MenuService.reset();
    Qt.callLater(() => searchInput.forceActiveFocus());
  }

  function close() {
    if (!isOpen) return;
    Logger.d("Launcher", "Closing");
    isOpen = false;
    searchText = "";
    MenuService.reset();
  }

  function toggle() {
    if (isOpen) close(); else open("apps");
  }

  function activateSelected() {
    if (currentMode === "apps") {
      if (listModel.length === 0 || selectedIndex >= listModel.length) return;
      ApplicationsService.launchApp(listModel[selectedIndex]);
      close();
    } else {
      const items = listModel;
      if (items.length === 0 || selectedIndex >= items.length) return;
      const item = items[selectedIndex];
      
      if (item.items) {
        MenuService.openCategory(item.id);
        selectedIndex = 0;
      } else if (item.submenu) {
        MenuService.openCategory(item.submenu);
        selectedIndex = 0;
      } else if (item.action) {
        MenuService.executeAction(item.action, close);
      }
    }
  }

  function goBack() {
    if (currentMode === "menu" && MenuService.currentCategory !== "") {
      MenuService.goBack();
      selectedIndex = 0;
    }
  }

  // Panel
  Rectangle {
    id: panel
    anchors.centerIn: parent
    width: 380
    height: Math.min(420, 52 + 36 * Math.max(1, listModel.length))

    color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.92)  // 92% opacity
    radius: 8
    border.color: Color.mOutline
    border.width: 1

    // Shadow effect
    Rectangle {
      anchors.fill: parent
      anchors.margins: -2
      z: -1
      radius: parent.radius + 2
      color: Qt.alpha(Color.mShadow, 0.3)
      visible: root.isOpen
    }


    scale: root.isOpen ? 1.0 : 0.96
    Behavior on scale {
      NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }

    // Keyboard
    Keys.onPressed: event => {
      if (event.key === Qt.Key_Escape) {
        if (currentMode === "menu" && MenuService.currentCategory !== "") {
          goBack();
        } else {
          close();
        }
        event.accepted = true;
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        activateSelected();
        event.accepted = true;
      } else if (event.key === Qt.Key_Down) {
        if (selectedIndex < listModel.length - 1) selectedIndex++;
        event.accepted = true;
      } else if (event.key === Qt.Key_Up) {
        if (selectedIndex > 0) selectedIndex--;
        event.accepted = true;
      } else if (event.key === Qt.Key_Tab) {
        currentMode = currentMode === "apps" ? "menu" : "apps";
        selectedIndex = 0;
        searchInput.text = "";
        MenuService.reset();
        event.accepted = true;
      } else if (event.key === Qt.Key_Backspace && searchInput.text === "" && currentMode === "menu") {
        goBack();
        event.accepted = true;
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 8
      spacing: 4

      // Search bar
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        color: Color.mSurfaceVariant
        radius: 6

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          // Mode icon (clickable to switch) - 20px container aligns with list icons
          Item {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20

            Text {
              anchors.centerIn: parent
              text: root.currentMode === "apps" ? "" : "󰄛"
              color: Color.mTertiary
              font.family: Style.fontFamily
              font.pixelSize: 16
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.currentMode = root.currentMode === "apps" ? "menu" : "apps";
                root.selectedIndex = 0;
                searchInput.text = "";
                MenuService.reset();
              }
            }
          }



          TextInput {
            id: searchInput
            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalAlignment: TextInput.AlignVCenter

            color: Color.mOnSurface
            font.family: Style.fontFamily
            font.pixelSize: 14
            selectionColor: Color.mPrimary
            selectedTextColor: Color.mOnPrimary

            Text {
              anchors.fill: parent
              verticalAlignment: Text.AlignVCenter
              text: root.currentMode === "apps" ? "Search apps..." : "Search menu..."
              color: Color.mOnSurfaceVariant
              font: parent.font
              opacity: 0.6
              visible: !parent.text && !parent.activeFocus
            }

            onTextChanged: {
              root.searchText = text;
              root.selectedIndex = 0;
              if (root.currentMode === "apps") {
                ApplicationsService.filterApps(text);
              } else {
                MenuService.menuSearchText = text;
              }
            }

            Keys.onPressed: event => {
              if ([Qt.Key_Escape, Qt.Key_Return, Qt.Key_Enter, Qt.Key_Down, Qt.Key_Up, Qt.Key_Tab].includes(event.key)) {
                panel.Keys.pressed(event);
              }
            }
          }

          // Count
          Text {
            text: listModel.length + "/" + (root.currentMode === "apps" ? ApplicationsService.allApps.length : MenuService.getAllItems().length + MenuService.menuCategories.length)
            color: Color.mOnSurfaceVariant
            font.family: Style.fontFamily
            font.pixelSize: 12
            opacity: 0.7
          }
        }
      }

      // List
      ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 0

        model: root.listModel
        currentIndex: root.selectedIndex

        highlightMoveDuration: 100

        delegate: Rectangle {
          id: item
          required property var modelData
          required property int index

          width: list.width
          height: 36
          radius: 4
          color: isHovered || index === root.selectedIndex ? Color.mHover : "transparent"

          property bool isHovered: false
          property bool isCategory: modelData.items !== undefined

          Behavior on color {
            ColorAnimation { duration: 100 }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            // Icon
            Item {
              Layout.preferredWidth: 20
              Layout.preferredHeight: 20

              IconImage {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: root.currentMode === "apps" ? Quickshell.iconPath(modelData.icon, "application-x-executable") : ""
                visible: root.currentMode === "apps"
                asynchronous: true
              }

              Text {
                anchors.centerIn: parent
                text: modelData.icon || "󰀻"
                color: item.isHovered || index === root.selectedIndex ? Color.mOnHover : Color.mPrimary
                font.family: Style.fontFamily
                font.pixelSize: 16
                visible: root.currentMode === "menu"
              }
            }

            // Name
            Text {
              Layout.fillWidth: true
              text: modelData.name || "Unknown"
              color: item.isHovered || index === root.selectedIndex ? Color.mOnHover : Color.mOnSurface
              font.family: Style.fontFamily
              font.pixelSize: 13
              elide: Text.ElideRight
            }

            // Category badge (for search results)
            Text {
              text: modelData.category || ""
              color: Color.mOnSurfaceVariant
              font.family: Style.fontFamily
              font.pixelSize: 10
              opacity: 0.6
              visible: modelData.category !== undefined && root.currentMode === "menu" && MenuService.isSearching
            }

            // Arrow for categories
            Text {
              text: "›"
              color: Color.mOnSurfaceVariant
              font.family: Style.fontFamily
              font.pixelSize: 14
              visible: item.isCategory || (modelData.submenu !== undefined && modelData.submenu !== null)
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: item.isHovered = true
            onExited: item.isHovered = false
            onClicked: {
              root.selectedIndex = index;
              root.activateSelected();
            }
          }
        }

        // Empty state
        Text {
          anchors.centerIn: parent
          text: root.currentMode === "apps" 
                ? (ApplicationsService.isLoaded ? "No apps found" : "Loading...")
                : "No items"
          color: Color.mOnSurfaceVariant
          font.family: Style.fontFamily
          font.pixelSize: 13
          opacity: 0.6
          visible: list.count === 0
        }
      }
    }
  }
}
