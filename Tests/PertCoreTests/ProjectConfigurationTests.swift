import XCTest
import Foundation

/// Tests that verify project configuration for Swift/SwiftUI and Kotlin/Jetpack Compose builds.
final class ProjectConfigurationTests: XCTestCase {

    // MARK: - Swift Package Configuration

    func testPackageSwiftExists() {
        let packagePath = projectRoot().appendingPathComponent("Package.swift")
        XCTAssertTrue(FileManager.default.fileExists(atPath: packagePath.path), "Package.swift must exist at project root")
    }

    func testPackageSwiftContainsSwiftUITargets() throws {
        let content = try readProjectFile("Package.swift")
        XCTAssertTrue(content.contains("PertIOSCore"), "Package.swift must declare PertIOSCore target")
        XCTAssertTrue(content.contains("PertCore"), "Package.swift must declare PertCore target")
        XCTAssertTrue(content.contains(".iOS(.v17)"), "Package.swift must target iOS 17+")
        XCTAssertTrue(content.contains(".macOS(.v14)"), "Package.swift must target macOS 14+")
    }

    func testPackageSwiftContainsTestTargets() throws {
        let content = try readProjectFile("Package.swift")
        XCTAssertTrue(content.contains("PertCoreTests"), "Package.swift must declare PertCoreTests target")
        XCTAssertTrue(content.contains("PertIOSCoreTests"), "Package.swift must declare PertIOSCoreTests target")
    }

    func testPackageSwiftContainsResourceBundle() throws {
        let content = try readProjectFile("Package.swift")
        XCTAssertTrue(content.contains(".process(\"Resources\")"), "PertIOSCore must process Resources bundle")
    }

    // MARK: - iOS Source Structure

