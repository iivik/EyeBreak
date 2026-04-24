// Settings.jsx — EyeBreak settings popover.
// Mac-native-adjacent popover with a notch, organized into sections.
// Themed via a `theme` prop (see theme.jsx).

const { useState, useRef, useEffect } = React;

// ─── Tiny themed primitives ────────────────────────────────

function Toggle({ on, onChange, theme, size = 'md' }) {
  const w = size === 'sm' ? 30 : 36;
  const h = size === 'sm' ? 18 : 22;
  const knob = h - 4;
  return (
    <button
      onClick={() => onChange(!on)}
      style={{
        width: w,
        height: h,
        borderRadius: h / 2,
        border: 'none',
        padding: 0,
        cursor: 'pointer',
        background: on ? theme.accent : 'rgba(255,255,255,0.09)',
        position: 'relative',
        transition: 'background .18s ease',
        flexShrink: 0,
        boxShadow: on ? `0 0 0 0.5px ${theme.accent}` : `inset 0 0 0 0.5px ${theme.border}`,
      }}
    >
      <span
        style={{
          position: 'absolute',
          top: 2,
          left: on ? w - knob - 2 : 2,
          width: knob,
          height: knob,
          borderRadius: knob / 2,
          background: on ? '#fff' : '#d8d2c8',
          transition: 'left .18s cubic-bezier(.3,.7,.3,1)',
          boxShadow: '0 1px 2px rgba(0,0,0,0.35), 0 0 0 0.5px rgba(0,0,0,0.2)',
        }}
      />
    </button>
  );
}

function Slider({ value, min, max, step = 1, onChange, theme, formatValue }) {
  const pct = ((value - min) / (max - min)) * 100;
  const ref = useRef(null);
  const [dragging, setDragging] = useState(false);

  const setFromClientX = (clientX) => {
    const rect = ref.current.getBoundingClientRect();
    const raw = ((clientX - rect.left) / rect.width) * (max - min) + min;
    const stepped = Math.round(raw / step) * step;
    onChange(Math.max(min, Math.min(max, stepped)));
  };

  useEffect(() => {
    if (!dragging) return;
    const move = (e) => setFromClientX(e.clientX);
    const up = () => setDragging(false);
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
    return () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
    };
  }, [dragging]);

  return (
    <div
      ref={ref}
      onMouseDown={(e) => {
        setDragging(true);
        setFromClientX(e.clientX);
      }}
      style={{
        position: 'relative',
        height: 18,
        cursor: 'pointer',
        flex: 1,
        display: 'flex',
        alignItems: 'center',
      }}
    >
      <div
        style={{
          width: '100%',
          height: 4,
          borderRadius: 2,
          background: 'rgba(255,255,255,0.06)',
          boxShadow: `inset 0 0 0 0.5px ${theme.border}`,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: 0,
          height: 4,
          width: `${pct}%`,
          borderRadius: 2,
          background: theme.accent,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: `calc(${pct}% - 7px)`,
          width: 14,
          height: 14,
          borderRadius: 7,
          background: '#fff',
          boxShadow: '0 1px 3px rgba(0,0,0,0.4), 0 0 0 0.5px rgba(0,0,0,0.15)',
          transition: dragging ? 'none' : 'left .08s linear',
        }}
      />
    </div>
  );
}

function SegmentedControl({ options, value, onChange, theme }) {
  return (
    <div
      style={{
        display: 'inline-flex',
        background: 'rgba(255,255,255,0.04)',
        borderRadius: 7,
        padding: 2,
        boxShadow: `inset 0 0 0 0.5px ${theme.border}`,
        gap: 1,
      }}
    >
      {options.map((opt) => {
        const active = opt.value === value;
        return (
          <button
            key={opt.value}
            onClick={() => onChange(opt.value)}
            style={{
              background: active ? theme.accent : 'transparent',
              color: active ? theme.accentText : theme.text,
              border: 'none',
              padding: '4px 11px',
              borderRadius: 5,
              fontSize: 12,
              fontWeight: active ? 590 : 500,
              fontFamily: theme.fontBody,
              letterSpacing: '-0.01em',
              cursor: 'pointer',
              transition: 'background .12s, color .12s',
              boxShadow: active ? '0 1px 2px rgba(0,0,0,0.25)' : 'none',
            }}
          >
            {opt.label}
          </button>
        );
      })}
    </div>
  );
}

function SectionLabel({ children, theme }) {
  return (
    <div
      style={{
        fontSize: 10,
        fontWeight: 600,
        letterSpacing: '0.12em',
        color: theme.label,
        textTransform: 'uppercase',
        marginBottom: 10,
        fontFamily: theme.fontBody,
      }}
    >
      {children}
    </div>
  );
}

