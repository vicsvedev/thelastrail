import Foundation

enum JournalCatalog {
    static let radioMessage = "Om någon fortfarande hör det här... följ spåren norrut."

    static func entry(_ id: JournalID) -> JournalEntry {
        switch id {
        case .radioFirst:
            return JournalEntry(id: id, title: "Radiosignalen", category: .radio, text: """
            Lokets gamla radio sprakar till liv när motorn startar. Genom bruset hörs en trött röst:

            ”\(radioMessage)”

            Meddelandet upprepas om och om igen. Någon, någonstans, sänder fortfarande.
            """)
        case .depotLogbook:
            return JournalEntry(id: id, title: "Depåns loggbok", category: .document, text: """
            12 mars 2132 — Inga tåg från söder på tre dagar. Telefonerna är döda.
            13 mars — Order från Nordpasset: alla fordon norrut. Ingen förklaring.
            14 mars — Sista avgången går i kväll. Alla ska med. Lok 7 står kvar, insprutarna är slut.
            Om någon hittar den här boken: vi lämnade inte för att vi ville.
            — Stationsmästare A. Lind
            """)
        case .depotStashNote:
            return JournalEntry(id: id, title: "Lappen under golvet", category: .document, text: """
            Till den som kommer efter oss.
            Vi gömde reserverna i Tallkorset, bakom lagret där granarna står tätast.
            Följ den nötta stigen. Ingen annan behöver veta.
            """)
        case .tallkorsetTimetable:
            return JournalEntry(id: id, title: "Tidtabellen i Tallkorset", category: .document, text: """
            Tavlan är blekt av sol och regn. Den sista raden är skriven för hand med krita:

            ”EXTRATÅG NORRUT 14/3 kl 23.40 — ALLA PLATSER FRIA”

            Under står det, med en annan handstil: ”Vi väntar vid Nordpasset.”
            """)
        case .tallkorsetWorkshopBlueprint:
            return JournalEntry(id: id, title: "Ritning: Grundläggande verkstad", category: .blueprint, text: """
            En vikt ritning över hur man bygger in en verkstadsbänk i en vanlig lastvagn.
            Någon har skrivit i marginalen: ”Ett tåg utan verkstad är bara en vagn på väg mot sitt sista stopp.”
            """)
        case .tallkorsetHiddenNote:
            return JournalEntry(id: id, title: "Brev till Jonas", category: .document, text: """
            Jonas,
            om du kommer tillbaka hit innan vi har gett oss av: verktygen och ritningarna ligger i utrustningsrummet i Rosthamn. Koden är densamma som alltid – din födelsedag. 4-1-7-2.
            Ta allt du kan bära och följ spåren norrut.
            / Maja
            """)
        case .tallkorsetCacheNote:
            return JournalEntry(id: id, title: "Reservförrådet", category: .discovery, text: """
            Bakom de täta granarna står en presenning över en hög med lådor.
            Maskindelar, en dunk diesel och konserver – omsorgsfullt inslaget mot fukten.
            Någon hoppades att någon skulle komma.
            """)
        case .rosthamnForeman:
            return JournalEntry(id: id, title: "Förmannens dagbok", category: .document, text: """
            Ordern kom från Projekt Vinterljus i norr: tusen spolar koppartråd i veckan.
            Ingen vet vad de bygger däruppe. Lönerna är bra, så ingen frågar.
            Senaste veckorna har himlen haft en konstig färg på nätterna. Grönaktig.
            Folk sover dåligt. Radion sprakar på alla frekvenser.
            """)
        case .rosthamnScratch:
            return JournalEntry(id: id, title: "Klotter på väggen", category: .document, text: """
            Inristat i färgen bredvid den låsta dörren:
            ”KODEN? FRÅGA JONAS I TALLKORSET.”
            """)
        case .rosthamnCodeRoom:
            return JournalEntry(id: id, title: "Ritning: Verkstadsvagn", category: .blueprint, text: """
            I utrustningsrummet ligger en hel pärm med konstruktionsritningar. Den viktigaste: en komplett verkstadsvagn med svarv, svets och verktygsväggar. Med den kan du bygga nästan vad som helst.
            """)
        case .rosthamnWarehouse:
            return JournalEntry(id: id, title: "Ritning: Bostadsvagn", category: .blueprint, text: """
            En arkitektritning av en ombyggd personvagn: kamin, säng, bokhylla och ett fönster mot spåret.
            Någon har ritat en liten katt i hörnet.
            """)
        case .rosthamnSignalBox:
            return JournalEntry(id: id, title: "Ställverket", category: .document, text: """
            Ställverket styr växlarna i hela distriktet. Ett handskrivet meddelande är tejpat på panelen:
            ”NORRA LINJEN STÄNGD PÅ ORDER AV VINTERLJUS. INGEN FÅR FÖLJA EFTER.”
            Säkringen till växelmotorerna är borttagen.
            """)
        case .djupgruvanMiner:
            return JournalEntry(id: id, title: "Gruvarbetarens anteckning", category: .document, text: """
            Den gamla gruvbanan går rakt genom berget till Nordpasset. Ingen har kört den sedan raset 2119.
            Ritningarna borde ligga kvar i det inre schaktet – men där är det beckmörkt.
            Ta med en lampa. Och se upp för stenarna i taket.
            """)
        case .djupgruvanForeman:
            return JournalEntry(id: id, title: "Stigarens kontor", category: .document, text: """
            Bland papperen i stigarens kontor ligger en kvittens:
            ”1 st säkring till ställverket i Rosthamn, uttagen på order. Förvaras här tills vidare.”
            Säkringen ligger kvar i lådan.
            """)
        case .djupgruvanBlueprint:
            return JournalEntry(id: id, title: "Ritning: Gamla gruvbanan", category: .blueprint, text: """
            En dammig rulle med spårritningar. Gruvbanan mellan Djupgruvan och Nordpasset är kortare än Norra linjen – om man bara kan laga rasen. Med rätt material borde det gå.
            """)
        case .djupgruvanSidePassage:
            return JournalEntry(id: id, title: "Den igenmurade gången", category: .discovery, text: """
            Bakom den spruckna muren finns ett gammalt förråd med gruvutrustning och lådor märkta ”VINTERLJUS – PROVER”. Proverna lyser svagt grönt i mörkret.
            """)
        case .nordpassetSign:
            return JournalEntry(id: id, title: "Skylten vid Nordpasset", category: .document, text: """
            NORDPASSET 1 142 m ö.h.
            Evakueringståg fortsätter till Station Polaris.
            Ta med varma kläder. Tänk på varandra.
            """)
        case .nordpassetLog:
            return JournalEntry(id: id, title: "Radiotornets logg", category: .discovery, text: """
            Terminalen startar med ett surr. Loggen är lång – de sista raderna lyder:

            ”Projekt Vinterljus skulle kyla himlen. Istället tystnade den. All elektronik söder om passet slogs ut på en natt. Vi evakuerade alla vi kunde till Polaris, bortom berget.
            Raset kom dagen efter sista tåget. Spåret är stängt.
            Jag sänder härifrån så länge strömmen räcker.
            Om någon fortfarande hör det här... följ spåren norrut.
            — E. Norrby, signalist”

            Längst ner står senaste sändningens tidsstämpel. Det är dagens datum.
            Meddelandet spelas inte upp från ett band. Någon sänder just nu – från andra sidan raset.
            """)
        case .nordpassetCairn:
            return JournalEntry(id: id, title: "Röset på klippavsatsen", category: .discovery, text: """
            Under stenarna ligger en plåtask med ett blekt fotografi: ett tåg fullt av människor som vinkar.
            På baksidan: ”Polaris, april 2132. Vi klarade oss. Kom efter.”
            """)
        case .decodedFragment1:
            return JournalEntry(id: id, title: "Avkodat fragment I", category: .radio, text: """
            ”...Polaris här. Reaktorn håller. Vi är 412 personer. Tunnelns norra mynning är fri men södra sidan är begravd under raset. Vi behöver en snöplog och sprängmedel...”
            """)
        case .decodedFragment2:
            return JournalEntry(id: id, title: "Avkodat fragment II", category: .radio, text: """
            ”...till alla tåg söder om passet: Vinterljus är inte avstängt. Det sover bara.
            Om himlen blir grön igen – kör inte under den. Vänta i en tunnel...”
            """)
        case .tutorialComplete:
            return JournalEntry(id: id, title: "Din resa har bara börjat", category: .discovery, text: """
            Loket lever, vagnen har en verkstad och spåren ligger öppna framför dig.
            Radiosignalen kommer från norr. Någonstans där uppe finns svaren.
            """)
        }
    }
}
