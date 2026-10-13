import Foundation

enum ResourceCatalog {
    static func info(_ type: ResourceType) -> ResourceInfo {
        switch type {
        case .scrap:
            return ResourceInfo(type: type, name: "Järnskrot",
                                description: "Rostiga plåtbitar, bultar och rör. Grunden för nästan allt du bygger.",
                                stackLimit: nil, fuelValue: 0)
        case .wood:
            return ResourceInfo(type: type, name: "Trä",
                                description: "Torra plankor och grenar. Bra byggmaterial – och kan eldas i nödfall.",
                                stackLimit: nil, fuelValue: 2)
        case .copper:
            return ResourceInfo(type: type, name: "Koppar",
                                description: "Kopparledningar och rör. Behövs för motorer och elektronik.",
                                stackLimit: nil, fuelValue: 0)
        case .coal:
            return ResourceInfo(type: type, name: "Kol",
                                description: "Stenkol från gruvorna. Brinner länge och varmt i lokets panna.",
                                stackLimit: nil, fuelValue: 5)
        case .fuel:
            return ResourceInfo(type: type, name: "Bränsle",
                                description: "En dunk diesel. Fyller lokets tank rejält.",
                                stackLimit: 20, fuelValue: 10)
        case .machineParts:
            return ResourceInfo(type: type, name: "Maskindelar",
                                description: "Kugghjul, lager och ventiler i hyfsat skick.",
                                stackLimit: nil, fuelValue: 0)
        case .food:
            return ResourceInfo(type: type, name: "Mat",
                                description: "Konserver, bär och torkad fisk. Ät från ryggsäcken för att återfå hälsa.",
                                stackLimit: nil, fuelValue: 0)
        case .researchParts:
            return ResourceInfo(type: type, name: "Forskningsdelar",
                                description: "Märkliga komponenter från forskningsanläggningar. Vad användes de till?",
                                stackLimit: nil, fuelValue: 0)
        }
    }

    static func name(_ type: ResourceType) -> String { info(type).name }

    /// Burnable resources. Coal is burned first; wood last because it is also a building material.
    static let burnables: [ResourceType] = [.coal, .fuel, .wood]
    /// Burned by "Fyll tanken". Wood is only burned on purpose or when a trip needs it.
    static let tankFillers: [ResourceType] = [.coal, .fuel]
}

enum ItemCatalog {
    static func info(_ type: ItemType) -> ItemInfo {
        switch type {
        case .crowbar:
            return ItemInfo(type: type, name: "Kofot",
                            description: "Bänder upp fastrostade dörrar och lådor.", kind: .tool)
        case .headlamp:
            return ItemInfo(type: type, name: "Pannlampa",
                            description: "Lyser upp mörka tunnlar. Utan den kommer du inte långt in i gruvan.", kind: .tool)
        case .fuse:
            return ItemInfo(type: type, name: "Säkring",
                            description: "En tung keramisk högspänningssäkring. Passar i gamla ställverk.", kind: .keyItem)
        case .repairKit:
            return ItemInfo(type: type, name: "Reparationssats",
                            description: "Verktyg, tejp och reservdelar. Lagar trasiga maskiner ute i världen.", kind: .consumable)
        case .signalDecoder:
            return ItemInfo(type: type, name: "Signalavkodare",
                            description: "Filtrerar bruset i lokets radio. Kanske finns det fler meddelanden i det.", kind: .tool)
        }
    }

    static func name(_ type: ItemType) -> String { info(type).name }
}

/// Static wagon data. Wagons without `buildable` are part of the architecture but not yet in the game.
struct WagonInfo {
    let type: WagonType
    let name: String
    let description: String
    let weight: Double
    let storageCapacity: Int
    let availableInThisVersion: Bool
}

enum WagonCatalog {
    static func info(_ type: WagonType) -> WagonInfo {
        switch type {
        case .cargo:
            return WagonInfo(type: type, name: "Lastvagn",
                             description: "Förvarar resurser. Kan byggas om med en verkstadsbänk.",
                             weight: 12, storageCapacity: 80, availableInThisVersion: true)
        case .workshop:
            return WagonInfo(type: type, name: "Verkstadsvagn",
                             description: "En fullt utrustad verkstad. Låser upp avancerade konstruktioner.",
                             weight: 14, storageCapacity: 0, availableInThisVersion: true)
        case .living:
            return WagonInfo(type: type, name: "Bostadsvagn",
                             description: "En egen plats med kamin och säng. Vila här för full hälsa.",
                             weight: 10, storageCapacity: 0, availableInThisVersion: true)
        case .generator:
            return WagonInfo(type: type, name: "Generatorvagn",
                             description: "Producerar el men drar bränsle.",
                             weight: 16, storageCapacity: 0, availableInThisVersion: false)
        case .greenhouse:
            return WagonInfo(type: type, name: "Växthusvagn",
                             description: "Odlar mat över tid men kräver el.",
                             weight: 12, storageCapacity: 0, availableInThisVersion: false)
        case .research:
            return WagonInfo(type: type, name: "Forskningsvagn",
                             description: "Analyserar artefakter och låser upp teknik.",
                             weight: 12, storageCapacity: 0, availableInThisVersion: false)
        }
    }
}
