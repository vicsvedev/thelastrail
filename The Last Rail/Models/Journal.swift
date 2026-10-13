import Foundation

enum JournalID: String, Codable, CaseIterable {
    case radioFirst = "radio_forsta"
    case depotLogbook = "depan_loggbok"
    case depotStashNote = "depan_lapp"
    case tallkorsetTimetable = "tallkorset_tidtabell"
    case tallkorsetWorkshopBlueprint = "tallkorset_ritning"
    case tallkorsetHiddenNote = "tallkorset_dold_lapp"
    case tallkorsetCacheNote = "tallkorset_forrad"
    case rosthamnForeman = "rosthamn_formannen"
    case rosthamnScratch = "rosthamn_klotter"
    case rosthamnCodeRoom = "rosthamn_kodrum"
    case rosthamnWarehouse = "rosthamn_lagret"
    case rosthamnSignalBox = "rosthamn_stallverket"
    case djupgruvanMiner = "djupgruvan_gruvarbetaren"
    case djupgruvanForeman = "djupgruvan_stigaren"
    case djupgruvanBlueprint = "djupgruvan_ritning"
    case djupgruvanSidePassage = "djupgruvan_sidogang"
    case nordpassetSign = "nordpasset_skylt"
    case nordpassetLog = "nordpasset_logg"
    case nordpassetCairn = "nordpasset_roset"
    case decodedFragment1 = "avkodat_1"
    case decodedFragment2 = "avkodat_2"
    case tutorialComplete = "resan_borjar"
}

enum JournalCategory: String {
    case radio = "Radio"
    case document = "Dokument"
    case discovery = "Upptäckt"
    case blueprint = "Ritning"
}

struct JournalEntry {
    let id: JournalID
    let title: String
    let category: JournalCategory
    let text: String
}
