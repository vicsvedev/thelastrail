# THE LAST RAIL 1.0 — Release checklist

Legend: **[x]** done and verified · **[ ]** not done · 👤 requires the owner · ⚠️ verified only partly (reason given)

Last updated: 13 October 2026.

## A. Project and build

- [x] Deployment target iOS 17.0, iPhone only, landscape left and right only, full screen
- [x] Version **1.0**, build **1** (all targets)
- [x] Bundle ID unchanged: `Victor-Svensson.The-Last-Rail`
- [x] Development language Swedish (`CFBundleDevelopmentRegion = sv`, verified in the built Info.plist)
- [x] `ITSAppUsesNonExemptEncryption = NO`
- [x] Dark launch screen (`UIUserInterfaceStyle = Dark`)
- [x] Privacy manifest `PrivacyInfo.xcprivacy` included in the app bundle (verified in the archive)
- [x] No third-party dependencies, no ads, no in-app purchases
- [x] Debug tools (`-TLRScenario`, `-TLRFreshStart`, `-TLRShowFPS`) compiled out of Release
- [x] Release build for a physical iPhone (`generic/platform=iOS`): **0 warnings**
- [x] Release archive created (`xcodebuild archive`), signed with Apple Development, team B8SM9PP3KC (free Personal Team)
- [ ] 👤 Enroll in the Apple Developer Program (paid), then select the paid team under Signing & Capabilities
- [ ] 👤 Archive with the paid team and **Validate App** in Organizer
- [ ] 👤 Upload to App Store Connect (**not done, as instructed**; needs your approval)

## B. App icon and graphics

- [x] 1024 × 1024 icon, opaque RGB (the previous icon had an alpha channel, which App Store Connect rejects)
- [x] Icon shows the game's own locomotive (Lok 7) in pixel art; no external artwork (generator: `Tools/AppIcon/makeicon.swift`)
- [x] 6 real gameplay screenshots, 2868 × 1320 (6.9″ iPhone, landscape), JPEG, no alpha
- [ ] 👤 Optional: retake screenshots on a physical iPhone to avoid the simulator's Dynamic Island pill
- [ ] Optional: app preview video

## C. Metadata (`AppStore/`)

- [x] `APP_NAME.md`: name, subtitle, promotional text, categories, SKU (all within character limits)
- [x] `DESCRIPTION_SV.md` (2,076 characters) and `DESCRIPTION_EN.md` (2,165); limit 4,000; every claim matches implemented content
- [x] `KEYWORDS.md`: Swedish 90 characters / 95 bytes, English 97 / 97 (limit 100)
- [x] `SCREENSHOT_PLAN.md`, `RELEASE_NOTES.md`, `APP_REVIEW_NOTES.md`
- [x] `AGE_RATING_AND_COMPLIANCE.md`
- [ ] 👤 Check that the name "The Last Rail" is free on the App Store and doesn't conflict with a trademark
- [ ] 👤 **Support URL**
- [ ] 👤 Contact name, email and phone for App Review
- [ ] 👤 Copyright line (`2026 [name]`)

## D. Privacy and compliance

- [x] Code audit: no network calls, no analytics, crash SDK, tracking, IDFA, identifiers or required-reason APIs; only local JSON saves
- [x] `PRIVACY_POLICY_SV.md`, `PRIVACY_POLICY_EN.md` and the GitHub Pages page `docs/index.html` (no external resources, no names or personal details)
- [ ] Privacy policy live at https://vicsvedev.github.io/thelastrail/ (GitHub Pages from `/docs` on `main`); see the Pages status in the latest report
- [ ] 👤 App Privacy in App Store Connect: "No, we do not collect data from this app"
- [ ] 👤 Age-rating questionnaire: choose "None" or "Infrequent/Mild" for horror or fear themes (see `AGE_RATING_AND_COMPLIANCE.md`)
- [ ] 👤 EU Digital Services Act trader status
- [ ] 👤 Price, Paid Apps Agreement and banking/tax details (if paid)
- [ ] 👤 Decide whether to allow the app on Apple silicon Mac and Vision Pro (recommended: off)

## E. Completeness (App Review 2.1)

- [x] No placeholder buttons or "coming soon" texts. Removed: "Ej i version 0.2" wagon tiles, "(Fortsättning i en kommande version.)" on the Polaris route, "(Kommer i en framtida version.)" in wagon data
- [x] The main menu shows the real version from the bundle (was hard-coded "0.2")
- [x] The locked Polaris route is framed as a story cliffhanger and explained in the review notes
- [x] All menu, pause and panel buttons lead to working features (checked on screen on SE and Pro Max)

