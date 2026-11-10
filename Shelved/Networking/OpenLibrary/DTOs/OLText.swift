import Foundation

/// Open Library returns text fields in two shapes:
///   "description": "A desert planet…"
///   "description": { "type": "/type/text", "value": "A desert planet…" }
///
/// A custom `init(from:)` accepts both, so the rest of the code just sees `.value`.
nonisolated struct OLText: Decodable, Sendable {
    let value: String

    private nonisolated enum CodingKeys: String, CodingKey {
        case value
    }

    init(from decoder: any Decoder) throws {
        // Try the plain string shape first…
        if let container = try? decoder.singleValueContainer(),
           let string = try? container.decode(String.self) {
            value = string
            return
        }
        // …then fall back to the object shape. If this throws too, the JSON
        // really is malformed and decoding should fail.
        let object = try decoder.container(keyedBy: CodingKeys.self)
        value = try object.decode(String.self, forKey: .value)
    }
}
