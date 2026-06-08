# Shopping List App -- Style Guide

> Living document. Updated as Flutter and widget styling evolves.

## Color Palette

PantryPalooza palette mapped to Flutter `ColorScheme` tokens.

| Token | Hex | ColorScheme slot | Use |
|---|---|---|---|
| slate-blue | `#3D5F8F` | `primary` | Interactive elements (buttons, toggles, links) |
| terracotta | `#A3412F` | `secondary` | Active / processing / spending feedback |
| moss-green | `#556347` | `tertiary` | Success / available / ready feedback |
| near-black | `#151514` | `onSurface` | Primary text on light surfaces |
| warm off-white | `#F2F0E8` | `surface` | Subtle backgrounds |
| white | `#FFFFFF` | -- | Light backgrounds (decorative use only). Not mapped to any ColorScheme slot -- reserved for overlays on top of surfaces (e.g., SnackBar). |

System feedback colors (red for error, orange for warning, green for success)
are **not** part of the custom palette -- leave as Material defaults.

### Implementation

```dart
final colorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF3D5F8F),
  primary: const Color(0xFF3D5F8F),    // slate-blue
  secondary: const Color(0xFFA3412F),  // terracotta
  tertiary: const Color(0xFF556347),   // moss-green
  surface: const Color(0xFFF2F0E8),    // warm off-white
  onSurface: const Color(0xFF151514),  // near-black
);
```

## Typography

| Role | Font | Weight | Slots |
|---|---|---|---|
| Headings | Merriweather | 400 (display-small, headline-small, title-medium/small) / 700 (display-large/medium, headline-large/medium, title-large) | `display*`, `headline*`, `title*` |
| Body | System (Roboto on Android) | 400 | `body*` |
| Labels | System (Roboto on Android) | 500 | `label*` |

Font asset paths (declared in `pubspec.yaml`):
- `fonts/Merriweather-Regular.ttf` (weight 400)
- `fonts/Merriweather-Bold.ttf` (weight 700)

## AppBar

- Background: `colorScheme.primary` (slate-blue)
- Foreground: `colorScheme.onPrimary` (white)
- Title: Merriweather Bold, 22pt

## Content Layout

- Max content width: 896px (via `ConstrainedBox(maxWidth: 896)` centered on wide screens)
- Spacing adapts via Flutter's default responsive behavior; tighter on narrow screens, more generous on tablets

## Widget (Android AppWidget / Jetpack Glance)

Glance widgets are limited to a subset of Compose rendering (`RemoteViews`-backed).
The palette is applied directly in Kotlin code:

| Element | Color token | Value |
|---|---|---|
| Background | `warmOffWhite` | `#F2F0E8` (gray-light) |
| Title | `slateBlue` | `#3D5F8F` (primary) |
| Checkbox unchecked | `slateBlue` | `#3D5F8F` (primary) |
| Checkbox checked | `mossGreen` | `#556347` (tertiary / success) |
| Item name active | `nearBlack` | `#151514` (onSurface) |
| Item name completed | `Color.Gray` | Material gray (not custom) |
| Empty state text | `Color.Gray` | Material gray |

### Glance limitations

- No access to Flutter `ThemeData` -- colors are hardcoded as `Color` constants
- No custom font support via Glance without setting up Android `res/font/` resources;
  widget title uses bold system font (Roboto on Android)
- Unicode characters `☐` / `☑` serve as checkbox glyphs instead of Material Checkbox