## F. iPhone landscape layout

Checked from simulator screenshots on the **iPhone SE (3rd gen, 667 × 375 pt, smallest)**, **iPhone 17 Pro (Dynamic Island)** and **iPhone 17 Pro Max (largest)**:

- [x] Main menu, new game with tutorial hints, exploration (rain), travel, train, map, crafting, inventory, locomotive, wagons, journal, pause, settings, help, keypad, tutorial complete and story dialog
- [x] No clipped UI and HUD inside safe areas (SE and Pro Max checked)
- [x] Touch targets 44 pt or larger (bottom bar, close buttons and panel buttons; keypad keys 56 × 46)
- [x] Long story dialog: the text scrolls, and the scroll indicator now flashes on open (fixed; it previously looked cut off on the SE)
- [x] Story text no longer breaks mid-sentence (reflowed 7 places)
- [x] The device stays landscape in every orientation (UI test)
- ⚠️ Cosmetic: on the SE the "21 km" map label touches the "Tallkorset" name. Not fixed (minor).
- ⚠️ Dynamic Island on the *left* landscape side was only tested in UI tests, not screenshotted.
- ⚠️ Text uses fixed sizes and does not follow Dynamic Type. That's acceptable for a game, but noted for accessibility.

## G. Quality assurance

| Item | Result | Evidence |
|---|---|---|
| All automated tests | **74/74 pass** | iPhone 17 Pro (run twice, before and after the final code changes), iPhone SE 3rd gen (twice), iPhone 17 Pro Max (once, before the final text/dialog changes) |
| New game | [x] | UI test `testMainMenuNewGameAndJoystickMovement` |
| Continue after app restart | [x] | UI test `testSaveSurvivesRelaunch` (terminate and relaunch) |
| Tutorial start to finish | [x] | `fullTutorialWithRealSystems` (unit test with real systems); UI tests cover steps 1–3 with real touches |
| Tutorial skip | [x] | `skipLeavesPlayableState`, `skipAfterCompletionStepDoesNotDoubleReward` |
| Movement and interaction | [x] | UI tests (joystick drag, action button), `TouchControlTests`, `InteractionTests` |
| Multi-touch (joystick + sprint + action) | ⚠️ | Unit test on the touch model; XCUITest can't inject independent fingers. Needs a real device. |
| Inventory | [x] | `InventoryTests` (7) |
| Crafting and upgrades | [x] | `CraftingTests` (9) |
| Railway travel | [x] | `TravelTests` (10), UI tests `testTrainGesturesMapAndDeparture`, `testTravelArriveDisembarkAndBoard` |
| Station exploration | [x] | `ContentTests` (flood-fill reachability for every station), screenshots |
| Health, hazards, faint and respawn | [x] | `hazardsDamageAndFaintKeepsProgress`, `faintPenaltyHalvesCarriedResources` |
| Secrets | [x] | `atLeastThreeOptionalSecrets`, interaction tests, live discovery in screenshot 6 |
| Story progression to the end of chapter 1 | [x] | `chapterOneViaMineLine`, `chapterOneViaNorthernLine` |
| Saving and loading, corruption fallback | [x] | `SaveTests` (7) |
| Offline gameplay | [x] | Static verification: no networking API anywhere in the code, no dependencies. ⚠️ Not tested in airplane mode on a device. |
| Frame rate | [x] simulator | SpriteKit FPS counter: **60.0 FPS** in rain exploration, travel with 4 vehicles, and the dark mine; 51–167 nodes, 15–26 draw calls (iPhone 17 Pro Max simulator, Debug build) |
| CPU and memory | [x] simulator | About 3–5% CPU; about 128 MB RSS; no growth across 60 scene transitions (127 → 125 MB) |
| Memory leaks | ⚠️ | The `leaks` tool cannot attach to simulator processes here. Checked through RSS stability instead. Run Instruments › Leaks on a device for certainty. |
| Real-device playtest (feel, heat, audio, haptics, real FPS) | [ ] 👤 | Needs a physical iPhone, best via TestFlight |

## H. Distribution

- [x] Archive builds and is signed (development)
- [x] App Store export attempted locally (destination `export`, **no upload**): fails with "No provider associated with App Store Connect user" / "No profiles … were found". This is expected without a paid membership.
- [ ] 👤 Steps 3–12 in `APP_STORE_RELEASE.md`
