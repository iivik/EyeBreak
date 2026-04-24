// Three warm-zen dark themes for EyeBreak.
// Each theme is a flat object of design tokens consumed by Settings + BreakScreen + MenuBar.

const THEMES = {
  // ──────────────────────────────────────────────
  // EMBER — deep warm ink, amber accent. Refined + Mac-native.
  // ──────────────────────────────────────────────
  ember: {
    name: 'Ember',
    tagline: 'Deep ink · amber accent',
    // Window surface — layered warm near-blacks
    bg: '#1a1613',
    bgElev: '#221d19',
    bgSunken: '#15110e',
    border: 'rgba(255, 220, 180, 0.08)',
    borderStrong: 'rgba(255, 220, 180, 0.14)',
    // Text
    text: '#f4ead9',
    textMuted: 'rgba(244, 234, 217, 0.62)',
    textDim: 'rgba(244, 234, 217, 0.38)',
    // Accent — warm amber
    accent: '#e8a87c',
    accentHover: '#f0b48a',
    accentSoft: 'rgba(232, 168, 124, 0.14)',
    accentText: '#1a1613',
    // Category label (section headers in popover)
    label: '#d9925f',
    // Break screen
    breakBg: 'radial-gradient(ellipse at 50% 55%, #2a1d14 0%, #0d0806 70%, #050302 100%)',
    breakAccent: '#f4b88a',
    breakText: '#f4ead9',
    breakMeta: 'rgba(244, 234, 217, 0.5)',
    breakNumber: 'rgba(244, 234, 217, 0.85)',
    // Typography
    fontBody: '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Inter", system-ui, sans-serif',
    fontDisplay: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", system-ui, sans-serif',
    fontMono: '"SF Mono", "JetBrains Mono", ui-monospace, monospace',
    // Chrome flavor
    chromeStyle: 'solid',
  },

  // ──────────────────────────────────────────────
  // DUNE — warmer taupe, peach accent, editorial serif for numbers
  // ──────────────────────────────────────────────
  dune: {
    name: 'Dune',
    tagline: 'Dusk taupe · editorial',
    bg: '#211915',
    bgElev: '#2a201b',
    bgSunken: '#1a1410',
    border: 'rgba(255, 210, 180, 0.09)',
    borderStrong: 'rgba(255, 210, 180, 0.16)',
    text: '#f3e4cf',
    textMuted: 'rgba(243, 228, 207, 0.6)',
    textDim: 'rgba(243, 228, 207, 0.36)',
    accent: '#d97a5a',
    accentHover: '#e58a6c',
    accentSoft: 'rgba(217, 122, 90, 0.16)',
    accentText: '#f3e4cf',
    label: '#c9896a',
    breakBg: 'radial-gradient(ellipse at 50% 70%, #3a2418 0%, #1a100a 55%, #070403 100%)',
    breakAccent: '#e89a76',
    breakText: '#f3e4cf',
    breakMeta: 'rgba(243, 228, 207, 0.48)',
    breakNumber: 'rgba(243, 228, 207, 0.9)',
    fontBody: '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Inter", system-ui, sans-serif',
    fontDisplay: '"Cormorant Garamond", "Iowan Old Style", "Palatino", Georgia, serif',
    fontMono: '"SF Mono", "JetBrains Mono", ui-monospace, monospace',
    chromeStyle: 'solid',
    displayIsSerif: true,
  },

  // ──────────────────────────────────────────────
  // HORIZON — near-black, candle-glow amber, minimal + atmospheric
  // ──────────────────────────────────────────────
  horizon: {
    name: 'Horizon',
    tagline: 'Near-black · candle glow',
    bg: '#0f0d0c',
    bgElev: '#16130f',
    bgSunken: '#0a0807',
    border: 'rgba(255, 200, 140, 0.07)',
    borderStrong: 'rgba(255, 200, 140, 0.13)',
    text: '#ede3d0',
    textMuted: 'rgba(237, 227, 208, 0.58)',
    textDim: 'rgba(237, 227, 208, 0.32)',
    accent: '#f0b878',
    accentHover: '#f5c38a',
    accentSoft: 'rgba(240, 184, 120, 0.12)',
    accentText: '#0f0d0c',
    label: '#c99863',
    breakBg: 'linear-gradient(180deg, #0a0806 0%, #140c06 55%, #2a1608 80%, #3a1e0a 100%)',
    breakAccent: '#f5c68c',
    breakText: '#ede3d0',
    breakMeta: 'rgba(237, 227, 208, 0.5)',
    breakNumber: 'rgba(237, 227, 208, 0.88)',
    fontBody: '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Inter", system-ui, sans-serif',
    fontDisplay: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", system-ui, sans-serif',
    fontMono: '"SF Mono", "JetBrains Mono", ui-monospace, monospace',
    chromeStyle: 'solid',
  },
};

window.THEMES = THEMES;
