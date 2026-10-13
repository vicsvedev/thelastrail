import Foundation

enum SaveError: Error, Equatable {
    case noSave
    case corrupted
    case unsupportedVersion(Int)
}

/// JSON save games in Application Support. Writes are atomic and the previous save is kept as a backup.
struct SaveSystem {
    let directory: URL

    static let fileName = "save.json"
    static let backupName = "save.backup.json"

    static var defaultDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("TheLastRail", isDirectory: true)
    }

    init(directory: URL = SaveSystem.defaultDirectory) {
        self.directory = directory
    }

    var saveURL: URL { directory.appendingPathComponent(Self.fileName) }
    var backupURL: URL { directory.appendingPathComponent(Self.backupName) }

    func save(_ state: GameState) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(state)
        let fm = FileManager.default
        // Keep the last good save as a backup before replacing it.
        if fm.fileExists(atPath: saveURL.path), (try? decode(Data(contentsOf: saveURL))) != nil {
            _ = try? fm.removeItem(at: backupURL)
            try? fm.copyItem(at: saveURL, to: backupURL)
        }
        try data.write(to: saveURL, options: .atomic)
    }

    func load() throws -> GameState {
        let fm = FileManager.default
        if fm.fileExists(atPath: saveURL.path), let data = try? Data(contentsOf: saveURL) {
            do { return try decode(data) } catch SaveError.unsupportedVersion(let v) {
                throw SaveError.unsupportedVersion(v)
            } catch {
                // Fall through to the backup.
            }
        }
        if fm.fileExists(atPath: backupURL.path), let data = try? Data(contentsOf: backupURL) {
            if let state = try? decode(data) { return state }
            throw SaveError.corrupted
        }
        throw fm.fileExists(atPath: saveURL.path) ? SaveError.corrupted : SaveError.noSave
    }

    var hasValidSave: Bool { (try? load()) != nil }

    func deleteAll() {
        try? FileManager.default.removeItem(at: saveURL)
        try? FileManager.default.removeItem(at: backupURL)
    }

    func decode(_ data: Data) throws -> GameState {
        struct VersionProbe: Decodable { let version: Int }
        guard let probe = try? JSONDecoder().decode(VersionProbe.self, from: data) else { throw SaveError.corrupted }
        if probe.version > GameState.currentVersion { throw SaveError.unsupportedVersion(probe.version) }
        let migrated = try SaveMigration.migrate(data, from: probe.version)
        do {
            var state = try JSONDecoder().decode(GameState.self, from: migrated)
            state.version = GameState.currentVersion
            return state
        } catch {
            throw SaveError.corrupted
        }
    }
}

/// Upgrades older save JSON to the current schema, one version at a time.
enum SaveMigration {
    static func migrate(_ data: Data, from version: Int) throws -> Data {
        var data = data
        var v = version
        while v < GameState.currentVersion {
            data = try step(data, from: v)
            v += 1
        }
        return data
    }

    private static func step(_ data: Data, from version: Int) throws -> Data {
        // Version 1 is the first schema. Future migrations transform the JSON dictionary here.
        data
    }
}

/// Player preferences, stored next to the save.
struct GameSettings: Codable, Equatable {
    var masterVolume: Double = 0.8
    var musicVolume: Double = 0.55
    var effectsVolume: Double = 0.8
    var muted = false
    var screenShake = true
    var showHints = true
    var fullscreen = false
}

struct SettingsStore {
    let directory: URL
    init(directory: URL = SaveSystem.defaultDirectory) { self.directory = directory }

    var url: URL { directory.appendingPathComponent("settings.json") }

    func load() -> GameSettings {
        guard let data = try? Data(contentsOf: url),
              let settings = try? JSONDecoder().decode(GameSettings.self, from: data) else { return GameSettings() }
        return settings
    }

    func save(_ settings: GameSettings) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(settings) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
