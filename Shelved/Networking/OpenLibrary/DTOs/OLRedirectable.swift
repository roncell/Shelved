import Foundation

/// An Open Library record that may be a redirect.
///
/// When Open Library merges duplicates, the old record stays at its URL as
///   { "type": { "key": "/type/redirect" }, "location": "/works/OL893414W" }
/// with no title or authors. The JSON API doesn't follow these for us, and
/// IDs saved earlier (a route, a deep link, later a library entry) can point
/// at one, so the catalog follows `redirectKey` instead.
nonisolated protocol OLRedirectable {
    var type: OLKeyRef? { get }
    var location: String? { get }
}

extension OLRedirectable {
    /// The key to fetch instead, e.g. "/works/OL893414W", or nil if this is the real record.
    nonisolated var redirectKey: String? {
        type?.key == "/type/redirect" ? location : nil
    }
}