    func testIOSCoreSourceFilesExist() {
        let files = [
            "Sources/PertIOSCore/CopyPromptViewModel.swift",
            "Sources/PertIOSCore/CopyPromptView.swift",
            "Sources/PertIOSCore/ToastView.swift",
        ]
        for file in files {
            let path = projectRoot().appendingPathComponent(file)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path.path), "\(file) must exist")
        }
    }

    func testIOSCoreResourcesExist() {
        let path = projectRoot().appendingPathComponent("Sources/PertIOSCore/Resources/copy.mp3")
        XCTAssertTrue(FileManager.default.fileExists(atPath: path.path), "copy.mp3 sound asset must exist in iOS resources")
    }

    func testIOSCoreUsesSwiftUI() throws {
        let viewContent = try readProjectFile("Sources/PertIOSCore/CopyPromptView.swift")
        XCTAssertTrue(viewContent.contains("import SwiftUI"), "CopyPromptView must import SwiftUI")
        XCTAssertTrue(viewContent.contains("View"), "CopyPromptView must conform to View protocol")
    }

    func testIOSCoreTestFilesExist() {
        let files = [
            "Tests/PertIOSCoreTests/CopyPromptViewModelTests.swift",
            "Tests/PertIOSCoreTests/ToastViewTests.swift",
        ]
        for file in files {
            let path = projectRoot().appendingPathComponent(file)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path.path), "\(file) must exist")
        }
    }

    // MARK: - Android/Kotlin Configuration

    func testAndroidBuildGradleExists() {
        let path = projectRoot().appendingPathComponent("android/app/build.gradle.kts")
        XCTAssertTrue(FileManager.default.fileExists(atPath: path.path), "Android app build.gradle.kts must exist")
    }

    func testAndroidBuildGradleConfiguresCompose() throws {
        let content = try readProjectFile("android/app/build.gradle.kts")
        XCTAssertTrue(content.contains("compose = true"), "Android build must enable Compose")
        XCTAssertTrue(content.contains("kotlinCompilerExtensionVersion"), "Android build must set Compose compiler version")
        XCTAssertTrue(content.contains("material3"), "Android build must include Material3 dependency")
        XCTAssertTrue(content.contains("compose-bom"), "Android build must use Compose BOM")
    }

    func testAndroidBuildGradleConfiguresKotlin() throws {
        let content = try readProjectFile("android/app/build.gradle.kts")
        XCTAssertTrue(content.contains("org.jetbrains.kotlin.android"), "Android build must apply Kotlin Android plugin")
    }

    func testAndroidSourceFilesExist() {
        let files = [
            "android/app/src/main/java/com/pert/copyprompt/MainActivity.kt",
            "android/app/src/main/java/com/pert/copyprompt/viewmodel/CopyPromptViewModel.kt",
            "android/app/src/main/java/com/pert/copyprompt/ui/CopyPromptScreen.kt",
            "android/app/src/main/java/com/pert/copyprompt/ui/ToastOverlay.kt",
        ]
        for file in files {
            let path = projectRoot().appendingPathComponent(file)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path.path), "\(file) must exist")
        }
    }

    func testAndroidTestFilesExist() {
        let files = [
            "android/app/src/test/java/com/pert/copyprompt/viewmodel/CopyPromptViewModelTest.kt",
            "android/app/src/androidTest/java/com/pert/copyprompt/ui/CopyPromptScreenTest.kt",
        ]
        for file in files {
            let path = projectRoot().appendingPathComponent(file)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path.path), "\(file) must exist")
        }
    }

    func testAndroidResourcesExist() {
        let files = [
            "android/app/src/main/res/raw/copy.mp3",
            "android/app/src/main/res/values/strings.xml",
            "android/app/src/main/res/values/themes.xml",
            "android/app/src/main/AndroidManifest.xml",
        ]
        for file in files {
            let path = projectRoot().appendingPathComponent(file)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path.path), "\(file) must exist")
        }
    }

    func testAndroidLauncherIconExists() {
        let path = projectRoot().appendingPathComponent("android/app/src/main/res/mipmap-hdpi/ic_launcher.png")
        XCTAssertTrue(FileManager.default.fileExists(atPath: path.path), "Android launcher icon must exist")
    }

    func testAndroidManifestConfigured() throws {
        let content = try readProjectFile("android/app/src/main/AndroidManifest.xml")
        XCTAssertTrue(content.contains("MainActivity"), "AndroidManifest must declare MainActivity")
        XCTAssertTrue(content.contains("android.intent.action.MAIN"), "AndroidManifest must declare MAIN intent")
        XCTAssertTrue(content.contains("android.intent.category.LAUNCHER"), "AndroidManifest must declare LAUNCHER category")
    }

    func testAndroidUsesJetpackCompose() throws {
        let screenContent = try readProjectFile("android/app/src/main/java/com/pert/copyprompt/ui/CopyPromptScreen.kt")
        XCTAssertTrue(screenContent.contains("@Composable"), "CopyPromptScreen must use @Composable annotation")
        XCTAssertTrue(screenContent.contains("androidx.compose"), "CopyPromptScreen must import Jetpack Compose")
    }

    func testAndroidGradleWrapperExists() {
        let path = projectRoot().appendingPathComponent("android/gradle/wrapper/gradle-wrapper.properties")
        XCTAssertTrue(FileManager.default.fileExists(atPath: path.path), "Gradle wrapper properties must exist")
    }

    func testAndroidSettingsGradleExists() {
        let path = projectRoot().appendingPathComponent("android/settings.gradle.kts")
        XCTAssertTrue(FileManager.default.fileExists(atPath: path.path), "settings.gradle.kts must exist")
    }

    // MARK: - Cross-Platform Parity

    func testBothPlatformsHaveSoundAsset() {
        let iosPath = projectRoot().appendingPathComponent("Sources/PertIOSCore/Resources/copy.mp3")
        let androidPath = projectRoot().appendingPathComponent("android/app/src/main/res/raw/copy.mp3")
        XCTAssertTrue(FileManager.default.fileExists(atPath: iosPath.path), "iOS must have copy.mp3")
        XCTAssertTrue(FileManager.default.fileExists(atPath: androidPath.path), "Android must have copy.mp3")
    }

    func testBothPlatformsHaveViewModelAndUI() {
        // iOS
        XCTAssertTrue(fileExists("Sources/PertIOSCore/CopyPromptViewModel.swift"))
        XCTAssertTrue(fileExists("Sources/PertIOSCore/CopyPromptView.swift"))
        // Android
        XCTAssertTrue(fileExists("android/app/src/main/java/com/pert/copyprompt/viewmodel/CopyPromptViewModel.kt"))
        XCTAssertTrue(fileExists("android/app/src/main/java/com/pert/copyprompt/ui/CopyPromptScreen.kt"))
    }

    // MARK: - Helpers

    private func projectRoot() -> URL {
        // Navigate from the test bundle to the project root
        // When running via `swift test`, the working directory is the package root
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    private func readProjectFile(_ relativePath: String) throws -> String {
        let path = projectRoot().appendingPathComponent(relativePath)
        return try String(contentsOf: path, encoding: .utf8)
    }

    private func fileExists(_ relativePath: String) -> Bool {
        let path = projectRoot().appendingPathComponent(relativePath)
        return FileManager.default.fileExists(atPath: path.path)
    }
}
