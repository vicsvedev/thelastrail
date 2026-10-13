import Foundation

/// Identifiers for sound effects. Implemented by `SoundManager`; gameplay code only names them.
enum SoundEffect: String, CaseIterable {
    case footstep, pickup, menuSelect, menuMove, craft, engineStart, arrival, secret
    case damage, radio, door, error, paper, departure, refuel, faint
}

enum DialogStyle: Equatable {
    case info
    case note
    case radio
    case discovery
    case blueprint
}

struct DialogContent: Equatable, Identifiable {
    let id = UUID()
    let title: String
    let text: String
    var style: DialogStyle = .info

    static func == (lhs: DialogContent, rhs: DialogContent) -> Bool { lhs.id == rhs.id }

    static func journal(_ id: JournalID) -> DialogContent {
        let entry = JournalCatalog.entry(id)
        let style: DialogStyle
        switch entry.category {
        case .radio: style = .radio
        case .document: style = .note
        case .discovery: style = .discovery
        case .blueprint: style = .blueprint
        }
        return DialogContent(title: entry.title, text: entry.text, style: style)
    }
}
