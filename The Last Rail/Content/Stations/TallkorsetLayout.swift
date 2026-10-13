import Foundation

/// Tallkorset — a small forest station where the tracks split.
enum TallkorsetLayout {
    static let layout = StationLayout(
        station: .tallkorset,
        rows: [
        "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT", // 0
        "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT", // 1
        "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT", // 2
        "TTTTTTT..g..TTTTTTTTTt....T...xxx....f......gT", // 3
        "TTTTTTT.....TTTTTTTTT.g....g.T.......fwwwww..T", // 4
        "TTTTTTT.....TTTTTTTTT......g.........wwwwww..T", // 5
        "TTTTTTTTTbTTTTTTTTTTT...######.....T..wwwww..T", // 6
        "TTTTT,,,,bTTTTTTTTTTT...#____#.........w.....T", // 7
        "T....,##########....T...#____#............f..T", // 8
        "TT...,#________#..gg....#____#........g......T", // 9
        "T..T.,#________#........##_###.......T......gT", // 10
        "T....,#________#........g.,.....f............T", // 11
        "T....,#________#..........,..................T", // 12
        "T....,#________#...TT.,...,.t...f##########..T", // 13
        "T.T..,####_#####......,.....T.T..#c_______#..T", // 14
        "T..g.,....,...........,.T........#________#..T", // 15
        "T....,,,,,,,,,,,,,,,,,,..........#________#..T", // 16
        "T.T......TTg..f..T....,..........#________#..T", // 17
        "T...........T.....t.T.,.Tg..f....#________#..T", // 18
        "T.gf.....g............,,,,,,,....#_______k#..T", // 19
        "T........g........##########,...g####_#####..T", // 20
        "T..T..g.....x.....#________#,,,,,,,,,,.......T", // 21
        "T.......g......t..#________#.tg.....g........T", // 22
        "T............g....#________#.................T", // 23
        "T.................####_#####............R..T.T", // 24
        "T.............PPPPPPPPPPPPPPPPPPPPP..........T", // 25
        "T.............PPLPPPPPPPPPPPPPPPPLP..........T", // 26
        "==============================================", // 27
        "TTTTTT.TTTTTT.TT.TTTTTTTT..TTTTT.TTTTTTTTTTTTT", // 28
        "TT.TTTTTTTTTTTT.TTTTTTTTTTTTTT.TTT.TTTTTTTTTTT", // 29
        "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT", // 30
        "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT", // 31
        ],
        objects: [
            // Warehouse
            L.crate("lager_lada", [.scrap: 3, .wood: 2], 13, 10),
            L.res("lager_skrot", .scrap, 3, 8, 12),
            // Shed
            L.note("bod_brev", .tallkorsetHiddenNote, 28, 7),
            L.res("bod_bransle", .fuel, 1, 25, 7),
            // Workshop
            L.blueprint("verkstad_ritning", .workshop, .tallkorsetWorkshopBlueprint, 40, 15),
            L.res("verkstad_skrot", .scrap, 3, 36, 16),
            // Station building
            L.crate("station_lada", [.food: 2, .scrap: 2], 19, 21),
            L.note("tidtabell", .tallkorsetTimetable, 25, 21, look: .sign),
            // Secret cache behind the warehouse
            L.crate("gomstalle", [.machineParts: 4, .fuel: 1, .food: 2], 8, 4, secret: .tallkorsetCache),
            L.note("gomstalle_lapp", .tallkorsetCacheNote, 10, 4),
            // Forest resources
            L.res("vedtrave_1", .wood, 3, 3, 22, renewable: true),
            L.res("vedtrave_2", .wood, 3, 13, 19, renewable: true),
            L.res("vedtrave_3", .wood, 3, 43, 12, renewable: true),
            L.res("barbuske_1", .food, 2, 8, 24, look: .berryBush, renewable: true),
            L.res("barbuske_2", .food, 2, 41, 9, look: .berryBush, renewable: true),
            L.res("skrot_spar", .scrap, 2, 30, 23),
            L.res("skrothog", .scrap, 2, 2, 12, renewable: true),
            L.sign("skylt", "TALLKORSET", "Tallkorset 212 m ö.h.\n← Gamla depån   Rosthamn →\n↑ Norra linjen mot Nordpasset", 35, 25),
        ],
        buildings: [
            L.building("lager", "Lagret", 6, 8, 10, 7, roof: 0x4A5A3A),
            L.building("bod", "Boden", 24, 6, 6, 5, roof: 0x6A4A2E),
            L.building("verkstad", "Verkstaden", 33, 13, 10, 8, roof: 0x5A4438),
            L.building("stationshus", "Stationshuset", 18, 20, 10, 5, roof: 0x7A3A2A),
        ],
        zones: [
            L.zone("verkstad_in", 34, 14, 8, 6, .tutorialWorkshop),
            L.zone("stationshus_in", 19, 21, 8, 3, .caption("Regnet smattrar mot taket. Väntsalen är tom.")),
            L.zone("glanta", 7, 3, 5, 3, .caption("En liten glänta, dold bakom granarna.")),
        ],
        trainFront: L.p(38, 27),
        spawn: L.p(36, 26),
        weather: .rain
    )
}
