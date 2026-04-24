# Handoff: EyeBreak — Ember Direction

## Overview
EyeBreak is a macOS menu bar utility that reminds the user to look 20 feet away every 20 minutes for 20 seconds (the 20-20-20 rule recommended by opticians).

This bundle specifies the **Ember** visual direction — a deep warm-ink background with an amber accent. Mac-native-adjacent: follows Mac conventions (popover with notch, segmented controls, SF system fonts, NSVisualEffectView-style menu strip) but has a distinctive brand voice. Three surfaces are specified:

1. **Menu bar icon + dropdown** — quick actions from the status item
2. **Settings popover** — full configuration UI (appears from the menu bar icon)
3. **Break screen** — the fullscreen "look away" moment every 20 minutes

## About the Design Files
The files in this bundle are **design references created in HTML** — prototypes showing intended look and behavior, not production code to copy directly. Your task is to **recreate these designs in the existing EyeBreak codebase** using its established patterns and libraries (SwiftUI / AppKit for a native Mac app, Electron/React if that's the stack, etc.). If v3 is already built, treat this as a visual redesign of existing surfaces — keep wiring/logic, replace the UI.

Do not ship the HTML itself.

## Fidelity
**High-fidelity.** Pixel-perfect mockups with final colors, typography, spacing, and interactions. Recreate the UI to these exact values using the codebase's native component library.

---

## Light / Dark / System mode

The mockups show **dark mode only** (the warm-zen Ember palette). For light mode, derive the Ember light companion using these rules:

| Token            | Dark (Ember)        | Light (Ember Light)     |
|------------------|---------------------|-------------------------|
| `bg`             | `#1a1613`           | `#faf7f2`               |
| `bgElev`         | `#221d19`           | `#ffffff`               |
| `bgSunken`       | `#15110e`           | `#f2ede5`               |
| `border`         | `rgba(255,220,180,.08)` | `rgba(40,20,0,.08)` |
| `borderStrong`   | `rgba(255,220,180,.14)` | `rgba(40,20,0,.14)` |
| `text`           | `#f4ead9`           | `#1f1a16`               |
| `textMuted`      | `rgba(244,234,217,.62)` | `rgba(31,26,22,.62)` |
| `textDim`        | `rgba(244,234,217,.38)` | `rgba(31,26,22,.42)` |
| `accent`         | `#e8a87c`           | `#c9722d` (darker for AA contrast on light) |
| `accentHover`    | `#f0b48a`           | `#b8611f`               |
| `accentSoft`     | `rgba(232,168,124,.14)` | `rgba(201,114,45,.12)` |
| `accentText`     | `#1a1613`           | `#ffffff`               |
| `label`          | `#d9925f`           | `#a8662f`               |

Bind to `NSApp.effectiveAppearance` (SwiftUI: `@Environment(\.colorScheme)`) and follow the system setting by default. Expose no user toggle unless product wants one — this is a utility, and following System is the right default.

The **break screen** stays dark in both modes. The screen-takeover is a restful moment and the warm dark gradient is core to the brand — do not produce a light version of the break overlay.

---

## Screens / Views

### 1. Menu bar icon (status item)

The icon lives in the macOS menu bar. It's an eye glyph next to a countdown text.

- **Glyph**: outlined eye, 16×16 at 1x. Stroke 1.3pt, color = `text` (adapts to menu bar appearance). Inner pupil is a filled circle, 2.7pt radius. See `EyeGlyph` in `Settings.jsx`.
- **Countdown text**: monospaced, 11pt, color `textMuted`. Format: `7m` when >1min, `45s` when <1min, blank while paused.
- **Pill background** when a break is imminent (<2 min): padding `2px 6px`, radius 4, background `accentSoft`, text color `accent`.
- Click opens the dropdown. `⌘`-click, or right-click, also opens it.

### 2. Menu bar dropdown

Standard Mac `NSMenu` — recreate with native menu APIs, not a custom popover. Items:

| Label              | Shortcut | Notes                                 |
|--------------------|----------|---------------------------------------|
| Take Break Now     | ⌘B       | Triggers break screen immediately     |
| Skip Next Break    | ⌘S       | Skips the next scheduled break only   |
| Pause for 1 Hour   | ⌘P       | Pauses reminders for 60 min           |
| —                  |          | (separator)                           |
| Settings…          | ⌘,       | Opens settings popover                |
| About EyeBreak     |          | Standard About window                 |
| —                  |          | (separator)                           |
| Quit EyeBreak      | ⌘Q       |                                       |

The mock shows the Settings… row highlighted in amber (`accent` / `accentText`) — this is just hover/focus state; standard `NSMenu` highlight colors are acceptable. Do not custom-draw the menu unless the codebase already does.

### 3. Settings popover

The Settings popover is anchored to the menu bar icon with a 12px notch. Width **384pt**, height grows to fit content (≈620pt).

**Container**
- Background: `bg` (`#1a1613`)
- Corner radius: 12pt
- Border: 0.5pt `borderStrong`
- Shadow: `0 20px 50px rgba(0,0,0,0.55), 0 4px 14px rgba(0,0,0,0.35)`, plus `inset 0 0.5px 0 rgba(255,255,255,0.05)` for the subtle top-edge highlight
- Notch: 12×12 square rotated 45°, anchored top-center, same fill as bg, same inset border. In AppKit this is the popover arrow — use the default.

**Header** (padding 14pt top, 18pt sides, 12pt bottom, bottom border 0.5pt `border`)
- Left cluster (9pt gap): Eye glyph 16pt in `accent` → "EyeBreak" 14pt / 600 weight / `text` → "v1.2" 11pt / mono / `textDim`
- Right: **Status pill** — rounded (99pt), padding `3px 9px 3px 7px`. When active: background `accentSoft`, text `accent`, 11pt mono. A 6pt dot glows (box-shadow `0 0 6px accent`). Shows `next in 7m` or `paused`.

**Body** (padding 16pt top, 18pt sides, 6pt bottom)

Each section has a **section label** above it: 10pt, weight 600, letter-spacing 0.12em, uppercase, color `#d9925f` (`label` token), 10pt bottom margin.

Rows follow a consistent pattern — label on the left (13pt / 500 / `text`), control on the right. Optional hint below label (11pt / `textMuted` / 3pt top). Default row spacing: 14pt; "tight" rows (children of a parent toggle): 10pt. When a parent toggle is off, children go to `opacity: 0.4` and `pointer-events: none`.

Section **dividers**: 1pt tall, color `border`, 18pt top/bottom margin.

**Sections in order:**

1. **Eye Break**
   - Row: "Break reminders" · hint "20-20-20 rule — recommended by opticians" · Toggle (default on)
   - Row (tight): "Interval" · Slider 10–60 min, step 5, default 20 · value label `"{n} min"` (12pt mono, min-width 44pt, right-aligned)
   - Row (tight): "Duration" · Slider 10–60 sec, step 5, default 20 · value label `"{n} sec"`

2. **Posture**
   - Row: "Posture nudges" · Toggle (default on)
   - Row (tight): "Remind every" · Slider 5–30 min, step 5, default 10

3. **Idle detection**
   - Row: "Pause when idle for" · SegmentedControl: `1 min` / `90s` / `2 min`, default `90s`

4. **Sound**
   - Row: "Break cue" · SegmentedControl: `Soothing` / `Beep` / `Silent`, default `Soothing`

5. **General**
   - Row (tight): "Start at login" · Toggle sm (default on)
   - Row (tight): "Show in Notification Center" · Toggle sm (default on)
   - Row (tight): "Respect Do Not Disturb" · Toggle sm (default on)

**Footer — stats strip**
- Top border 0.5pt `border`, background `bgSunken`, padding `11px 18px`
- Three stats in a row, 18pt gap: value (14pt / 600 / `text`, `-0.02em` tracking) above label (10pt / `textDim`, 0.04em tracking, uppercase, 500 weight)
- Mock values: **8** today · **12** day streak · **2h 40m** eyes rested
- Wire to real data: count of completed breaks today, consecutive days with ≥1 break, sum of break durations today

### 4. Break screen (fullscreen overlay)

When it's time to break, a **fullscreen** window appears on every display. Dark warm gradient background, centered content, escapable with `esc`.

- **Background**: radial gradient `radial-gradient(ellipse at 50% 55%, #2a1d14 0%, #0d0806 70%, #050302 100%)`
- **Behind the overlay**: the user's desktop is *not* hidden — overlay uses ~96% opacity so the desktop shows through faintly at ~4%. In AppKit, set the window level above normal, opaque=NO, background color with alpha.
- **Vignette**: overlaid `radial-gradient(ellipse at center, transparent 30%, rgba(0,0,0,0.45) 100%)` to focus attention center.

**Breathing rings** (purely decorative, very soft):
- Inner: 340pt circle, 1pt `breakAccent` border, opacity oscillates 0.08 ↔ 0.22 over 1.8s ease-in-out
- Outer: 460pt circle, same border, opacity 0.04 ↔ 0.10

**Centerpiece** (vertically centered, 14pt gap):
1. **Eye glyph** 52pt. Stroke `breakAccent` (`#f4b88a`), 1.5pt. Inner pupil filled `breakAccent`, with a 2pt dark highlight offset slightly. Wrapped in a soft radial glow (`radial-gradient(circle, breakAccent 0%, transparent 65%)`, opacity 0.22, 6pt blur, 14pt bleed).
2. **"Look Away"** — 54pt, weight 300, letter-spacing -0.035em, SF Pro Display, color `breakText` (`#f4ead9`).
3. **Meta row** — 12pt / 500 / `breakMeta`, letter-spacing 0.02em: `20 feet · 20 seconds · every 20 minutes` (dots at 40% opacity, 12pt gap between segments).
4. **Countdown** (22pt top margin from meta):
   - Big number: 56pt, weight 200, `breakNumber` (`rgba(244,234,217,0.85)`), letter-spacing -0.03em, `font-feature-settings: "tnum"` for stable glyph widths as it counts down.
   - Label: "SECONDS" — 10pt, weight 500, uppercase, letter-spacing 0.22em, `breakMeta`, 4pt top margin.

**Corners**
- Top-left: 6pt amber dot (glow `0 0 6px breakAccent`) + "EYEBREAK" 10pt / 600 / 0.22em tracking / uppercase / `breakMeta` at 55% opacity.
- Top-right: current time "15:53" in mono, 11pt, `breakMeta` at 70% opacity.
- Bottom-center: `[esc]` kbd hint (mono 10pt, padded `1px 6px`, radius 4, bg `rgba(255,255,255,0.06)`) + "to skip" — both at `breakMeta` 70% opacity.

**Behavior**
- Covers every connected display (one window per screen).
- Countdown runs from the configured duration (default 20) down to 0, then auto-dismisses.
- `esc` skips the break early; log this to stats as a skipped break.
- Clicking does nothing — the whole point is to look *away* from the screen.
- No audio here — the break cue sound plays when the overlay appears, driven by Settings → Sound.

---

## Interactions & Behavior

- **Toggle**: 36×22pt (sm: 30×18pt). Off → on: knob slides from left to right over 180ms `cubic-bezier(.3,.7,.3,1)`. Track fill crossfades from `rgba(255,255,255,0.09)` to `accent` over 180ms.
- **Slider**: drag or click-to-seek. Snaps to step. Handle is a 14pt white circle with a 1pt-offset drop shadow. Track fill grows from left in `accent`.
- **SegmentedControl**: container `rgba(255,255,255,0.04)` with inset border; active segment gets `accent` background + `accentText` text + subtle shadow. Transition background/color 120ms.
- **Status pill**: recompute every minute; format "next in {n}m" for >60s, "now" within 10s of trigger, "paused" when reminders are off.
- **Popover**: opens on status item click. Closes on outside click or `esc`. In AppKit, use `NSPopover` with `behavior = .transient`.

## State Management

```
settings {
  eyeBreak: { enabled: bool, intervalMin: int(5–60), durationSec: int(10–60) }
  posture:  { enabled: bool, intervalMin: int(5–30) }
  idle:     { pauseAfterSec: 60 | 90 | 120 }
  sound:    'music' | 'beep' | 'silent'
  general:  { startAtLogin: bool, showInNotifCenter: bool, respectDnd: bool }
}

runtime {
  nextBreakAt: Date
  isPaused: bool
  pausedUntil: Date | null     // for "Pause for 1 Hour"
}

stats {
  todayCount: int              // breaks completed today (midnight-reset)
  streakDays: int              // consecutive days with ≥1 break
  todayRestedSec: int          // sum of completed break durations
}
```

Persist `settings` to `UserDefaults` / app preferences. Stats to a small SQLite or JSON file in Application Support. Reset `todayCount`/`todayRestedSec` at local midnight.

---

## Design Tokens (Ember — dark)

```
/* Surfaces */
--bg:            #1a1613;
--bg-elev:       #221d19;
--bg-sunken:     #15110e;
--border:        rgba(255, 220, 180, 0.08);
--border-strong: rgba(255, 220, 180, 0.14);

/* Text */
--text:          #f4ead9;
--text-muted:    rgba(244, 234, 217, 0.62);
--text-dim:      rgba(244, 234, 217, 0.38);

/* Accent */
--accent:        #e8a87c;
--accent-hover:  #f0b48a;
--accent-soft:   rgba(232, 168, 124, 0.14);
--accent-text:   #1a1613;
--label:         #d9925f;

/* Break screen */
--break-bg:      radial-gradient(ellipse at 50% 55%, #2a1d14 0%, #0d0806 70%, #050302 100%);
--break-accent:  #f4b88a;
--break-text:    #f4ead9;
--break-meta:    rgba(244, 234, 217, 0.50);
--break-number:  rgba(244, 234, 217, 0.85);
```

**Typography**
- Body: SF Pro Text (system) — 10, 11, 12, 13, 14pt used
- Display: SF Pro Display (system) — 54pt for "Look Away"
- Mono: SF Mono (system) — countdowns, timers, "v1.2"

**Spacing scale** (used in popover): 2, 4, 6, 8, 10, 11, 12, 14, 16, 18, 22pt. Standard row padding: 14pt vertical.

**Radii**: 4 (small pills/kbd), 5 (segmented buttons), 6 (swatches), 7 (segmented container), 8 (menu dropdown), 10 (break screen cards), 12 (popover, big cards), 99 (status pill).

**Shadows**
- Popover: `0 20px 50px rgba(0,0,0,.55), 0 4px 14px rgba(0,0,0,.35), inset 0 0.5px 0 rgba(255,255,255,.05)`
- Menu dropdown: `0 12px 32px rgba(0,0,0,.5)`
- Slider handle: `0 1px 3px rgba(0,0,0,.4), 0 0 0 0.5px rgba(0,0,0,.15)`

---

## Assets

- **EyeGlyph** (SVG) — see `Settings.jsx`. 20×20 viewBox. Used at 13–52pt throughout.
- No other image assets. All icons/decoration are SVG or CSS.

## Files

HTML design references in this bundle:
- `index.html` — renders all three directions on a design canvas. Open in a browser to preview.
- `theme.jsx` — token definitions for all three directions (use `ember`).
- `Settings.jsx` — settings popover component + primitives (Toggle, Slider, SegmentedControl, StatusPill).
- `BreakScreen.jsx` — break overlay component.
- `MenuBar.jsx` — menu dropdown reference.
- `design-canvas.jsx` — presentation wrapper (not part of the product).

**Only the Ember direction is in scope for implementation.** Dune and Horizon are alternate directions that were not selected.
