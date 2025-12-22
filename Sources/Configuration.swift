import Foundation

struct MousePosition: Codable {
    let x: Int
    let y: Int

    init(x: Int, y: Int) {
        self.x = min(max(x, 0), 100)
        self.y = min(max(y, 0), 100)
    }
}

struct AppBinding: Codable {
    let appName: String
    let bind: String
    let mousePosition: MousePosition?
    let centeredWidth: Int?
}

struct Config: Codable {
    let swap: String
    let full: String
    let defaultCenteredWidth: Int
    let apps: [AppBinding]

    static let defaultConfigPath = NSHomeDirectory() + "/.config/hypertile.config.json"

    func getCenteredWidth(for binding: AppBinding) -> Int {
        if let width = binding.centeredWidth {
            return min(max(width, 40), 100)
        }
        return min(max(defaultCenteredWidth, 40), 100)
    }

    static func load(from path: String = defaultConfigPath) -> Config? {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: path) {
            let defaultConfig = Config.createDefault()
            defaultConfig.save(to: path)
            print("Created default configuration at: \(path)")
            return defaultConfig
        }

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("Failed to read configuration file at: \(path)")
            return nil
        }

        let decoder = JSONDecoder()
        guard let config = try? decoder.decode(Config.self, from: data) else {
            print("Failed to parse configuration file at: \(path)")
            return nil
        }

        return config
    }

    func save(to path: String) {
        let fileManager = FileManager.default
        let configDir = (path as NSString).deletingLastPathComponent

        if !fileManager.fileExists(atPath: configDir) {
            try? fileManager.createDirectory(atPath: configDir, withIntermediateDirectories: true)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        if let data = try? encoder.encode(self) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }

    static func createDefault() -> Config {
        return Config(
            swap: "7",
            full: "g",
            defaultCenteredWidth: 75,
            apps: [
                AppBinding(
                    appName: "iTerm2",
                    bind: "d",
                    mousePosition: MousePosition(x: 90, y: 50),
                    centeredWidth: nil
                ),
                AppBinding(
                    appName: "neovide",
                    bind: "f",
                    mousePosition: MousePosition(x: 90, y: 50),
                    centeredWidth: nil
                ),
                AppBinding(
                    appName: "Google Chrome",
                    bind: "e",
                    mousePosition: MousePosition(x: 50, y: 50),
                    centeredWidth: nil
                ),
                AppBinding(
                    appName: "Safari",
                    bind: "r",
                    mousePosition: MousePosition(x: 50, y: 50),
                    centeredWidth: nil
                ),
                AppBinding(
                    appName: "Microsoft Teams",
                    bind: "c",
                    mousePosition: MousePosition(x: 60, y: 50),
                    centeredWidth: nil
                ),
                AppBinding(
                    appName: "Microsoft Outlook",
                    bind: "v",
                    mousePosition: MousePosition(x: 50, y: 50),
                    centeredWidth: nil
                )
            ]
        )
    }

    func findBinding(for key: String) -> AppBinding? {
        return apps.first { $0.bind.lowercased() == key.lowercased() }
    }
}
