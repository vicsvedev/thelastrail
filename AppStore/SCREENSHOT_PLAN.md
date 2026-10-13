# Screenshot plan

## Status: 6 screenshots captured and ready

The screenshots are in `AppStore/Screenshots/iPhone-6.9in-2868x1320/`.

They are **real captures of the running game**: the game rendered them in the iPhone 17 Pro Max simulator (iOS 26.4) and `xcrun simctl io screenshot` saved them. The only processing was rotating the portrait framebuffer to landscape and converting PNG to JPEG (quality 95, no alpha channel). No pixels were painted, composited, retouched or added.

To get the game into each state quickly, the Debug build's development scenario tool was used (`-TLRScenario`, see below). It produces ordinary game states a player reaches through normal play: tutorial finished, wagons built, stations visited. It does not draw anything that does not exist in the game.

## Apple's requirements (checked October 2026)

* **iPhone 6.9" display** is the required set for iPhone apps. Accepted landscape sizes: **2868 × 1320**, 2796 × 1290 or 2736 × 1260 px. Apple scales these down for smaller iPhones automatically.
* 1 to 10 screenshots per localization, JPEG or PNG, RGB, no transparency.
* Screenshots must show the app in use, not only a title screen or splash art.
* iPad screenshots are not needed: the app is iPhone only.

All six files are **2868 × 1320 px, JPEG, RGB, no alpha**. This was checked with `sips`.

## The six screenshots

| # | File | Theme (from the brief) | What it shows |
|---|---|---|---|
| 1 | `01_tag_pa_vag.jpg` | Train traveling through the world | Lok 7 with three wagons on the way from Tallkorset to Rosthamn: journey card, fuel and travel progress, train bar |
| 2 | `02_station_tallkorset.jpg` | Exploring an abandoned railway station | The player on the platform at Tallkorset in the rain, with the station building, the train and the "Plocka upp järnskrot" action prompt |
| 3 | `03_tag_och_vagnar.jpg` | Train and wagon management | The full train at Rosthamn station: status card (fuel, storage, condition, weight) and the management bar (Karta, Lager, Bygg, Vagnar, Loket, Journal, Kliv av) |
| 4 | `04_bygg_och_tillverka.jpg` | Crafting and upgrades | The "Bygg & tillverka" panel: recipe categories, cost and the Tillverka button |
| 5 | `05_jarnvagskarta.jpg` | The railway map | The railway map with five stations, distances, the locked route to "???" and station info |
| 6 | `06_hemlighet_djupgruvan.jpg` | A mysterious environment or discovery | The headlamp-lit dark mine at Djupgruvan, at the moment the secret "Den igenmurade sidogången (1/5)" is discovered |

Suggested upload order: 1 → 2 → 5 → 3 → 4 → 6. The first three appear in search results, so lead with the strongest atmosphere (the journey, the rainy station and the map).

### Known cosmetic detail

The simulator draws the **Dynamic Island** as a black pill on the left edge of every capture. `simctl` cannot turn this off (`--mask=ignored` has no effect on this device). Apple accepts screenshots like this. If you prefer screenshots without it, take them on a physical iPhone (see below); real-device screenshots do not include the island.

The objective tracker in screenshots 2 and 6 shows "Res till Rosthamn…", because the scenario tool skipped ahead from the tutorial. It is real game UI, but you may prefer to retake them during a real playthrough.

## How the screenshots were made (to reproduce)

```bash
export DEVELOPER_DIR=/Volumes/WD-BLACK/User/Apps/Xcode.app/Contents/Developer
# build Debug for the simulator, install it on the iPhone 17 Pro Max simulator, then for each shot:
xcrun simctl launch <UDID> Victor-Svensson.The-Last-Rail -TLRScenario "<scenario>"
sleep 8
xcrun simctl io <UDID> screenshot --type=png raw.png
sips -r 270 raw.png --out shot.png        # framebuffer is portrait
sips -s format jpeg -s formatOptions 95 shot.png --out final.jpg
```

| # | Scenario |
|---|---|
| 1 | `skip;wagons;routes;train:tallkorset;travel:rosthamn` (wait about 10 s) |
| 2 | `skip;explore:tallkorset@30,24` |
| 3 | `skip;wagons;routes;train:rosthamn` |
| 4 | `skip;wagons;train:rosthamn;overlay:crafting` |
| 5 | `skip;explore:tallkorset;explore:djupgruvan;explore:nordpasset;routes;train:rosthamn;overlay:map` |
| 6 | `skip;lamp;wagons;routes;explore:djupgruvan@6,6` |

`-TLRScenario` exists **only in Debug builds**. It is compiled out of Release and App Store builds.

## Manual alternative (on a physical iPhone)

1. Install a TestFlight or development build and play normally to the states listed above.
2. Turn off any Focus banners and charge the phone, so no notifications appear.
3. Hold the phone in landscape and press **Side button + Volume Up** to take a screenshot.
4. AirDrop the images to the Mac. A 6.9" iPhone (16 Pro Max / 17 Pro Max) gives exactly 2868 × 1320. Other phones need the 6.9" size, so use the simulator captures in that case.

## Optional extras (not required)

* **App preview video** (15–30 s): `xcrun simctl io <UDID> recordVideo --codec=h264 preview.mov` during a journey, then trim to 30 s. App previews must also show only real gameplay.
* **English store screenshots:** the game's UI is Swedish, so the same screenshots are used for the English listing.
