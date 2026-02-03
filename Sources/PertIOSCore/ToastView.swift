#if canImport(UIKit)
import SwiftUI

public struct ToastView: View {
    let message: String

    private let warmTextPrimary = Color(red: 0.28, green: 0.22, blue: 0.18)
    private let toastBackground = Color(red: 0.95, green: 0.83, blue: 0.72)

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        Text(message)
            .font(.callout)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(toastBackground)
            .foregroundColor(warmTextPrimary)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
    }
}
#endif
