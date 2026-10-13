import Foundation

/// Djupgruvan — the mining town and its dark tunnels.
enum DjupgruvanLayout {
    static let layout = StationLayout(
        station: .djupgruvan,
        rows: [
        "RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR", // 0
        "R##############################################R", // 1
        "R##############################################R", // 2
        "R##::::::########:c::::::::::::#####::::::::###R", // 3
        "R##::::::########::::::::^:::::###########::###R", // 4
        "R##::::::########:::::::::^::::###########::###R", // 5
        "R##::::::########:::::^::::::::###########::###R", // 6
        "R##::::::########:::::::::::::k###########::###R", // 7
        "R####X#################:#############:::::::###R", // 8
        "R###:::::::############:#############:::::::###R", // 9
        "R###k::::::############:#############:::::::###R", // 10
        "R###:::::::############^#############:::::::###R", // 11
        "R###:::::::############^#############:::::::###R", // 12
        "R###::::::c############:#############:::::::###R", // 13
        "R###::::::::::^::::::::::::::::^::::::::::::###R", // 14
        "R#####:::::::::^:::::::::::::::::::::::::::c###R", // 15
        "R#####################:::######################R", // 16
        "R#####################:::######################R", // 17
        "R#####################:::######################R", // 18
        "R#####################:::######################R", // 19
        "RRRRRRRRRRRRRRRRRRRRRR:::RRRRRRRRRRRRRRRRRRRRRRR", // 20
        "R....R....R....R....R....R....R....R....R....R.R", // 21
        "R.............,,,,,,,,,,,,,,,,,................R", // 22
        "R...########...........,.........########......R", // 23
        "R...#______#.....kk....,.........#______#......R", // 24
        "R...#______#...........,....c....#______#...R..R", // 25
        "R.R.#______#...........,.........#______#......R", // 26
        "R...#______#...........,.........###_####......R", // 27
        "R...####_###...L.......,.......L.............R.R", // 28
        "R...........PPPPPPPPPPPPPPPPPPPPPPPP...........R", // 29
        "================================================", // 30
        "RRR..RRRRRRRRRRRR.RRRRRRRRRRRRRRRRRRRR..RRRRRRRR", // 31
        "RRRRRR.RRRR.RRRRRRRRRRRRRRRR.RRRR.R.RRRRRRRRRRRR", // 32
        "RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR", // 33
        ],
        objects: [
            // Village
            L.door("kontor_dorr", .tool(.crowbar), 8, 28, look: .doorWood),
            L.item("sakring", .fuse, 9, 25),
            L.note("stigaren", .djupgruvanForeman, 6, 25),
            L.res("kontor_mat", .food, 2, 5, 27),
            L.res("stuga_mat", .food, 3, 34, 24),
            L.res("stuga_delar", .machineParts, 2, 39, 24),
            L.res("kolbinge", .coal, 3, 20, 24, look: .coalBin, renewable: true),
            L.res("kolhog_ute", .coal, 2, 27, 23, renewable: true),
            L.res("gruvvagn_skrot", .scrap, 4, 30, 23),
            L.res("stottor", .wood, 4, 13, 26),
            L.sign("skylt", "DJUPGRUVAN", "Djupgruvan – schakt 1 till 4.\nVARNING: rasrisk i gamla gången.\nLampa obligatorisk i inre schaktet.", 12, 22),
            // Mine
            L.note("gruvarbetaren", .djupgruvanMiner, 22, 17),
            L.res("kol_1", .coal, 2, 6, 10, renewable: true),
            L.res("kol_2", .coal, 2, 8, 12, renewable: true),
            L.res("galleri_skrot", .scrap, 2, 25, 15, renewable: true),
            L.res("kopparmalm_1", .copper, 2, 40, 9, look: .copperOre, renewable: true),
            L.res("kopparmalm_2", .copper, 2, 42, 12, look: .copperOre, renewable: true),
            L.res("kopparmalm_3", .copper, 3, 38, 13, look: .copperOre),
            L.res("gang_forskning", .researchParts, 1, 36, 3),
            L.barrier("morker", .tool(.headlamp), "Gången fortsätter in i ett kompakt mörker. Du ser inte handen framför dig.\n\nUtan en pannlampa vågar du inte gå längre.", 23, 10),
            // Inner shaft
            L.blueprint("gruvbanan_ritning", .trackRepair, .djupgruvanBlueprint, 28, 4),
            L.res("schakt_forskning", .researchParts, 2, 19, 6),
            L.res("schakt_delar", .machineParts, 2, 29, 6),
            // Hidden side passage
            L.crate("sidogang_lada", [.machineParts: 3, .researchParts: 3], 4, 4, look: .toolbox),
            L.note("sidogang_lapp", .djupgruvanSidePassage, 7, 4),
        ],
        buildings: [
            L.building("kontor", "Stigarens kontor", 4, 23, 8, 6, roof: 0x5A3A2A),
            L.building("stuga", "Gruvarbetarstugan", 33, 23, 8, 5, roof: 0x6A4A3A),
        ],
        zones: [
            L.zone("sidogang", 3, 3, 6, 5, .secret(.djupgruvanSidePassage)),
            L.zone("ingang", 22, 16, 3, 4, .caption("Kall, fuktig luft strömmar ut ur gruvan.")),
            L.zone("schakt", 17, 3, 14, 5, .caption("Det inre schaktet. Någonstans droppar vatten.")),
        ],
        trainFront: L.p(39, 30),
        spawn: L.p(37, 29),
        darkAreas: [TileRect(col: 1, row: 1, width: 46, height: 20)],
        weather: .none
    )
}
