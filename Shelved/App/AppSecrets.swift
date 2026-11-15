import Foundation

/// Reads API keys that the build copies into Info.plist from the untracked
/// `Config/Secrets.xcconfig`.
///
/// This keeps keys out of git, which is the goal here. It does *not* hide
/// them from someone who unpacks the app: anything shipped in the binary can
/// be read. Truly protecting a key needs a server in between (a proxy that
/// holds the key), which is overkill for a free, read-only TMDB token.
nonisolated enum AppSecrets {
    static func tmdbReadAccessToken(in bundle: Bundle = .main) -> String? {
        guard let value = bundle.object(forInfoDictionaryKey: "TMDBReadAccessToken") as? String else { return nil }
        let token = value.trimmingCharacters(in: .whitespacesAndNewlines)
        // Empty when Secrets.xcconfig is missing; "$(…)" if the variable never expanded.
        guard !token.isEmpty, !token.hasPrefix("$(") else { return nil }
        return token
    }
}
