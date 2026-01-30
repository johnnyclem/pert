import Foundation
import ArgumentParser
import PertCore
import Cocoa // For pasteboard

@main
struct PertCLI: AsyncParsableCommand {
    @Argument(help: "The prompt to condition and execute")
    var prompt: String
    
    mutating func run() async throws {
        let service = LLMService()
        
        // print("Thinking...")
        
        var config: LLMConfig
        
        if let localConfig = await service.detectLocalService() {
            config = localConfig
            // print("Using local service at: \(config.baseURL)")
        } else {
            // Prompt for manual config if env vars not present (simplified for this task: just ask stdin)
            print("No local inference found (LMStudio/Ollama).")
            print("Enter OpenAI compatible Base URL:")
            guard let baseURL = readLine(), !baseURL.isEmpty else {
                print("Invalid URL.")
                return
            }
            
            print("Enter API Key:")
            guard let apiKey = readLine(), !apiKey.isEmpty else {
                 print("Invalid Key.")
                return
            }
            config = LLMConfig(baseURL: baseURL, apiKey: apiKey)
        }
        
        do {
            let models = try await service.fetchModels(config: config)
            let bestModel = service.selectBestModel(models: models)
            
            // print("Selected Model: \(bestModel)")
            
            let result = try await service.conditionPrompt(prompt, outputFormat: .plainText, config: config, model: bestModel)
            
            print("\n--- Result ---\n")
            print(result)
            
            // Copy to clipboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(result, forType: .string)
            print("\n(Result copied to clipboard)")
            
        } catch {
            print("Error: \(error)")
        }
    }
}
