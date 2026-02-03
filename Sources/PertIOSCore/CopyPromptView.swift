#if canImport(UIKit)
import SwiftUI

public struct CopyPromptView: View {
    @StateObject private var viewModel = CopyPromptViewModel()

    private let warmBackgroundStart = Color(red: 0.98, green: 0.95, blue: 0.90)
    private let warmBackgroundEnd = Color(red: 0.99, green: 0.92, blue: 0.88)
    private let warmTextPrimary = Color(red: 0.28, green: 0.22, blue: 0.18)
    private let warmTextSecondary = Color(red: 0.46, green: 0.38, blue: 0.30)
    private let warmAccentSoft = Color(red: 0.93, green: 0.65, blue: 0.50)
    private let cardStroke = Color(red: 0.86, green: 0.78, blue: 0.70).opacity(0.35)

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [warmBackgroundStart, warmBackgroundEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Prompt display
                if !viewModel.conditionedPrompt.isEmpty {
                    Text(viewModel.conditionedPrompt)
                        .font(.body)
                        .foregroundColor(warmTextPrimary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(cardStroke, lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }

                // Copy button
                Button(action: {
                    viewModel.copyToClipboard()
                    viewModel.animateCopyButton()
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.title2)
                        .padding(16)
                        .background(warmAccentSoft)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .scaleEffect(viewModel.isCopyButtonPressed ? 0.9 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: viewModel.isCopyButtonPressed)
                }
                .disabled(viewModel.conditionedPrompt.isEmpty)
                .opacity(viewModel.conditionedPrompt.isEmpty ? 0.5 : 1)

                Spacer()
            }

            // Toast overlay
            if viewModel.showToast {
                ToastView(message: viewModel.toastMessage)
                    .padding(.bottom, 40)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.showToast)
    }
}
#endif
