pragma Singleton

import QtQuick
import Quickshell

import qs.Commons

/*
 * ApplicationsService - Provides app list from Quickshell's DesktopEntries
 */
Singleton {
  id: root

  // All applications from DesktopEntries
  property var allApps: []

  // Filtered results based on search query
  property var filteredApps: []

  // Current search query
  property string searchQuery: ""

  // Loading state
  property bool isLoaded: false
  property double lastLoadedAtMs: 0
  property var filterCache: ({})

  Component.onCompleted: Logger.d("ApplicationsService", "Service initialized")

  Timer {
    id: loadTimer
    interval: 100
    repeat: false
    onTriggered: loadApplications()
  }

  function ensureLoaded() {
    if (isLoaded || loadTimer.running) return;
    loadTimer.interval = 100;
    loadTimer.start();
  }

  // Simple contains match for performance
  function containsMatch(text, query) {
    if (!query) return true;
    return text.toLowerCase().includes(query.toLowerCase());
  }

  // Fuzzy match function - simple subsequence matching
  function fuzzyMatch(text, query) {
    if (!query) return true;
    const lowerText = text.toLowerCase();
    const lowerQuery = query.toLowerCase();
    let queryIndex = 0;
    for (let i = 0; i < lowerText.length && queryIndex < lowerQuery.length; i++) {
      if (lowerText[i] === lowerQuery[queryIndex]) queryIndex++;
    }
    return queryIndex === lowerQuery.length;
  }

  // Filter apps based on search query
  function filterApps(query) {
    ensureLoaded();

    if (!isLoaded) {
      filteredApps = [];
      return;
    }

    searchQuery = query;
    if (!query || query.trim() === "") {
      filteredApps = allApps.slice(0, 50); // Show first 50 apps when no query
      filterCache[""] = filteredApps;
      return;
    }

    const q = query.trim();
    const cacheKey = q.toLowerCase();
    if (filterCache[cacheKey] !== undefined) {
      filteredApps = filterCache[cacheKey];
      return;
    }

    let results = [];

    // First pass: contains match (faster)
    for (let i = 0; i < allApps.length && results.length < 50; i++) {
      const app = allApps[i];
      
      // Check keywords if available
      let keywordMatch = false;
      if (app.keywords && Array.isArray(app.keywords)) {
        for (let k = 0; k < app.keywords.length; k++) {
          if (containsMatch(app.keywords[k], q)) {
            keywordMatch = true;
            break;
          }
        }
      }

      if (containsMatch(app.name, q) || 
          containsMatch(app.execName || "", q) || 
          containsMatch(app.comment || "", q) || 
          containsMatch(app.id || "", q) ||
          keywordMatch) {
        results.push(app);
      }
    }

    // Second pass: fuzzy match if not enough results
    if (results.length < 10) {
      for (let i = 0; i < allApps.length && results.length < 50; i++) {
        const app = allApps[i];
        if (!results.includes(app) && fuzzyMatch(app.name, q)) {
          results.push(app);
        }
      }
    }

    filteredApps = results;
    filterCache[cacheKey] = results;
  }

  // Clear filter and reload apps
  function clearFilter() {
    ensureLoaded();
    searchQuery = "";
    filteredApps = allApps.slice(0, 50);
  }

  // Refresh applications from disk (call after installing new apps)
  function refreshApplications() {
    Logger.i("ApplicationsService", "Refreshing applications list...");
    isLoaded = false;
    filterCache = ({});
    allApps = [];
    filteredApps = [];
    loadApplications();
  }

  // Launch an application
  function launchApp(app) {
    if (!app) {
      Logger.w("ApplicationsService", "Cannot launch app - null app");
      return;
    }

    Logger.i("ApplicationsService", "Launching: " + app.name);

    // Use the app's execute method if available (from DesktopEntries)
    if (app._original && app._original.execute && typeof app._original.execute === 'function') {
      app._original.execute();
    } else if (app.command && Array.isArray(app.command)) {
      // Fallback to command array
      Quickshell.execDetached(app.command);
    } else {
      Logger.w("ApplicationsService", "No launch method available for: " + app.name);
    }
  }

  // Load all applications from Quickshell's DesktopEntries
  function loadApplications() {
    Logger.d("ApplicationsService", "Loading applications from DesktopEntries...");

    // Check if DesktopEntries is available
    if (typeof DesktopEntries === 'undefined') {
      Logger.w("ApplicationsService", "DesktopEntries not yet available, retrying...");
      loadTimer.interval = 500;
      loadTimer.start();
      return;
    }

    const apps = DesktopEntries.applications.values || [];
    Logger.d("ApplicationsService", "DesktopEntries returned " + apps.length + " entries");

    if (apps.length === 0) {
      // Maybe not ready yet, retry
      if (!isLoaded) {
        loadTimer.interval = 500;
        loadTimer.start();
      }
      return;
    }

    // Filter and transform apps
    allApps = [];
    filterCache = ({});
    for (let i = 0; i < apps.length; i++) {
      const app = apps[i];
      if (!app || app.noDisplay) continue;

      // Get executable name from command
      let execName = "";
      if (app.command && Array.isArray(app.command) && app.command.length > 0) {
        const cmd = app.command[0];
        const parts = cmd.split('/');
        execName = parts[parts.length - 1].split(' ')[0];
      }

      allApps.push({
        name: app.name || "Unknown",
        icon: app.icon || "application-x-executable",
        comment: app.genericName || app.comment || "",
        execName: execName,
        command: app.command,
        id: app.id,
        keywords: app.keywords || [],
        runInTerminal: app.runInTerminal,
        _original: app  // Keep reference for execute()
      });
    }

    // Sort alphabetically
    allApps.sort((a, b) => a.name.localeCompare(b.name));

    // Initialize filtered apps
    filteredApps = allApps.slice(0, 50);
    isLoaded = true;
    lastLoadedAtMs = Date.now();

    Logger.i("ApplicationsService", "Loaded " + allApps.length + " applications");
  }
}
