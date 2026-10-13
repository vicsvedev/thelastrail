# Beskrivning – svenska (primärspråk)

Klistra in texten mellan linjerna i fältet **Beskrivning** i App Store Connect (max 4 000 tecken). Inga Markdown-tecken används i själva texten, eftersom App Store inte tolkar Markdown.

---

Du vaknar i ett övergivet lokstall. Järnvägsnätet är tyst, stationerna tomma, och någonstans i bruset från en gammal radio hörs en röst: ”Om någon fortfarande hör det här... följ spåren norrut.”

The Last Rail är ett lugnt, atmosfäriskt utforskningsspel i pixelgrafik. Du reser med ett gammalt diesellok mellan övergivna stationer, samlar resurser, bygger ut ditt tåg och tar steg för steg reda på vad som hände med människorna som lämnade allt bakom sig.

UTFORSKA EN ÖVERGIVEN VÄRLD
Gå runt på fem stationer med olika miljöer: en depå på slätten, en skogsstation i regnet, en rostig industristad, ett gruvsamhälle med beckmörka gångar och en fjällstation högt uppe i passet. Se upp för slam, fallande stenar och heta ångventiler.

RES MED LOKET
Laga Lok 7 och ge dig ut på spåren. Planera resorna på järnvägskartan: varje sträcka kostar bränsle, och ett tungt tåg går långsammare och drar mer.

BYGG OCH UPPGRADERA DITT TÅG
Bygg en verkstad i lastvagnen och tillverka verktyg, uppgraderingar och nya vagnar: verkstadsvagn, bostadsvagn och extra lastvagnar. Förbättra motorn, bränsleförbrukningen och lagret, och laga raserade spår för att öppna nya vägar.

SAMLA RESURSER
Leta upp järnskrot, trä, koppar, kol, bränsle, maskindelar, mat och forskningsdelar. Ryggsäcken rymmer bara så mycket, så tänk efter vad du bär till tåget.

HITTA DOLDA PLATSER
Varje station har hemligheter för den som letar noga: gömda förråd, en låst dörr med en kod att knäcka och en igenmurad gång djupt inne i gruvan.

LÖS MYSTERIET
Läs dagböcker, lappar och radiologgar som du hittar längs vägen. Vad var Projekt Vinterljus? Varför stängdes Norra linjen? Och vem sänder fortfarande från andra sidan berget?

GJORT FÖR IPHONE
- Spelas i liggande läge med pekkontroller: styrspak, handlingsknapp och springknapp
- En steg-för-steg-guide i början, som du kan hoppa över
- Sparar automatiskt, och du kan fortsätta där du slutade
- Fungerar helt utan internetanslutning
- Ingen reklam, inga köp i appen och ingen datainsamling

Version 1.0 innehåller berättelsens första kapitel. Spelet är på svenska.

---

## Nyckelfakta (för granskning, inte för publicering)

Varje påstående ovan motsvarar innehåll som finns i spelet:

| Påstående | Var i projektet |
|---|---|
| Fem stationer | `Content/Stations/WorldCatalog.swift`: Gamla depån, Tallkorset, Rosthamn, Djupgruvan, Nordpasset |
| Slam, fallande stenar, ångventiler | `Models/StationLayout.swift`, `hazardDamage` |
| Lok 7, diesellok | `Content/Story/JournalCatalog.swift` (depåns loggbok), tutorialtexter |
| Bränsle per sträcka, vikt påverkar resor | `Systems/Travel/TrainStats.swift`, `TravelSystem.swift` |
| Verkstad, verktyg, uppgraderingar, vagnar, spårreparation | `Content/Recipes/RecipeCatalog.swift` (16 recept) |
| Åtta resurstyper | `Models/ResourceType.swift` |
| Fem hemligheter (gömda förråd, kodlås, igenmurad gång) | `Models/World.swift`, `SecretID` |
| Dagbok, ritningar, radiofragment | `Content/Story/JournalCatalog.swift` |
| Tutorial som kan hoppas över | `Systems/Tutorial/TutorialSystem.swift`, pausmenyn "Hoppa över tutorial" |
| Autosparning | sparar när appen går till bakgrunden, `SaveSystem.swift` |
