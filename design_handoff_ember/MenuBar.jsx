// MenuBar.jsx — The menu bar icon + dropdown, as a reference frame.
// The icon lives in a faux macOS menu bar; the dropdown is what falls from it.

function MenuBar({ theme, open = true }) {
  const items = [
    { label: 'Take Break Now', shortcut: '⌘ B' },
    { label: 'Skip Next Break', shortcut: '⌘ S' },
    { label: 'Pause for 1 Hour', shortcut: '⌘ P' },
    { divider: true },
    { label: 'Settings…', shortcut: '⌘ ,', icon: 'settings', active: true },
    { label: 'About EyeBreak' },
    { divider: true },
    { label: 'Quit EyeBreak', shortcut: '⌘ Q', icon: 'quit' },
  ];

  return (
    <div style={{ width: 260, fontFamily: theme.fontBody }}>
      {/* Faux menu bar strip */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          height: 24,
          padding: '0 10px',
          background: 'rgba(28, 22, 18, 0.85)',
          backdropFilter: 'blur(20px)',
          borderRadius: '6px 6px 0 0',
          borderBottom: `0.5px solid ${theme.border}`,
          color: theme.text,
          fontSize: 12,
          fontWeight: 500,
        }}
      >
        <span style={{ opacity: 0.8 }}></span>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          {/* Active menu bar EyeBreak icon */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 5,
              padding: '2px 6px',
              borderRadius: 4,
              background: theme.accentSoft,
            }}
          >
            <EyeGlyph color={theme.accent} size={13} />
            <span style={{ fontSize: 11, fontFamily: theme.fontMono, color: theme.accent }}>15:53</span>
          </div>
          <span style={{ opacity: 0.5 }}>󰂯</span>
          <span style={{ opacity: 0.5, fontSize: 11, fontFamily: theme.fontMono }}>100%</span>
          <span style={{ opacity: 0.5 }}>Wed 16:24</span>
        </div>
      </div>

      {/* Dropdown */}
      {open && (
        <div
          style={{
            marginTop: 4,
            marginLeft: 100,
            width: 220,
            background: theme.bg,
            borderRadius: 8,
            boxShadow: `
              0 0 0 0.5px ${theme.borderStrong},
              0 12px 32px rgba(0,0,0,0.5),
              inset 0 0.5px 0 rgba(255,255,255,0.05)
            `,
            padding: 5,
            overflow: 'hidden',
          }}
        >
          {items.map((item, i) => {
            if (item.divider) {
              return (
                <div
                  key={i}
                  style={{
                    height: 1,
                    background: theme.border,
                    margin: '5px 2px',
                  }}
                />
              );
            }
            return (
              <div
                key={i}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '5px 9px',
                  borderRadius: 5,
                  background: item.active ? theme.accent : 'transparent',
                  color: item.active ? theme.accentText : theme.text,
                  fontSize: 12,
                  fontWeight: item.active ? 500 : 400,
                  letterSpacing: '-0.01em',
                  cursor: 'default',
                }}
              >
                <span>{item.label}</span>
                {item.shortcut && (
                  <span
                    style={{
                      fontSize: 11,
                      fontFamily: theme.fontMono,
                      opacity: item.active ? 0.85 : 0.45,
                      letterSpacing: '0.02em',
                    }}
                  >
                    {item.shortcut}
                  </span>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

window.MenuBar = MenuBar;
