import SwiftUI
import PertCore
import AVFoundation

@main
struct PertGUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    // UI State
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?

    // Progress state
    @State private var currentModel: String?
    @State private var currentStep: String = "Ready"
    @State private var progress: Double = 0.0

    // Focus state
    @FocusState private var isInputFocused: Bool
    @FocusState private var isOutputFocused: Bool

    // Config state
    @State private var showConfigSheet = false
    @State private var manualBaseURL = ""
    @State private var manualAPIKey = ""
    @State private var useManualConfig = false

    // Alert wrapper
    @State private var errorWrapper: ErrorWrapper?
    
    // Copy functionality
    @State private var showToast: Bool = false
    @State private var toastMessage: String = "Copied to clipboard"
    @State private var hasAutoCopied = false
    @State private var isCopyButtonPressed = false
    @State private var audioPlayer: AVAudioPlayer?

    // Computed properties for visual polish
    private let randomMessages = [
        "I'm just applying the final coat of 'I totally knew what I was doing the whole time' gloss.",
        "I am currently pressurizing this coal. The diamond is imminent.",
        "You can't rush art, but you can definitely threaten it with a deadline until it cooperates.",
        "I'm just sprinkling some glitter on the chaos to make it look like a strategy.",
        "It is currently in the 'Trust the Process' phase, which is code for 'I am fixing everything right now.'",
        "I'm not stalling; I'm adding texture to the brilliance.",
        "I am converting pure adrenaline into a deliverable product. Give me five minutes.",
        "Just tightening the lug nuts so the wheels don't fall off when I hand it to you.",
        "I'm putting the 'pro' in 'procrastinated perfection.'",
        "I am curating the vibes from 'dumpster fire' to 'masterpiece' as we speak."
    ]

    private var statusIcon: String {
        if errorWrapper != nil {
            return "exclamationmark.triangle"
        }
        switch currentStep {
        case "Detecting local services…":
            return "magnifyingglass"
        case "Fetching models…":
            return "cloud.fill"
        case "Selecting best model…":
            return "checkmark.circle"
        case "Processing prompt…":
            return "gear"
        default:
            return currentModel != nil ? "brain" : "circle"
        }
    }

    private var statusColor: Color {
        if errorWrapper != nil {
            return .red
        }
        if isProcessing {
            return .blue
        }
        if currentModel != nil {
            return .green
        }
        return .gray
    }

    private let warmBackgroundStart = Color(red: 0.98, green: 0.95, blue: 0.90)
    private let warmBackgroundEnd = Color(red: 0.99, green: 0.92, blue: 0.88)
    private let cardFill = Color(red: 1.0, green: 0.98, blue: 0.95).opacity(0.75)
    private let cardStroke = Color(red: 0.86, green: 0.78, blue: 0.70).opacity(0.35)
    private let warmTextPrimary = Color(red: 0.28, green: 0.22, blue: 0.18)
    private let warmTextSecondary = Color(red: 0.46, green: 0.38, blue: 0.30)
    private let warmAccent = Color(red: 0.89, green: 0.54, blue: 0.36)
    private let warmAccentSoft = Color(red: 0.93, green: 0.65, blue: 0.50)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [warmBackgroundStart, warmBackgroundEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pert")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(warmTextPrimary)
                            Text("Warm, focused prompt conditioning with a little delight.")
                                .font(.title3)
                                .foregroundColor(warmTextSecondary)
                        }

                        Spacer()

                        HStack(spacing: 12) {
                            Button(action: processPrompt) {
                                Label("Process", systemImage: "sparkles")
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(warmAccent)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(inputText.isEmpty || isProcessing)
                            .opacity(inputText.isEmpty || isProcessing ? 0.6 : 1)
                            .animation(.easeInOut(duration: 0.2), value: isProcessing)

                            Button(action: {
                                copyToClipboard()
                                animateCopyButton()
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .padding(10)
                                    .background(warmAccentSoft)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                    .scaleEffect(isCopyButtonPressed ? 0.9 : 1.0)
                            }
                            .buttonStyle(.plain)
                            .disabled(outputText.isEmpty)
                            .opacity(outputText.isEmpty ? 0.5 : 1)
                            .help("Copy conditioned output")

                            Button(action: { showConfigSheet = true }) {
                                Image(systemName: "gearshape.fill")
                                    .padding(10)
                                    .background(Color.white.opacity(0.7))
                                    .foregroundColor(warmTextPrimary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: statusIcon)
                        if let model = currentModel {
                            Text("Using \(model)")
                        } else {
                            Text(currentStep)
                        }
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.6))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())
                }

                HStack(spacing: 24) {
                    // Left Side: Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Prompt Input")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(warmTextPrimary)

                        Text("Drop in your raw idea and we’ll help shape it.")
                            .font(.callout)
                            .foregroundColor(warmTextSecondary)

                        TextEditor(text: $inputText)
                            .font(.body)
                            .foregroundColor(warmTextPrimary)
                            .frame(minWidth: 200, maxWidth: .infinity, minHeight: 280, maxHeight: .infinity)
                            .padding(8)
                            .background(Color(NSColor.windowBackgroundColor))
                            .cornerRadius(12)
                            .focused($isInputFocused)
                            .onAppear {
                                isInputFocused = true
                            }
                    }
                    .padding(20)
                    .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(cardFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(cardStroke, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
                    )

                    // Right Side: Output
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Conditioned Output")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(warmTextPrimary)

                        Text("Clean, structured prompts ready to use.")
                            .font(.callout)
                            .foregroundColor(warmTextSecondary)

                        ZStack {
                            TextEditor(text: $outputText)
                                .font(.body)
                                .foregroundColor(warmTextPrimary)
                                .frame(minWidth: 200, maxWidth: .infinity, minHeight: 280, maxHeight: .infinity)
                                .padding(8)
                                .background(Color(NSColor.windowBackgroundColor))
                                .cornerRadius(12)
                                .focused($isOutputFocused)

                            if isProcessing {
                                VStack(spacing: 12) {
                                    if progress < 1.0 {
                                        ProgressView(value: progress, total: 1.0)
                                            .progressViewStyle(.linear)
                                            .scaleEffect(x: 1, y: 2, anchor: .center)
                                    } else {
                                        ProgressView()
                                            .scaleEffect(1.5)
                                    }
                                    Text(currentStep)
                                        .font(.caption)
                                        .foregroundColor(warmTextSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .padding(20)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                    }
                    .padding(20)
                    .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(cardFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(cardStroke, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.easeInOut(duration: 0.25), value: showToast)
        .animation(.easeInOut(duration: 0.25), value: isProcessing)
        .sheet(isPresented: $showConfigSheet) {
            VStack(spacing: 20) {
                Text("Configuration")
                    .font(.headline)

                Text("If no local service (LMStudio :1234 / Ollama :11434) is detected, manual settings will be used.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                TextField("Base URL (e.g., https://api.openai.com/v1)", text: $manualBaseURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)

                SecureField("API Key", text: $manualAPIKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)

                HStack {
                    Button("Cancel") { showConfigSheet = false }
                    Button("Save") {
                        useManualConfig = !manualBaseURL.isEmpty && !manualAPIKey.isEmpty
                        showConfigSheet = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
            .frame(width: 400, height: 250)
        }
        .alert(item: $errorWrapper) { wrapper in
            Alert(title: Text("Error"), message: Text(wrapper.error), dismissButton: .default(Text("OK")))
        }
        .overlay(
            VStack {
                if showToast {
                    Text(toastMessage)
                        .font(.callout)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color(red: 0.95, green: 0.83, blue: 0.72))
                        .foregroundColor(warmTextPrimary)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
                        .padding(.bottom, 32)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                Spacer()
            },
            alignment: .bottom
        )
    }
    
    private func animateCopyButton() {
        withAnimation(.easeInOut(duration: 0.15)) {
            isCopyButtonPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.15)) {
                isCopyButtonPressed = false
            }
        }
    }
    
    private func copyToClipboard() {
        guard !outputText.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let success = pasteboard.setString(outputText, forType: .string)
        
        if success {
            // Play copy sound
            NSSound.beep()
            
            // Show toast
            if hasAutoCopied {
                toastMessage = "Re-copied to clipboard"
            } else {
                toastMessage = "Copied to clipboard"
            }
            showToast = true
            
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                showToast = false
            }
        } else {
            toastMessage = "Failed to copy to clipboard"
            showToast = true
            
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                showToast = false
            }
        }
    }

    struct ErrorWrapper: Identifiable {
        let id = UUID()
        let error: String
    }

    func processPrompt() {
        guard !inputText.isEmpty else { return }
        isProcessing = true
        outputText = ""

        Task {
            currentStep = "Detecting local services…"
            progress = 0.25
            let service = LLMService()
            var config: LLMConfig?

            // Logic: Check local first, then fallback to manual if set
            if let local = await service.detectLocalService() {
                config = local
            } else if useManualConfig {
                config = LLMConfig(baseURL: manualBaseURL, apiKey: manualAPIKey)
            }

            guard let validConfig = config else {
                // Trigger UI to ask for config
                await MainActor.run {
                    currentStep = "Ready"
                    progress = 0.0
                    isProcessing = false
                    showConfigSheet = true
                }
                return
            }

            do {
                currentStep = "Fetching models…"
                progress = 0.5
                let models = try await service.fetchModels(config: validConfig)

                currentStep = "Selecting best model…"
                progress = 0.75
                let bestModel = service.selectBestModel(models: models)

                currentStep = "Processing prompt…"
                progress = 1.0
                currentStep = randomMessages.randomElement()!
                let result = try await service.conditionPrompt(inputText, config: validConfig, model: bestModel)

                await MainActor.run {
                    outputText = result
                    currentModel = bestModel
                    currentStep = "Ready"
                    progress = 0.0
                    isProcessing = false
                    
                    // Auto-copy the conditioned prompt
                    if !hasAutoCopied {
                        copyToClipboard()
                        hasAutoCopied = true
                        toastMessage = "Prompt automatically copied to clipboard"
                        showToast = true
                        
                        Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            showToast = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorWrapper = ErrorWrapper(error: error.localizedDescription)
                    currentStep = "Ready"
                    progress = 0.0
                    isProcessing = false
                }
            }
        }
    }
}
