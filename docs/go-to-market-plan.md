# Go-to-Market Plan: Shopping List App

**Date:** 2026-06-09
**Status:** Preparation phase (pre-Play account)

## Summary

Ship the current local-only shopping list app to Google Play. One screen, no backend,
no authentication, no third-party SDKs. The app is feature-complete for MVP.

---

## Key Decisions

### Telemetry / Crash Reporting

**Decision:** None for MVP. No Sentry, no UserOrient, no third-party SDK.

Google Play's closed testing questionnaire does not require third-party crash
reporting. Play Console provides crash data via Android vitals and the pre-launch
report for free. Sentry can be evaluated post-release if crashes actually occur.

_Rationale:_ A local-only CRUD app with no networking has minimal crash surface.
Adding an SDK now adds a dependency, a DSN secret, and a Data Safety form
declaration for zero marginal benefit during the closed testing gate.

### Privacy

**Decision:** No data collection architecture needed. The app stores everything
locally on-device via SQLite. Nothing is transmitted. The privacy policy will
say exactly that.

_Rationale:_ No accounts, no networking, no PII. A "default-off" consent flow
and hashing logic would be engineering theater for this app.

---

## Phases

### Phase 0: Pre-Account (can do now, $0)

Before paying the $25 developer registration fee, prepare everything that does
not require a Play Console account.

- [ ] **App icon** -- 512x512px, 32-bit PNG with alpha channel. Uploaded to Play
      Console during app setup. (Separate from the mipmap launcher icon.)
- [ ] **Feature graphic** -- 1024x500px, PNG or JPEG.
- [ ] **Phone screenshots** -- 2-8 screenshots showing the actual UI. No
      marketing-only graphics.
- [ ] **Tablet screenshots** -- Optional for MVP, needed if listing on tablets.
      Issue [#16](https://github.com/sshunter/lets-go-shopping/issues/16), post-mvp
- [ ] **Privacy policy** -- Short honest statement hosted at a live HTTPS URL
      (e.g., bluecollarcode.com/privacy on Cloudflare Pages). Single paragraph
      for this app: zero data collection, all data on-device. Google rejects PDFs.
- [ ] **16KB page alignment** -- Already compliant. Flutter 3.44.1 bundles
      NDK r28 which aligns native binaries automatically. No action needed.
- [ ] **Target SDK** -- Builds target API 36 (Android 16), well above the
      API 35 minimum. No action needed.
- [ ] **Decide tester strategy** -- Recruit own (friends, family, Reddit,
      Discord) or pay a tester service ~$50 flat for guaranteed 16-20 testers
      across 14 days.
- [ ] **Set up feedback channel** -- Google Form, email, or a simple web form
      on bluecollarcode.com. Testers need a way to send you written feedback
      that you can quote in the questionnaire.

### Phase 1: Play Console Setup ($25)

After paying the one-time developer registration fee.

- [ ] Register personal developer account at play.google.com/console
- [ ] Create app listing
- [ ] Complete store listing: description, category, tags
- [ ] Complete content rating questionnaire
- [ ] Fill out Data Safety form (minimal: no user data collected, crash logs
      from Android vitals only)
- [ ] Upload privacy policy URL
- [ ] Upload app icon, feature graphic, screenshots

### Phase 2: Release Build (requires keystore)

- [ ] Generate upload keystore:
      `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000`
- [ ] Create `android/key.properties` for signing config
- [ ] Add `*.jks`, `key.properties` to `.gitignore`
- [ ] Configure release signing in `android/app/build.gradle.kts`
- [ ] Register the upload key's SHA-1 fingerprint in Play Console (Play App
      Signing recommended -- Google holds the signing key, you keep the upload key)
- [ ] `flutter build appbundle --release` -- produces `.aab`
- [ ] Upload AAB to the closed testing track

### Phase 3: Closed Testing (14 days)

- [ ] Create closed testing track in Play Console
- [ ] Create tester list or Google Group
- [ ] Share opt-in link with testers
- [ ] Target 16-20 testers to survive dropouts without resetting the 14-day clock
- [ ] Collect all tester feedback (timestamps, descriptions, screenshots)
- [ ] Ship at least one update during the 14 days -- even a minor UI polish or
      wording tweak counts. Upload a new AAB to the same track.
- [ ] Keep a running document: every piece of feedback + every change made

### Phase 4: Production Access

- [ ] Click "Apply for production" on the Play Console Dashboard
- [ ] Answer the 3-section questionnaire (~10 questions): 1. About your closed test (recruitment, engagement, feedback summary) 2. About your app (audience, value, expected installs) 3. Production readiness (changes made, why ready)
- [ ] Await review (typically 7 days or less)
- [ ] Go live

---

## Questionnaire Cheat Sheet

The questions from Google's production access form that trip most people up:

| Google asks                        | What they want to hear                                       |
| ---------------------------------- | ------------------------------------------------------------ |
| "What engagement did you receive?" | Specific features testers used, not just "they used it"      |
| "What feedback did you get?"       | Real, specific, documented feedback -- even minor things     |
| "What changes did you make?"       | Concrete fixes, even if small. "Nothing" is the wrong answer |
| "Were there any crashes or ANRs?"  | They already know from Play Console. Be honest.              |

---

## Post-MVP (not in scope for this plan)

- Crash reporting (e.g., Sentry) if real-world crash rates justify it
- Any new features the user wanted to build but held for after release
- iOS release (requires macOS + $99 Apple developer account)
