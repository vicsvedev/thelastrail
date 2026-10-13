import Foundation

/// Nordpasset — the mountain station where the radio signal is strongest.
enum NordpassetLayout {
    static let layout = StationLayout(
        station: .nordpasset,
        rows: [
        "RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR", // 0
        "RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR", // 1
        "RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR", // 2
        "RR..R..R..R..R..R.xxxxx..R..R..R..R..R..R..R", // 3
        "R.................xxxxx....................R", // 4
        "R...R.R.......T.....x.........########.....R", // 5
        "R..................x=.........#______#.....R", // 6
        "R...................=x........#______#.....R", // 7
        "R...................=.........#______#.....R", // 8
        "R...................=.........#______#.....R", // 9
        "R...................=.........#______#.....R", // 10
        "R............R......=.........###_####.....R", // 11
        "R...................=............,........RR", // 12
        "R...................=............,.........R", // 13
        "R................R..=.........R..,.........R", // 14
        "RT..#########.......=........T...,T..R....RR", // 15
        "R...#_______#.......=.......~~~~~,~..R....RR", // 16
        "R...#_______#.......=......~~~~~~,~~.RRRR.RR", // 17
        "R...#_______#.......=.......~~~~~,~..RRRR.RR", // 18
        "R...#_______#.......=............,...RRRR.RR", // 19
        "R...####_####.......=........R...,..RRRRR.RR", // 20
        "R.......,,,,,,,,,,,,,,,,,,,,,,,,,,..RRRRR.RR", // 21
        "R.......,..................................R", // 22
        "R.........PPPPLPPPPPPPPPPPPPPLPPPP..RRRRR.RR", // 23
        "============================================", // 24
        "RRRRRRRRRR.RRRRRRRRRRRRRRRRRRRRRRRR..R..RRRR", // 25
        "RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR.RRRR.RRRRRRR", // 26
        "RRRRRRRRRRRRR.RR.RRRRRRR.R.RRRR.RRRRRRRRRRRR", // 27
        "RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR", // 28
        "RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR", // 29
        ],
        objects: [
            L.machine("terminal", .radioTerminal, 33, 6, look: .terminal),
            L.machine("generator", .generator, 29, 11, look: .generator),
            L.res("kolbinge", .coal, 3, 27, 9, look: .coalBin, renewable: true),
            L.res("ved_1", .wood, 3, 3, 10, renewable: true),
            L.res("ved_2", .wood, 3, 15, 8, renewable: true),
            L.res("skrot", .scrap, 2, 24, 13, renewable: true),
            L.res("stationshus_mat", .food, 3, 5, 16),
            L.res("stationshus_forskning", .researchParts, 2, 11, 19),
            L.crate("stationshus_lada", [.wood: 3, .scrap: 3], 6, 19),
            L.note("skylt_perrong", .nordpassetSign, 12, 22, look: .sign),
            L.sign("spar_slut", "Norra spåret", "Rälsen försvinner under ett jättelikt ras. Någonstans bortom berget fortsätter spåret mot Station Polaris.\n\nHär kommer du inte förbi – inte än.", 21, 9),
            L.note("roset", .nordpassetCairn, 39, 15, look: .cairn, secret: .nordpassetCairn),
            L.res("roset_forskning", .researchParts, 3, 40, 16),
        ],
        buildings: [
            L.building("radiotorn", "Radiotornet", 30, 5, 8, 7, roof: 0x4A5060),
            L.building("stationshus", "Stationshuset", 4, 15, 9, 6, roof: 0x7A3A2A),
        ],
        zones: [
            L.zone("ras", 18, 3, 5, 6, .caption("Vinden viner genom passet. Spåret norrut slutar i ett hav av sten.")),
            L.zone("torn_in", 31, 6, 6, 5, .caption("Radiotornet. Bruset är öronbedövande här inne.")),
        ],
        trainFront: L.p(36, 24),
        spawn: L.p(34, 23),
        weather: .snow
    )
}
