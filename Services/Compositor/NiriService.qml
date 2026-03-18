import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

/*
 * Niruv Niri Service - Communicates with Niri compositor via IPC
 * Provides workspace information and switching functionality
 */
Item {
  id: root

  property ListModel workspaces: ListModel {}
  property bool eventStreamSubscribed: false
  property bool isInitialized: false
  property int reconnectDelayMs: 1000
  readonly property int maxReconnectDelayMs: 15000

  signal workspacesUpdated

  function initialize() {
    if (isInitialized) return;
    isInitialized = true;

    if (!Quickshell.env("NIRI_SOCKET")) {
      Logger.w("NiriService", "NIRI_SOCKET is not set; compositor IPC disabled");
      return;
    }

    niriEventStream.connected = true;
    niriCommandSocket.connected = true;

    startEventStream();
    updateWorkspaces();
    Logger.i("NiriService", "Service started");
  }

  function sendSocketCommand(sock, command) {
    if (!sock.connected) {
      scheduleReconnect();
      return;
    }

    sock.write(JSON.stringify(command) + "\n");
    sock.flush();
  }

  function startEventStream() {
    if (eventStreamSubscribed) return;
    sendSocketCommand(niriEventStream, "EventStream");
    eventStreamSubscribed = true;
  }

  function updateWorkspaces() {
    sendSocketCommand(niriCommandSocket, "Workspaces");
  }

  function recollectWorkspaces(workspacesData) {
    const workspacesList = [];

    for (const ws of workspacesData) {
      workspacesList.push({
        "id": ws.id,
        "idx": ws.idx,
        "name": ws.name || "",
        "output": ws.output || "",
        "isFocused": ws.is_focused === true,
        "isActive": ws.is_active === true,
        "isOccupied": ws.active_window_id ? true : false
      });
    }

    workspacesList.sort((a, b) => {
      if (a.output !== b.output) {
        return a.output.localeCompare(b.output);
      }
      return a.idx - b.idx;
    });

    workspaces.clear();
    for (var i = 0; i < workspacesList.length; i++) {
      workspaces.append(workspacesList[i]);
    }

    workspacesUpdated();
  }

  function switchToWorkspace(workspace) {
    try {
      Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", workspace.idx.toString()]);
    } catch (e) {
      Logger.e("NiriService", "Failed to switch workspace:", e);
    }
  }

  function scheduleReconnect() {
    if (!isInitialized || reconnectTimer.running) return;
    reconnectTimer.interval = reconnectDelayMs;
    reconnectTimer.start();
    reconnectDelayMs = Math.min(reconnectDelayMs * 2, maxReconnectDelayMs);
  }

  function reconnectNow() {
    if (!isInitialized) return;
    niriCommandSocket.connected = false;
    niriEventStream.connected = false;
    eventStreamSubscribed = false;

    niriCommandSocket.connected = true;
    niriEventStream.connected = true;

    startEventStream();
    updateWorkspaces();
  }

  Timer {
    id: reconnectTimer
    repeat: false
    onTriggered: reconnectNow()
  }

  // Command socket for requests
  Socket {
    id: niriCommandSocket
    path: Quickshell.env("NIRI_SOCKET")
    connected: false

    onConnectedChanged: {
      if (!connected) {
        scheduleReconnect();
      } else {
        reconnectDelayMs = 1000;
      }
    }

    parser: SplitParser {
      onRead: function (line) {
        try {
          const data = JSON.parse(line);

          if (data && data.Ok) {
            const res = data.Ok;
            if (res.Workspaces) {
              recollectWorkspaces(res.Workspaces);
            }
          } else {
            Logger.e("NiriService", "Niri returned an error:", data.Err);
          }
        } catch (e) {
          Logger.e("NiriService", "Failed to parse data from socket:", e);
        }
      }
    }
  }

  // Event stream socket for real-time updates
  Socket {
    id: niriEventStream
    path: Quickshell.env("NIRI_SOCKET")
    connected: false

    onConnectedChanged: {
      if (!connected) {
        eventStreamSubscribed = false;
        scheduleReconnect();
      } else {
        reconnectDelayMs = 1000;
        startEventStream();
      }
    }

    parser: SplitParser {
      onRead: data => {
        try {
          const event = JSON.parse(data.trim());

          if (event.WorkspacesChanged) {
            recollectWorkspaces(event.WorkspacesChanged.workspaces);
          } else if (event.WorkspaceActivated) {
            updateWorkspaces();
          }
        } catch (e) {
          Logger.e("NiriService", "Error parsing event stream:", e);
        }
      }
    }
  }
}
