# IrisBreak — Mac App Store Submission

Bundle ID: `com.vikasanand.eyebreak` · Team: `55Q6D4GFWP` · Category: Health & Fitness
Version 1.0 (build 1) · macOS 13+ · Sandboxed · One-time $4.99 unlock (StoreKit 2 non-consumable)
IAP product ID: `com.vikasanand.eyebreak.unlock`

---

## 1. App Store Connect listing copy

**Name** (30 char max)
> IrisBreak

**Subtitle** (30 char max)
> 20-20-20 eye breaks, gently

**Promotional Text** (170 char max — editable anytime without review)
> Protect your eyes from screen strain. IrisBreak nudges you to look away every 20 minutes — and stays quiet when you're on a call.

**Description**
> IrisBreak helps you follow the 20-20-20 rule that eye-care professionals recommend: every 20 minutes, look at something 20 feet away for 20 seconds. It lives quietly in your menu bar and gives you a gentle full-screen reminder when it's time to rest your eyes.
>
> WHY IRISBREAK
> • Beautiful, calm full-screen break overlay — not a jarring alarm
> • Smart pausing — automatically skips breaks when you're on a call or sharing your screen, so it never interrupts a meeting
> • Idle-aware — won't nag you when you've stepped away
> • Posture reminders to keep you sitting well
> • Activity rings and streaks so you can see your healthy habit build
> • Logs completed breaks to Apple Health as mindful minutes (optional)
>
> SIMPLE AND PRIVATE
> • No account, no tracking, no ads
> • Everything stays on your Mac
>
> TRY IT FREE
> Full features free for 7 days. After that, unlock everything forever with a single one-time purchase — no subscription.

**Keywords** (100 char max, comma-separated, no spaces)
> eye,break,20-20-20,rest,strain,reminder,health,posture,timer,screen,vision,pomodoro,wellness

**Support URL** — REQUIRED (you must provide a real page)
> https://… (a simple page with a contact email is enough)

**Marketing URL** — optional

**Copyright**
> © 2026 Vikas Anand

---

## 2. In-App Purchase setup (do this before/with submission)

Create one **Non-Consumable** IAP in App Store Connect:
- Reference Name: `IrisBreak Full Unlock`
- Product ID: `com.vikasanand.eyebreak.unlock`  ← must match the code exactly
- Price: Tier for $4.99
- Display Name: `IrisBreak — Full Unlock`
- Description: `Unlock all features forever. One-time purchase, no subscription.`
- Add a review screenshot of the paywall/About purchase screen
- The IAP must be submitted **with** the app's first version (attach it to the version under "In-App Purchases").

> Note: client-side 7-day trial is fine — Apple allows app-managed free trials for non-subscription IAP. The purchase must be restorable (you have a Restore button in About — good).

---

## 3. Privacy

**App Privacy "nutrition label"** — answer in App Store Connect:
- Data collection: **Data Not Collected** (no analytics, no account, network is StoreKit only)
- Health data (Apple Health) stays on device and is not collected by you → not declared as collected.

**Privacy Policy URL** — REQUIRED even if you collect nothing. A short page stating "IrisBreak does not collect, store, or transmit any personal data. Eye-break activity written to Apple Health stays on your device." is sufficient.

**HealthKit review note** — Apple scrutinizes HealthKit on Mac. In "App Review notes" explain:
> IrisBreak writes completed eye-break sessions to Apple Health as Mindful Minutes (HKCategoryTypeIdentifier.mindfulSession). It does not read health data. HealthKit is optional and the app is fully functional without granting access.

---

## 4. Screenshots (REQUIRED)

Mac screenshots must be one of these exact sizes (PNG/JPG, RGB, no alpha):
- 1280×800, 1440×900, 2560×1600, or 2880×1800

Need 1–10. Suggested set:
1. The break overlay (the calm full-screen rest screen)
2. Menu bar popover with activity rings + countdown
3. Settings window
4. Posture reminder
5. The "on a call → break skipped" state / About screen

Capture on this Mac with ⇧⌘4 (or full screen ⇧⌘3); resize to an allowed size if needed.

---

## 5. App Review notes (paste into "Notes")
> IrisBreak is a 20-20-20 eye-break reminder that lives in the menu bar (LSUIElement).
>
> • Free 7-day trial of all features, then a single one-time $4.99 unlock (non-consumable IAP `com.vikasanand.eyebreak.unlock`). Restore Purchase is in the About window.
> • To test full features without waiting for a break: open Settings and use "Take a break now," or shorten the interval.
> • The app auto-skips breaks during calls/screen-sharing by reading (read-only, no permission needed) camera/mic in-use state and screen-sharing status — no recording, no data leaves the device.
> • HealthKit: write-only mindful sessions, optional.

---

## 6. Submission checklist (the human-only steps)

These need your Apple ID / App Store Connect access — I can't do them for you.

- [ ] **App Store Connect → create App record** (if not done): platform macOS, name "IrisBreak", bundle ID `com.vikasanand.eyebreak`, SKU (any string), Health & Fitness category.
- [ ] **Create the IAP** (section 2) and attach to version 1.0.
- [ ] **Fill listing copy** (section 1) + upload **screenshots** (section 4) + set **price = Free** (the app is free; revenue is the IAP).
- [ ] **Privacy** answers + Privacy Policy URL + Support URL (section 3).
- [ ] **Archive & upload the signed build** — in Xcode:
      Product → Archive → Distribute App → **App Store Connect** → Upload.
      (Automatic signing with your team will produce the Mac App Store distribution signature & provisioning.)
- [ ] Select the uploaded build in the version, answer the encryption question (uses only standard HTTPS → "No" to non-exempt encryption), add **App Review notes** (section 5).
- [ ] **Submit for Review.**

> The earlier `CODE_SIGNING_ALLOWED=NO` archive was only to validate the build/assets locally. The real upload is signed automatically by Xcode's Distribute flow.
