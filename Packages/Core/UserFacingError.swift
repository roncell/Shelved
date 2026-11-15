import Foundation

/// An error that knows how to describe itself to a user.
///
/// Lets `Error.userMessage` (in Core) word errors defined in other modules
/// without importing them: `LibraryError` (Data) and `NetworkError`
/// (Networking) conform where they're declared. Before modularizing, Core
/// listed every error type by name, which made the lowest layer depend on
/// the ones above it.
public nonisolated protocol UserFacingError: Error {
    /// A short sentence that's safe to show. nil to fall back to the generic text.
    var userFacingMessage: String? { get }
}
