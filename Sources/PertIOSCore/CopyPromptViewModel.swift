#if canImport(UIKit)
import Foundation
import AVFoundation
import UIKit
import PertCore

@MainActor
public class CopyPromptViewModel: ObservableObject {
    @Published public var conditionedPrompt: String = ""
    @Published public var isConditioned: Bool = false
    @Published public var showToast: Bool = false
    @Published public var toastMessage: String = "Copied to clipboard"
    @Published public var isCopyButtonPressed: Bool = false
    @Published public var inputPrompt: String = ""
    @Published public var isConditioning: Bool = false
    @Published public var conditioningError: String?
    @Published public var selectedOutputFormat: OutputFormat = .plainText

    private var audioPlayer: AVAudioPlayer?
    private let clipboardService: ClipboardServiceProtocol
    private let llmService: LLMService

    public init(clipboardService: ClipboardServiceProtocol = ClipboardService(), llmService: LLMService = LLMService()) {
        self.clipboardService = clipboardService
        self.llmService = llmService
        loadSound()
    }

    private func loadSound() {
        guard let url = Bundle.module.url(forResource: "copy", withExtension: "mp3") else {
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch {
            // Sound loading failed; copy will still work without sound
        }
    }

    public func setConditionedPrompt(_ prompt: String) {
        conditionedPrompt = prompt
        isConditioned = true
    }

    public func copyToClipboard() {
        guard !conditionedPrompt.isEmpty else { return }

        let success = clipboardService.copyText(conditionedPrompt)
        if success {
            playSound()
            toastMessage = "Copied to clipboard"
        } else {
            toastMessage = "Failed to copy to clipboard"
        }
        showToast = true

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            showToast = false
        }
    }

    public func onConditioningComplete(prompt: String) {
        setConditionedPrompt(prompt)
        autoCopy()
    }

    private func autoCopy() {
        guard !conditionedPrompt.isEmpty else { return }

        let success = clipboardService.copyText(conditionedPrompt)
        if success {
            playSound()
            toastMessage = "Prompt automatically copied to clipboard"
        } else {
            toastMessage = "Failed to copy to clipboard"
        }
        showToast = true

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            showToast = false
        }
    }

    public func conditionPrompt() async {
        let prompt = inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        isConditioning = true
        conditioningError = nil

        do {
            guard let config = await llmService.detectLocalService() else {
                conditioningError = "No local LLM service found"
                isConditioning = false
                return
            }

            let models = try await llmService.fetchModels(config: config)
            let model = llmService.selectBestModel(models: models)
            let result = try await llmService.conditionPrompt(prompt, outputFormat: selectedOutputFormat, config: config, model: model)
            isConditioning = false
            onConditioningComplete(prompt: result)
        } catch {
            conditioningError = error.localizedDescription
            isConditioning = false
        }
    }

    public func animateCopyButton() {
        isCopyButtonPressed = true

        Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            isCopyButtonPressed = false
        }
    }

    private func playSound() {
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }
}
#endif
