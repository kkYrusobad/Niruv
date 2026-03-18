pragma Singleton

import QtQuick
import Quickshell

/*
 * Niruv Colors - Gruvbox Material Dark color scheme
 * Uses Material Design 3 naming with 'm' prefix to avoid QML signal conflicts
 */
Singleton {
  id: root

  readonly property string themeVariant: {
    const variant = Settings.data.general.themeVariant;
    if (variant === "medium" || variant === "hard") {
      return variant;
    }
    return "soft";
  }

  readonly property var palette: ({
    soft: {
      primary: "#a9b665",
      secondary: "#d8a657",
      tertiary: "#89b482",
      orange: "#e78a4e",
      blue: "#7daea3",
      purple: "#d3869b",
      error: "#ea6962",
      surface: "#32302f",
      onSurface: "#dab997",
      surfaceVariant: "#3c3836",
      onSurfaceVariant: "#bdad9c",
      outline: "#7c6f64",
      shadow: "#1d2021",
      hover: "#3c3836",
      onHover: "#dab997"
    },
    medium: {
      primary: "#a9b665",
      secondary: "#d8a657",
      tertiary: "#89b482",
      orange: "#e78a4e",
      blue: "#7daea3",
      purple: "#d3869b",
      error: "#ea6962",
      surface: "#292828",
      onSurface: "#ddc7a1",
      surfaceVariant: "#32302f",
      onSurfaceVariant: "#ebdbb2",
      outline: "#665c54",
      shadow: "#1d2021",
      hover: "#3c3836",
      onHover: "#ebdbb2"
    },
    hard: {
      primary: "#a9b665",
      secondary: "#d8a657",
      tertiary: "#89b482",
      orange: "#e78a4e",
      blue: "#7daea3",
      purple: "#d3869b",
      error: "#ea6962",
      surface: "#202020",
      onSurface: "#ddc7a1",
      surfaceVariant: "#2a2827",
      onSurfaceVariant: "#ebdbb2",
      outline: "#5a524c",
      shadow: "#1d2021",
      hover: "#32302f",
      onHover: "#ebdbb2"
    }
  })

  function variantColor(key) {
    const selected = palette[themeVariant] || palette.soft;
    return selected[key] || palette.soft[key];
  }

  // --- Key Colors: Gruvbox Material Dark Soft ---
  readonly property color mPrimary: variantColor("primary")
  readonly property color mOnPrimary: variantColor("surface")

  readonly property color mSecondary: variantColor("secondary")
  readonly property color mOnSecondary: variantColor("surface")

  readonly property color mTertiary: variantColor("tertiary")
  readonly property color mOnTertiary: variantColor("surface")

  // --- Additional Gruvbox Colors ---
  readonly property color mOrange: variantColor("orange")
  readonly property color mOnOrange: variantColor("surface")

  readonly property color mBlue: variantColor("blue")
  readonly property color mOnBlue: variantColor("surface")

  readonly property color mPurple: variantColor("purple")
  readonly property color mOnPurple: variantColor("surface")

  // --- Utility Colors ---
  readonly property color mError: variantColor("error")
  readonly property color mOnError: variantColor("surface")

  // --- Surface Colors ---
  readonly property color mSurface: variantColor("surface")
  readonly property color mOnSurface: variantColor("onSurface")

  readonly property color mSurfaceVariant: variantColor("surfaceVariant")
  readonly property color mOnSurfaceVariant: variantColor("onSurfaceVariant")

  readonly property color mOutline: variantColor("outline")
  readonly property color mShadow: variantColor("shadow")

  readonly property color mHover: variantColor("hover")
  readonly property color mOnHover: variantColor("onHover")

  // --- Absolute Colors ---
  readonly property color transparent: "transparent"
  readonly property color black: "#000000"
  readonly property color white: "#ffffff"
}
