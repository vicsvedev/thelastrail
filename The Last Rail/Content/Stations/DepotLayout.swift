import Foundation

/// Gamla depån — the tutorial depot on the southern plain.
enum DepotLayout {
    static let layout = StationLayout(
        station: .depot,
        rows: [
        "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT", // 0
        "TTT..TTTTTTT..TT.TTTTT..TTTTTTT.TTTTT.TT", // 1
        "T...#######..........g....##########...T", // 2
        "T...#___cc#...g..g....L...#________#..gT", // 3
        "T...#_____#...t...........#________#...T", // 4
        "T...#_____#.......g.......#________#...T", // 5
        "T...#_____#........R......#k______c#...T", // 6
        "T...###_###...............####_#####...T", // 7
        "T......,.................g....,g....g..T", // 8
        "Tg.t...,,,,,,,,,,,,,,,,,,,,,,,,,,......T", // 9
        "T..........,.g.......,..L...kk.........T", // 10
        "TFFFFFFFFFF,FFFFFFFFF,FFFFFFFFFFFF...FFT", // 11
        "T##########_#########_#########........T", // 12
        "T#_cc_________________________#g.R....tT", // 13
        "T#____________________________#........T", // 14
        "T#_____________________________........T", // 15
        "T#======================================", // 16
        "T#_____________________________.g......T", // 17
        "T#____________________________#........T", // 18
        "T#c____________c____________kk#......t.T", // 19
        "T##############################........T", // 20
        "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTg..g....T", // 21
        "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT..T.....T", // 22
        "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT..g....TT", // 23
        "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT...T...T", // 24
        "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT", // 25
        ],
        objects: [
            L.machine("radio", .depotRadio, 2, 14, look: .radio),
            L.res("skrot_1", .scrap, 2, 6, 18),
            L.res("skrot_2", .scrap, 2, 28, 13),
            L.res("skrot_3", .scrap, 2, 15, 5),
            L.res("bransledunk", .fuel, 1, 34, 3),
            L.crate("forradslada", [.scrap: 2, .wood: 2], 28, 4),
            L.note("loggbok", .depotLogbook, 5, 4),
            L.note("lapp_golvet", .depotStashNote, 9, 6, secret: .depotStash),
            L.res("skrothog", .scrap, 3, 35, 20, renewable: true, requires: .tutorialComplete),
            L.res("lackande_fat", .fuel, 1, 36, 14, look: .oilDrum, renewable: true, requires: .tutorialComplete),
            L.sign("skylt", "GAMLA DEPÅN", "Södra slätten – lokstall 3.\nObehöriga äga ej tillträde.\n\nUnder skylten har någon ristat: ”Följ spåren norrut.”", 32, 10),
        ],
        buildings: [
            L.building("kontor", "Kontoret", 4, 2, 7, 6, roof: 0x5A3A2E),
            L.building("forrad", "Förrådet", 26, 2, 10, 6, roof: 0x4A4E58),
            L.building("lokstall", "Lokstallet", 1, 12, 30, 9, roof: 0x6A3A24),
        ],
        zones: [
            L.zone("forrad_in", 27, 3, 8, 4, .caption("Det luktar diesel och damm här inne.")),
            L.zone("kontor_in", 5, 3, 5, 4, .caption("Stationsmästarens kontor. Papper överallt.")),
        ],
        trainFront: L.p(26, 16),
        spawn: L.p(5, 15),
        weather: .dust
    )
}
