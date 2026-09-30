//
//  LoanCalculatorUITests.swift
//  LoanCalculatorUITests
//
//  Created by mac on 2026/3/14.
//

import XCTest

final class LoanCalculatorUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testBeijingShowsYearsAndPlannedPrincipalInsteadOfBalance() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["本人缴存月数"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["拟用公积金本金"].exists)
        XCTAssertTrue(app.staticTexts["该贷款类型最低首付 20%"].exists)
        XCTAssertFalse(app.staticTexts["账户余额"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
