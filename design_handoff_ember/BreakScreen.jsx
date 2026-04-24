// BreakScreen.jsx — The fullscreen "Look Away" moment.
// Matches the reference's composition (centered card, eye glyph, "Look Away",
// 20-20-20 sub-meta, countdown) but refined for the warm-zen palettes.
// Dim backdrop reveals a faint silhouette of the user's desktop.

const { useState: useStateBS, useEffect: useEffectBS } = React;

function BreakScreen({ theme, countdown = 13, width = 640, height = 400, showFaintDesktop = true }) {
  const [pulse, setPulse] = useStateBS(false);
  useEffectBS(() => {
    const id = window.setInterval(() => setPulse((p) => !p), 1800);
    return () => window.clearInterval(id);
  }, []);

  const isSerif = theme.displayIsSerif;

  return (
    <div
      style={{
        width,
        height,
        background: theme.breakBg,
        position: 'relative',
        overflow: 'hidden',
        fontFamily: theme.fontBody,
        borderRadius: 10,
        isolation: 'isolate',
      }}
    >
      {/* Faint desktop silhouette behind dim — suggests the user's screen is still there, just dimmed */}
      {showFaintDesktop && <FaintDesktop theme={theme} />}

      {/* Vignette to focus eye on center */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: 'radial-gradient(ellipse at center, transparent 30%, rgba(0,0,0,0.45) 100%)',
          pointerEvents: 'none',
        }}
      />

      {/* Breathing ring pulse — far, soft */}
      <div
        style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          width: 340,
          height: 340,
          borderRadius: '50%',
          border: `1px solid ${theme.breakAccent}`,
          opacity: pulse ? 0.08 : 0.22,
          transition: 'opacity 1.8s ease-in-out',
          pointerEvents: 'none',
        }}
      />
      <div
        style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          width: 460,
          height: 460,
          borderRadius: '50%',
          border: `1px solid ${theme.breakAccent}`,
          opacity: pulse ? 0.04 : 0.1,
          transition: 'opacity 1.8s ease-in-out',
          pointerEvents: 'none',
        }}
      />

      {/* Centerpiece */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 14,
        }}
      >
        {/* Eye glyph — soft glow */}
        <div style={{ position: 'relative', marginBottom: 2 }}>
          <div
            style={{
              position: 'absolute',
              inset: -14,
              borderRadius: '50%',
              background: `radial-gradient(circle, ${theme.breakAccent} 0%, transparent 65%)`,
              opacity: 0.22,
              filter: 'blur(6px)',
              pointerEvents: 'none',
            }}
          />
          <svg width="52" height="52" viewBox="0 0 52 52" fill="none" style={{ display: 'block', position: 'relative' }}>
            <path
              d="M4 26 C 10 13, 18 9, 26 9 C 34 9, 42 13, 48 26 C 42 39, 34 43, 26 43 C 18 43, 10 39, 4 26 Z"
              stroke={theme.breakAccent}
              strokeWidth="1.5"
              strokeLinejoin="round"
              fill="none"
            />
            <circle cx="26" cy="26" r="7" fill={theme.breakAccent} />
            <circle cx="28.5" cy="23.5" r="2" fill={theme.breakBg.includes('0a') ? '#0a0806' : theme.bg} opacity="0.9" />
          </svg>
        </div>

        {/* "Look Away" */}
        <div
          style={{
            fontSize: isSerif ? 68 : 54,
            fontWeight: isSerif ? 400 : 300,
            fontStyle: isSerif ? 'italic' : 'normal',
            color: theme.breakText,
            letterSpacing: isSerif ? '-0.01em' : '-0.035em',
            fontFamily: theme.fontDisplay,
            lineHeight: 1,
            textAlign: 'center',
          }}
        >
          Look Away
        </div>

        {/* 20 feet · 20 seconds · every 20 minutes */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 12,
            fontSize: 12,
            color: theme.breakMeta,
            letterSpacing: '0.02em',
            fontFamily: theme.fontBody,
            fontWeight: 500,
          }}
        >
          <span>20 feet</span>
          <span style={{ opacity: 0.4 }}>·</span>
          <span>20 seconds</span>
          <span style={{ opacity: 0.4 }}>·</span>
          <span>every 20 minutes</span>
        </div>

        {/* Countdown */}
        <div
          style={{
            marginTop: 22,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: 2,
          }}
        >
          <div
            style={{
              fontSize: isSerif ? 64 : 56,
              fontWeight: isSerif ? 400 : 200,
              color: theme.breakNumber,
              fontFamily: isSerif ? theme.fontDisplay : theme.fontBody,
              letterSpacing: '-0.03em',
              lineHeight: 1,
              fontFeatureSettings: '"tnum" 1',
              fontStyle: isSerif ? 'italic' : 'normal',
            }}
          >
            {countdown}
          </div>
          <div
            style={{
              fontSize: 10,
              color: theme.breakMeta,
              letterSpacing: '0.22em',
              textTransform: 'uppercase',
              fontWeight: 500,
              marginTop: 4,
            }}
          >
            seconds
          </div>
        </div>
      </div>

      {/* Bottom hint — skip */}
      <div
        style={{
          position: 'absolute',
          bottom: 22,
          left: '50%',
          transform: 'translateX(-50%)',
          display: 'flex',
          alignItems: 'center',
          gap: 8,
          fontSize: 11,
          color: theme.breakMeta,
          opacity: 0.7,
          fontFamily: theme.fontBody,
          letterSpacing: '0.01em',
        }}
      >
        <Kbd theme={theme}>esc</Kbd>
        <span>to skip</span>
      </div>

      {/* Top-left — app brand */}
      <div
        style={{
          position: 'absolute',
          top: 18,
          left: 20,
          display: 'flex',
          alignItems: 'center',
          gap: 8,
          opacity: 0.55,
        }}
      >
        <div
          style={{
            width: 6,
            height: 6,
            borderRadius: 3,
            background: theme.breakAccent,
            boxShadow: `0 0 6px ${theme.breakAccent}`,
          }}
        />
        <div
          style={{
            fontSize: 10,
            color: theme.breakMeta,
            letterSpacing: '0.22em',
            textTransform: 'uppercase',
            fontWeight: 600,
            fontFamily: theme.fontBody,
          }}
        >
          EyeBreak
        </div>
      </div>

      {/* Top-right — time */}
      <div
        style={{
          position: 'absolute',
          top: 18,
          right: 20,
          fontSize: 11,
          color: theme.breakMeta,
          fontFamily: theme.fontMono,
          letterSpacing: '0.02em',
          opacity: 0.7,
        }}
      >
        15:53
      </div>
    </div>
  );
}

