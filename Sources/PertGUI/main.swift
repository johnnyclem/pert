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
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    // Config state
    @State private var showConfigSheet = false
    @State private var manualBaseURL = ""
    @State private var manualAPIKey = ""
    @State private var useManualConfig = false
    
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
                    
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(1.5)
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
    
    @State private var errorWrapper: ErrorWrapper?
    
    struct ErrorWrapper: Identifiable {
        let id = UUID()
        let error: String
    }
    
    func processPrompt() {
        guard !inputText.isEmpty else { return }
        isProcessing = true
        outputText = ""
        
        Task {
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
                    isProcessing = false
                    showConfigSheet = true
                }
                return
            }
            
            do {
                let models = try await service.fetchModels(config: validConfig)
                let bestModel = service.selectBestModel(models: models)
                let result = try await service.conditionPrompt(inputText, config: validConfig, model: bestModel)
                
                await MainActor.run {
                    outputText = result
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorWrapper = ErrorWrapper(error: error.localizedDescription)
                    isProcessing = false
                }
            }
        }
    }
}
