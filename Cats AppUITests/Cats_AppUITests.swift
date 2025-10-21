//
//  Cats_AppUITests.swift
//  Cats AppUITests
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import XCTest

final class Cats_AppUITests: XCTestCase {

    @MainActor
    func testEnteringOfflineMode() throws {
        let app = XCUIApplication()
        
        // Simulate no internet connection
        app.launchArguments.append("--simulateOffline")
        app.launch()

        let noConnectionBanner = app.buttons["noConnectionBanner"]
        XCTAssertTrue(noConnectionBanner.waitForExistence(timeout: 1), "No connection banner should appear")
        
        noConnectionBanner.tap()
        
        let offlineModeBanner = app.buttons["offlineModeBanner"]
        XCTAssertTrue(offlineModeBanner.waitForExistence(timeout: 0.5), "Offline mode banner should appear")
    }
}
