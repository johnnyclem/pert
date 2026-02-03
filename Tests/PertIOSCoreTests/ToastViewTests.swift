#if canImport(UIKit)
import XCTest
import SwiftUI
@testable import PertIOSCore

final class ToastViewTests: XCTestCase {
    func testToastViewInitialization() {
        let toast = ToastView(message: "Test message")
        XCTAssertNotNil(toast)
    }

    func testToastViewWithEmptyMessage() {
        let toast = ToastView(message: "")
        XCTAssertNotNil(toast)
    }
}
#else
import XCTest

final class ToastViewStubTests: XCTestCase {
    func testPlatformNotSupported() {
        // ToastView requires UIKit (iOS). These tests run on iOS simulator only.
    }
}
#endif