function Row({ label, hint, right, theme, tight }) {
  return (
    <div style={{ marginBottom: tight ? 10 : 14 }}>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: 12,
        }}
      >
        <div
          style={{
            fontSize: 13,
            fontWeight: 500,
            color: theme.text,
            fontFamily: theme.fontBody,
            letterSpacing: '-0.01em',
          }}
        >
          {label}
        </div>
        {right}
      </div>
      {hint && (
        <div
          style={{
            fontSize: 11,
            color: theme.textMuted,
            marginTop: 3,
            fontFamily: theme.fontBody,
            letterSpacing: '-0.005em',
          }}
        >
          {hint}
        </div>
      )}
    </div>
  );
}

function Divider({ theme }) {
  return <div style={{ height: 1, background: theme.border, margin: '18px 0' }} />;
}

// ─── Main Settings popover ────────────────────────────────

function SettingsPopover({ theme, compact = false }) {
  const [breakOn, setBreakOn] = useState(true);
  const [interval, setInterval] = useState(20);
  const [duration, setDuration] = useState(20);
  const [postureOn, setPostureOn] = useState(true);
  const [postureEvery, setPostureEvery] = useState(10);
  const [idlePause, setIdlePause] = useState('90');
  const [sound, setSound] = useState('music');
  const [startAtLogin, setStartAtLogin] = useState(true);
  const [showNotifs, setShowNotifs] = useState(true);
  const [respectDnd, setRespectDnd] = useState(true);

  const W = compact ? 360 : 384;

  return (
    <div
      style={{
        width: W,
        background: theme.bg,
        borderRadius: 12,
        boxShadow: `
          0 0 0 0.5px ${theme.borderStrong},
          0 20px 50px rgba(0,0,0,0.55),
          0 4px 14px rgba(0,0,0,0.35),
          inset 0 0.5px 0 rgba(255,255,255,0.05)
        `,
        fontFamily: theme.fontBody,
        color: theme.text,
        overflow: 'hidden',
        position: 'relative',
      }}
    >
      {/* Notch / anchor */}
      <div
        style={{
          position: 'absolute',
          top: -6,
          left: '50%',
          transform: 'translateX(-50%) rotate(45deg)',
          width: 12,
          height: 12,
          background: theme.bg,
          boxShadow: `-0.5px -0.5px 0 0.5px ${theme.borderStrong}`,
        }}
      />

      {/* Header */}
      <div
        style={{
          padding: '14px 18px 12px',
          borderBottom: `0.5px solid ${theme.border}`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
          <EyeGlyph color={theme.accent} size={16} />
          <div
            style={{
              fontSize: 14,
              fontWeight: 600,
              letterSpacing: '-0.01em',
              color: theme.text,
            }}
          >
            EyeBreak
          </div>
          <div
            style={{
              fontSize: 11,
              color: theme.textDim,
              fontFamily: theme.fontMono,
              marginTop: 1,
            }}
          >
            v1.2
          </div>
        </div>
        <StatusPill theme={theme} on={breakOn} minutesUntil={7} />
      </div>

      {/* Body */}
      <div style={{ padding: '16px 18px 6px' }}>
        {/* EYE BREAK */}
        <SectionLabel theme={theme}>Eye Break</SectionLabel>

        <Row
          theme={theme}
          label="Break reminders"
          hint="20-20-20 rule — recommended by opticians"
          right={<Toggle theme={theme} on={breakOn} onChange={setBreakOn} />}
        />

        <div style={{ opacity: breakOn ? 1 : 0.4, pointerEvents: breakOn ? 'auto' : 'none' }}>
          <Row
            theme={theme}
            tight
            label="Interval"
            right={
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1, maxWidth: 220 }}>
                <Slider theme={theme} value={interval} min={10} max={60} step={5} onChange={setInterval} />
                <div
                  style={{
                    fontSize: 12,
                    fontWeight: 500,
                    color: theme.text,
                    fontFamily: theme.fontMono,
                    minWidth: 44,
                    textAlign: 'right',
                  }}
                >
                  {interval} min
                </div>
              </div>
            }
          />
          <Row
            theme={theme}
            tight
            label="Duration"
            right={
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1, maxWidth: 220 }}>
                <Slider theme={theme} value={duration} min={10} max={60} step={5} onChange={setDuration} />
                <div
                  style={{
                    fontSize: 12,
                    fontWeight: 500,
                    color: theme.text,
                    fontFamily: theme.fontMono,
                    minWidth: 44,
                    textAlign: 'right',
                  }}
                >
                  {duration} sec
                </div>
              </div>
            }
          />
        </div>

        <Divider theme={theme} />

        {/* POSTURE */}
        <SectionLabel theme={theme}>Posture</SectionLabel>
        <Row
          theme={theme}
          label="Posture nudges"
          right={<Toggle theme={theme} on={postureOn} onChange={setPostureOn} />}
        />
        <div
          style={{
            opacity: postureOn ? 1 : 0.4,
            pointerEvents: postureOn ? 'auto' : 'none',
          }}
        >
          <Row
            theme={theme}
            tight
            label="Remind every"
            right={
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1, maxWidth: 220 }}>
                <Slider theme={theme} value={postureEvery} min={5} max={30} step={5} onChange={setPostureEvery} />
                <div
                  style={{
                    fontSize: 12,
                    fontWeight: 500,
                    color: theme.text,
                    fontFamily: theme.fontMono,
                    minWidth: 44,
                    textAlign: 'right',
                  }}
                >
                  {postureEvery} min
                </div>
              </div>
            }
          />
        </div>

        <Divider theme={theme} />

        {/* IDLE */}
        <SectionLabel theme={theme}>Idle detection</SectionLabel>
        <Row
          theme={theme}
          label="Pause when idle for"
          right={
            <SegmentedControl
              theme={theme}
              value={idlePause}
              onChange={setIdlePause}
              options={[
                { value: '60', label: '1 min' },
                { value: '90', label: '90s' },
                { value: '120', label: '2 min' },
              ]}
            />
          }
        />

        <Divider theme={theme} />

        {/* SOUND */}
        <SectionLabel theme={theme}>Sound</SectionLabel>
        <Row
          theme={theme}
          label="Break cue"
          right={
            <SegmentedControl
              theme={theme}
              value={sound}
              onChange={setSound}
              options={[
                { value: 'music', label: 'Soothing' },
                { value: 'beep', label: 'Beep' },
                { value: 'silent', label: 'Silent' },
              ]}
            />
          }
        />

        <Divider theme={theme} />

        {/* GENERAL */}
        <SectionLabel theme={theme}>General</SectionLabel>
        <Row
          theme={theme}
          tight
          label="Start at login"
          right={<Toggle theme={theme} size="sm" on={startAtLogin} onChange={setStartAtLogin} />}
        />
        <Row
          theme={theme}
          tight
          label="Show in Notification Center"
          right={<Toggle theme={theme} size="sm" on={showNotifs} onChange={setShowNotifs} />}
        />
        <Row
          theme={theme}
          tight
          label="Respect Do Not Disturb"
          right={<Toggle theme={theme} size="sm" on={respectDnd} onChange={setRespectDnd} />}
        />
      </div>

      {/* Footer — stats strip */}
      <StatsFooter theme={theme} />
    </div>
  );
}

