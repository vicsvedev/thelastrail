import Foundation

/// Rosthamn — a silent industrial town full of copper and machine parts.
enum RosthamnLayout {
    static let layout = StationLayout(
        station: .rosthamn,
        rows: [
        "################################################", // 0
        "#xxxx..xxxxxxx.xxxxx..xxxxxxx..xxxxxxxxxxxxx.xx#", // 1
        "#..............................................#", // 2
        "#...################..#######..#############...#", // 3
        "#...#_k_____c______#..#_____#..#__________c#...#", // 4
        "#...#______________#..#_____#..#__________c#...#", // 5
        "#...#______________#..#_____#..#___________#...#", // 6
        "#...#______________#..#_____#..#___________#...#", // 7
        "#...####_######_####..#_____#..#___________#...#", // 8
        "#...#_______________,.###_###..#k__________#...#", // 9
        "#.k.#______________#,....,.....#####_#######...#", // 10
        "#.k.#____V_________#,,,,,,..........,..........#", // 11
        "#...#_________V____#.....,....FFFFFF,........c.#", // 12
        "#...#______________#....x,.....V..V.,..........#", // 13
        "#...#c____________c#.....,..........,.#######..#", // 14
        "#...#######_########.....,.....g.x..,.#_____#..#", // 15
        "#..........,....x......~~~~~...x....,.#_____#..#", // 16
        "#.......g..,..........~~~~~~~.......,.#_____#..#", // 17
        "#..........,..g........~~~~~........,.#_____#..#", // 18
        "#.g~~~.....,.............~x.........,.#_____#..#", // 19
        "#..~~~.....,.........c...gx.......x.,.###_###..#", // 20
        "#......g...,.................k......,....,.....#", // 21
        "#.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.#", // 22
        "#......x.....................................g.#", // 23
        "#...............Lx.x...g........L............R.#", // 24
        "#...........PPPPPPPPPPPPPPPPPPPPPPPPP..........#", // 25
        "#...........PPPPPPPPPPPPPPPPPPPPPPPPP..........#", // 26
        "================================================", // 27
        "#.xxxxxxxxx.xxx..xxx.xxxxx.xxxxxxxxx.xx.x.xxxxx#", // 28
        "#xxxxxxxxxxxx.xxxxxxxxxx.xxxxxx.xx..xxxxxxxxxxx#", // 29
        "#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx#", // 30
        "################################################", // 31
        ],
        objects: [
            // Factory hall
            L.res("fabrik_koppar_1", .copper, 3, 7, 5),
            L.note("formannen", .rosthamnForeman, 16, 5),
            L.res("fabrik_forskning", .researchParts, 1, 17, 7),
            L.res("fabrik_koppar_2", .copper, 2, 17, 10),
            L.res("fabrik_delar", .machineParts, 2, 6, 12),
            L.res("fabrik_skrot", .scrap, 5, 12, 13),
            L.res("hall_skrot", .scrap, 3, 10, 6),
            // Equipment room (code from Tallkorset)
            L.door("kodrum_dorr", .code("4172"), 25, 9, look: .keypadDoor, secret: .rosthamnCodeRoom),
            L.note("klotter", .rosthamnScratch, 24, 10),
            L.blueprint("kodrum_ritning", .workshopWagon, .rosthamnCodeRoom, 24, 5),
            L.crate("kodrum_lada", [.machineParts: 4, .copper: 2], 27, 5, look: .locker),
            // Warehouse (crowbar)
            L.door("lager_dorr", .tool(.crowbar), 36, 10),
            L.blueprint("lager_ritning", .livingWagon, .rosthamnWarehouse, 33, 5),
            L.crate("lager_lada", [.copper: 4, .scrap: 4], 40, 6),
            L.res("lager_mat", .food, 3, 38, 8),
            // Signal box
            L.machine("stallverk", .signalBox, 41, 15, look: .signalBox),
            // Yard
            L.res("oljefat_1", .fuel, 1, 2, 13, look: .oilDrum, renewable: true),
            L.res("oljefat_2", .fuel, 1, 3, 14, look: .oilDrum, renewable: true),
            L.res("skrothog", .scrap, 5, 30, 20, renewable: true),
            L.res("skrotvagn", .scrap, 4, 8, 23),
            L.res("skrotmaskin", .machineParts, 1, 46, 17, renewable: true),
            L.res("koppar_ror_1", .copper, 2, 28, 13),
            L.res("koppar_ror_2", .copper, 2, 6, 17),
            L.res("vaxellada", .machineParts, 2, 15, 19),
            L.sign("skylt", "ROSTHAMN", "Rosthamn – Norra Kopparverken.\nLeveranser till Projekt Vinterljus: spår 2.", 38, 24),
        ],
        buildings: [
            L.building("fabrik", "Fabrikshallen", 4, 3, 16, 13, roof: 0x5A4A44),
            L.building("kodrum", "Utrustningsrummet", 22, 3, 7, 7, roof: 0x3E4A56),
            L.building("lager", "Lagret", 31, 3, 13, 8, roof: 0x6A4030),
            L.building("stallverk", "Ställverket", 38, 14, 7, 7, roof: 0x4A3A36),
        ],
        zones: [
            L.zone("fabrik_in", 5, 9, 14, 6, .caption("Maskinerna står tysta. Ånga pyser ur trasiga rör.")),
            L.zone("stallverk_in", 39, 15, 5, 5, .caption("Ställverket. Hundratals reläer och en karta över distriktets växlar.")),
        ],
        trainFront: L.p(40, 27),
        spawn: L.p(38, 26),
        weather: .fog
    )
}
