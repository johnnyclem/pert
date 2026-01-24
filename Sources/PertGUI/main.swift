import SwiftUI
import PertCore

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

    var body: some View {
        HSplitView {
            // Left Side: Input
            VStack(alignment: .leading) {
                Text("Prompt Input")
                    .font(.headline)
                    .padding(.bottom, 4)

                TextEditor(text: $inputText)
                    .font(.body)
                    .frame(minWidth: 200, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
                    .padding(4)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .focused($isInputFocused)
                    .onAppear {
                        isInputFocused = true
                    }
            }
            .padding()
            .frame(minWidth: 300, maxWidth: .infinity)

            // Right Side: Output
            VStack(alignment: .leading) {
                Text("Conditioned Output")
                    .font(.headline)
                    .padding(.bottom, 4)

                ZStack {
                    TextEditor(text: $outputText)
                        .font(.body)
                        .frame(minWidth: 200, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
                        .padding(4)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .focused($isOutputFocused)

                    if isProcessing {
                        VStack {
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
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .frame(minWidth: 300, maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: processPrompt) {
                    Label("Process", systemImage: "play.fill")
                }
                .disabled(inputText.isEmpty || isProcessing)
            }

            ToolbarItem(placement: .automatic) {
                Button(action: { showConfigSheet = true }) {
                    Label("Settings", systemImage: "gear")
                }
            }

            ToolbarItem(placement: .automatic) {
                HStack {
                    Image(systemName: statusIcon)
                    if let model = currentModel {
                        Text("Using \(model)")
                            .font(.subheadline)
                    } else {
                        Text(currentStep)
                            .font(.subheadline)
                    }
                }
                .foregroundColor(statusColor)
            }
        }
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