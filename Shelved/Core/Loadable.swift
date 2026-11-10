import Foundation

/// The state of anything loaded asynchronously.
///
/// One enum instead of separate `isLoading` / `error` / `items` properties
/// makes impossible combinations (loading *and* failed) unrepresentable,
/// and a `switch` in the view forces every state to be handled.
nonisolated enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(any Error)

    var value: Value? {
        if case .loaded(let value) = self { value } else { nil }
    }
}