function Kbd({ theme, children }) {
  return (
    <span
      style={{
        display: 'inline-block',
        padding: '1px 6px',
        fontSize: 10,
        fontFamily: theme.fontMono,
        borderRadius: 4,
        background: 'rgba(255,255,255,0.06)',
        color: theme.breakText,
        boxShadow: `inset 0 0 0 0.5px ${theme.borderStrong}`,
        letterSpacing: '0.04em',
      }}
    >
      {children}
    </span>
  );
}

// Hints of a faint desktop behind the dim — windows barely visible.
function FaintDesktop({ theme }) {
  return (
    <div style={{ position: 'absolute', inset: 0, opacity: 0.07, pointerEvents: 'none' }}>
      {/* menu bar */}
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 22, background: '#fff' }} />
      {/* window 1 */}
      <div
        style={{
          position: 'absolute',
          top: 42,
          left: 30,
          width: 220,
          height: 130,
          borderRadius: 8,
          background: '#fff',
        }}
      />
      {/* window 2 */}
      <div
        style={{
          position: 'absolute',
          top: 200,
          right: 40,
          width: 260,
          height: 120,
          borderRadius: 8,
          background: '#fff',
        }}
      />
      {/* dock */}
      <div
        style={{
          position: 'absolute',
          bottom: 10,
          left: '50%',
          transform: 'translateX(-50%)',
          width: 260,
          height: 38,
          borderRadius: 12,
          background: '#fff',
        }}
      />
    </div>
  );
}

window.BreakScreen = BreakScreen;
