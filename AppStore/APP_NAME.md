# App name, subtitle and store settings

Character counts were checked with a script (see `RELEASE_CHECKLIST.md`). Apple's limits are shown in brackets.

## Name and subtitle

| Field | Swedish (primary) | English (U.K./U.S.) |
|---|---|---|
| App name [30] | `The Last Rail` (13) | `The Last Rail` (13) |
| Subtitle [30] | `Utforska de övergivna spåren` (28) | `Explore the abandoned railway` (29) |

App names must be unique across the App Store. If "The Last Rail" is already taken when you register the app, alternatives are:

* `The Last Rail: Sista avgången` (29)
* `The Last Rail – Lok 7` (21)

The home-screen name (`CFBundleDisplayName`) is set to **The Last Rail** in the project and does not need to match the store name exactly.

## Promotional text [170]

Promotional text can be changed at any time without a new review.

* **SV** (130): `Väck liv i ett gammalt diesellok, samla resurser och följ en radiosignal norrut genom ett övergivet järnvägsnät. Helt offline.`
* **EN** (124): `Bring an old diesel locomotive back to life, gather resources and follow a radio signal north through an abandoned rail network.`

## Category (recommendation)

| | Recommendation | Why |
|---|---|---|
| Primary category | **Games** | |
| Games subcategory 1 | **Adventure** | Exploration, story and secrets are the core of the game. This matches `LSApplicationCategoryType = public.app-category.adventure-games` in the project. |
| Games subcategory 2 | **Simulation** | Train management: fuel, weight, wagons and upgrades. |
| Secondary category (optional) | none | Not needed. |

## Store settings to enter in App Store Connect

| Setting | Value |
|---|---|
| Bundle ID | `Victor-Svensson.The-Last-Rail` (existing; kept as is, see `APP_STORE_RELEASE.md`) |
| SKU (internal, never shown) | suggestion: `THELASTRAIL-IOS-001` |
| Primary language | **Swedish** |
| Version | 1.0 (build 1) |
| Platforms | iPhone only (iPad is not supported; the game is landscape iPhone only) |
| Price | owner's decision (see `APP_STORE_RELEASE.md` §10) |
| In-app purchases | none |
| Copyright | `© 2026 [NAMN / NAME]` – fill in |
| Support URL (required) | **owner must supply** (for example a simple web page with a contact email) |
| Marketing URL (optional) | owner's decision |
| Privacy Policy URL (required) | `https://vicsvedev.github.io/thelastrail/` (GitHub Pages, source `docs/index.html`) |

## Localizations

The game's text is Swedish only. You can still add an English (U.K. or U.S.) **store** localization so that English-speaking customers can read the listing. The English description clearly says that the game itself is in Swedish. If you add the English store localization, App Store Connect lists the app's languages based on the app binary (Swedish), not on the store text.
