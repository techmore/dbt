//
//  TM_DBTUITests.swift
//  TM-DBTUITests
//
//  Created by techmore on 5/29/26.
//

import XCTest

final class TM_DBTUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Guards against the blank-screen bug: content must be on screen and usable on every platform.
    @MainActor
    func testMainScreensAreReachable() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["Review a hard moment"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Now"].isHittable)

        let morning = app.buttons["checkpoint-morning"]
        let before = morning.value as? String
        morning.tap()
        XCTAssertNotEqual(morning.value as? String, before)
        morning.tap()
        XCTAssertEqual(morning.value as? String, before)

        app.buttons["Diary"].tap()
        XCTAssertTrue(app.buttons["Save check-in"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Save check-in"].isHittable)

        app.buttons["Today"].tap()
        app.buttons["Review a hard moment"].tap()
        let prompting = app.textViews.firstMatch
        XCTAssertTrue(prompting.waitForExistence(timeout: 5))
        prompting.tap()
        prompting.typeText("UI test event")
        app.buttons["Save"].tap()
        app.buttons["Diary"].tap()
        XCTAssertTrue(app.staticTexts["UI test event"].waitForExistence(timeout: 5))

        app.buttons["Worksheets"].tap()
        XCTAssertTrue(app.staticTexts["Nightly endpoint"].waitForExistence(timeout: 5))

        app.buttons["Resources"].tap()
        XCTAssertTrue(app.staticTexts["In a crisis"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
