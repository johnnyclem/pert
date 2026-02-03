#if canImport(UIKit)
import UIKit

/// Protocol abstracting clipboard operations for testability.
public protocol ClipboardServiceProtocol {
    func copyText(_ text: String) -> Bool
    func getText() -> String?
}

/// Default implementation using UIPasteboard.
public final class ClipboardService: ClipboardServiceProtocol {
    public init() {}

    public func copyText(_ text: String) -> Bool {
        UIPasteboard.general.string = text
        return UIPasteboard.general.string == text
    }

    public func getText() -> String? {
        return UIPasteboard.general.string
    }
}
#endif
