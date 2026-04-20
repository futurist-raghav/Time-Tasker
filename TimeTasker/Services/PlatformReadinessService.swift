import Foundation
import Darwin

struct PlatformReadinessService {
    static let shared = PlatformReadinessService()

    private init() {}

    var isAppleSiliconRuntime: Bool {
        #if arch(arm64)
        true
        #else
        false
        #endif
    }

    var isRosettaTranslated: Bool {
        var translated: Int32 = 0
        var size = MemoryLayout<Int32>.size
        let result = sysctlbyname("sysctl.proc_translated", &translated, &size, nil, 0)
        return result == 0 && translated == 1
    }

    var architectureLabel: String {
        isAppleSiliconRuntime ? "Apple Silicon" : "Intel"
    }

    var runtimeLabel: String {
        isRosettaTranslated ? "Rosetta" : "Native"
    }

    var osLabel: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(version.majorVersion).\(version.minorVersion) \(codename(for: version.majorVersion))"
    }

    var displayOSLabel: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(version.majorVersion).\(version.minorVersion)"
    }

    var supportLabel: String {
        let major = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        if major >= 27 {
            return "Post-Tahoe era"
        }
        if major >= 26 {
            return "Tahoe baseline"
        }
        if major >= 15 {
            return "Sequoia baseline"
        }
        return "Legacy baseline"
    }

    var appVersionLabel: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        return "v\(shortVersion) (\(build))"
    }

    var displayVersionLabel: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        return "\(shortVersion) build \(build)"
    }

    private func codename(for majorVersion: Int) -> String {
        switch majorVersion {
        case 26: return "Tahoe"
        case 25: return "Sequoia"
        case 24: return "Sonoma"
        case 23: return "Ventura"
        case 22: return "Monterey"
        default: return ""
        }
    }
}
