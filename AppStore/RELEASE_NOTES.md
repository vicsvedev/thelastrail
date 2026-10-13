# Release notes – version 1.0 (build 1)

App Store Connect does not show a "What's New" field for an app's first version. The texts below are for **TestFlight ("What to Test")** and can be reused as the first update's "What's New" if you want.

## TestFlight – "What to Test" (Swedish, max 4,000 characters)

```
Tack för att du testar The Last Rail!

Det här är version 1.0 – spelets första kapitel. Spela gärna från början:
1. Nytt spel: följ guiden tills du har lagat loket och byggt verkstaden (ca 10–15 min).
2. Res vidare till Rosthamn, Djupgruvan och Nordpasset.
3. Leta efter de fem hemligheterna.

Vi vill särskilt veta:
- Känns styrspaken, springknappen och handlingsknappen bra i handen?
- Är någon text svår att läsa eller någon knapp svår att träffa?
- Fastnade du någonstans eller visste du inte vad du skulle göra?
- Hackade spelet, blev telefonen varm eller kraschade appen?
- Fungerar "Fortsätt" efter att du stängt appen helt?

Skicka feedback direkt i TestFlight: ta en skärmdump i spelet och välj "Dela betaversionsfeedback".
```

## TestFlight – "What to Test" (English)

```
Thanks for testing The Last Rail!

This is version 1.0, the game's first chapter. The game is in Swedish. Please play from the start:
1. New game (Nytt spel): follow the guide until you have repaired the locomotive and built the workshop (about 10–15 min).
2. Travel on to Rosthamn, Djupgruvan and Nordpasset.
3. Look for the five secrets.

We especially want to know:
- Do the joystick, sprint button and action button feel good?
- Is any text hard to read, or any button hard to hit?
- Did you get stuck, or not know what to do next?
- Did the game stutter, the phone get hot, or the app crash?
- Does "Fortsätt" (Continue) work after fully closing the app?

Send feedback in TestFlight: take a screenshot in the game and choose "Share Beta Feedback".
```

## Version 1.0 contents (internal summary)

* Chapter 1, "Sista avgången": a 10-step tutorial, five explorable stations, six routes (one locked as a story cliffhanger), 16 crafting recipes, 8 resource types, 5 secrets and a journal with documents, blueprints and radio fragments.
* iPhone, landscape only, iOS 17 or later. Touch controls: floating joystick, action and sprint buttons, multi-touch.
* Local autosave with a backup copy. Fully offline. No ads, no in-app purchases, no data collection.

## Changes made during release preparation (compared with internal 0.2)

* Version set to 1.0 (build 1). The main menu reads the version from the app bundle.
* New app icon: opaque 1024 px pixel art of the in-game locomotive (Lok 7). The previous icon had an alpha channel, which App Store Connect rejects.
* Removed the "Ej i version 0.2" placeholder tiles from the Wagons panel, and "coming in a future version" texts from the Polaris route and the unused wagon descriptions.
* Story texts reflowed so that sentences no longer break mid-line in dialogs. Long dialogs flash a scroll indicator.
* Development launch arguments (`-TLRScenario`, `-TLRFreshStart`, `-TLRShowFPS`) are compiled out of Release builds.
* Added a privacy manifest (`PrivacyInfo.xcprivacy`), `ITSAppUsesNonExemptEncryption = NO`, Swedish as the development language and a dark launch screen.
