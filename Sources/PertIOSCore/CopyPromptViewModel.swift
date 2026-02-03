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

    private var audioPlayer: AVAudioPlayer?

    public init() {
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

        UIPasteboard.general.string = conditionedPrompt
        playSound()

        toastMessage = "Copied to clipboard"
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

        UIPasteboard.general.string = conditionedPrompt
        playSound()

        toastMessage = "Prompt automatically copied to clipboard"
        showToast = true

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            showToast = false
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