function StatusPill({ theme, on, minutesUntil }) {
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 6,
        padding: '3px 9px 3px 7px',
        borderRadius: 99,
        background: on ? theme.accentSoft : 'rgba(255,255,255,0.05)',
        fontSize: 11,
        fontWeight: 500,
        fontFamily: theme.fontMono,
        color: on ? theme.accent : theme.textMuted,
        letterSpacing: '0.01em',
      }}
    >
      <span
        style={{
          width: 6,
          height: 6,
          borderRadius: 3,
          background: on ? theme.accent : theme.textMuted,
          boxShadow: on ? `0 0 6px ${theme.accent}` : 'none',
        }}
      />
      {on ? `next in ${minutesUntil}m` : 'paused'}
    </div>
  );
}

function StatsFooter({ theme }) {
  return (
    <div
      style={{
        borderTop: `0.5px solid ${theme.border}`,
        background: theme.bgSunken,
        padding: '11px 18px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        gap: 10,
      }}
    >
      <div style={{ display: 'flex', gap: 18 }}>
        <Stat theme={theme} value="8" label="today" />
        <Stat theme={theme} value="12" label="day streak" />
        <Stat theme={theme} value="2h 40m" label="eyes rested" />
      </div>
    </div>
  );
}

function Stat({ theme, value, label }) {
  const isSerif = theme.displayIsSerif;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
      <div
        style={{
          fontSize: isSerif ? 17 : 14,
          fontWeight: isSerif ? 500 : 600,
          color: theme.text,
          fontFamily: isSerif ? theme.fontDisplay : theme.fontBody,
          letterSpacing: '-0.02em',
          lineHeight: 1,
        }}
      >
        {value}
      </div>
      <div
        style={{
          fontSize: 10,
          color: theme.textDim,
          letterSpacing: '0.04em',
          textTransform: 'uppercase',
          fontWeight: 500,
        }}
      >
        {label}
      </div>
    </div>
  );
}

function EyeGlyph({ color, size = 16 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 20 20" fill="none">
      <path
        d="M1.5 10 C 4 5, 7 3.5, 10 3.5 C 13 3.5, 16 5, 18.5 10 C 16 15, 13 16.5, 10 16.5 C 7 16.5, 4 15, 1.5 10 Z"
        stroke={color}
        strokeWidth="1.3"
        strokeLinejoin="round"
      />
      <circle cx="10" cy="10" r="2.7" fill={color} />
    </svg>
  );
}

window.SettingsPopover = SettingsPopover;
window.EyeGlyph = EyeGlyph;
