pragma Singleton

import QtQuick
import Quickshell
import "../Services/Power"

Singleton {
  id: root

  // Font size
  readonly property real fontSizeXXS: 8
  readonly property real fontSizeXS: 9
  readonly property real fontSizeS: 10
  readonly property real fontSizeM: 11
  readonly property real fontSizeL: 13
  readonly property real fontSizeXL: 16
  readonly property real fontSizeXXL: 18
  readonly property real fontSizeXXXL: 24

  // Font family
  readonly property string fontFamily: "JetBrainsMono Nerd Font"

  // Font weight
  readonly property int fontWeightRegular: 400
  readonly property int fontWeightMedium: 500
  readonly property int fontWeightSemiBold: 600
  readonly property int fontWeightBold: 700

  // Radii
  readonly property int radiusXXS: Math.round(4 * Settings.data.general.radiusRatio)
  readonly property int radiusXS: Math.round(8 * Settings.data.general.radiusRatio)
  readonly property int radiusS: Math.round(12 * Settings.data.general.radiusRatio)
  readonly property int radiusM: Math.round(16 * Settings.data.general.radiusRatio)
  readonly property int radiusL: Math.round(20 * Settings.data.general.radiusRatio)
  readonly property int screenRadius: Math.round(20 * Settings.data.general.screenRadiusRatio)

  // Border
  readonly property int borderS: Math.max(1, Math.round(1 * uiScaleRatio))
  readonly property int borderM: Math.max(1, Math.round(2 * uiScaleRatio))
  readonly property int borderL: Math.max(1, Math.round(3 * uiScaleRatio))

  // Margins (for margins and spacing)
  readonly property int marginXXS: Math.round(2 * uiScaleRatio)
  readonly property int marginXS: Math.round(4 * uiScaleRatio)
  readonly property int marginS: Math.round(6 * uiScaleRatio)
  readonly property int marginM: Math.round(9 * uiScaleRatio)
  readonly property int marginL: Math.round(13 * uiScaleRatio)
  readonly property int marginXL: Math.round(18 * uiScaleRatio)

  // Opacity
  readonly property real opacityNone: 0.0
  readonly property real opacityLight: 0.25
  readonly property real opacityMedium: 0.5
  readonly property real opacityHeavy: 0.75
  readonly property real opacityAlmost: 0.95
  readonly property real opacityFull: 1.0

  // Shadows
  readonly property real shadowOpacity: 0.85
  readonly property real shadowBlur: 1.0
  readonly property int shadowBlurMax: 22
  readonly property real shadowHorizontalOffset: Settings.data.general.shadowOffsetX
  readonly property real shadowVerticalOffset: Settings.data.general.shadowOffsetY

  // Motion profile
  readonly property string animationMode: {
    const mode = Settings.data.general.animationMode;
    if (mode === "subtle" || mode === "expressive") {
      return mode;
    }
    return "balanced";
  }
  readonly property bool animationsDisabled: Settings.data.general.animationDisabled || PowerProfileService.performanceMode
  readonly property real animationModeFactor: {
    switch (animationMode) {
      case "subtle": return 0.85;
      case "expressive": return 1.2;
      case "balanced":
      default:
        return 1.0;
    }
  }

  // Shared easing tokens for consistent interaction feel
  readonly property int easingStandard: Easing.InOutCubic
  readonly property int easingEnter: Easing.OutCubic
  readonly property int easingExit: Easing.InCubic
  readonly property int easingEmphasized: Easing.OutBack

  // Animation duration (ms)
  readonly property int animationFaster: animationsDisabled ? 0 : Math.round((75 * animationModeFactor) / Settings.data.general.animationSpeed)
  readonly property int animationFast: animationsDisabled ? 0 : Math.round((150 * animationModeFactor) / Settings.data.general.animationSpeed)
  readonly property int animationNormal: animationsDisabled ? 0 : Math.round((300 * animationModeFactor) / Settings.data.general.animationSpeed)
  readonly property int animationSlow: animationsDisabled ? 0 : Math.round((450 * animationModeFactor) / Settings.data.general.animationSpeed)
  readonly property int animationSlowest: animationsDisabled ? 0 : Math.round((750 * animationModeFactor) / Settings.data.general.animationSpeed)

  // Delays
  readonly property int tooltipDelay: 300
  readonly property int tooltipDelayLong: 1200
  readonly property int pillDelay: 500

  // Widgets base size
  readonly property real baseWidgetSize: 33
  readonly property real sliderWidth: 200

  readonly property real uiScaleRatio: Settings.data.general.scaleRatio

  // Bar Dimensions
  readonly property real barHeight: {
    switch (Settings.data.bar.density) {
      case "mini":
      return (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? 22 : 20;
      case "compact":
      return (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? 27 : 25;
      case "comfortable":
      return (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? 39 : 37;
      default:
      case "default":
      return (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? 33 : 31;
    }
  }
  readonly property real capsuleHeight: {
    switch (Settings.data.bar.density) {
      case "mini":
      return Math.round(barHeight * 1.0);
      case "compact":
      return Math.round(barHeight * 0.85);
      case "comfortable":
      return Math.round(barHeight * 0.73);
      default:
      case "default":
      return Math.round(barHeight * 0.82);
    }
  }
  readonly property color capsuleColor: Settings.data.bar.showCapsule ? Qt.alpha(Color.mSurfaceVariant, Settings.data.bar.capsuleOpacity) : Color.transparent
}
