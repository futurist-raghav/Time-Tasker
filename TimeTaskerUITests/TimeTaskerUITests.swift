//
//  TimeTaskerUITests.swift
//  TimeTaskerUITests
//
//  Created by Raghav Agarwal on 04/12/25.
//

import XCTest

final class TimeTaskerUITests: XCTestCase {

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-reset")
        return app
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMainScreenShowsCoreSections() throws {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.otherElements["main.content"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["header.appTitle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["tasks.section"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tasks.newTaskButton"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testNewTaskOpensCreationSheet() throws {
        let app = makeApp()
        app.launch()

        let newTaskButton = app.buttons["tasks.newTaskButton"]
        XCTAssertTrue(newTaskButton.waitForExistence(timeout: 5))

        newTaskButton.tap()

        XCTAssertTrue(app.otherElements["taskCreation.form"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["taskCreation.titleField"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            makeApp().launch()
        }
    }
}
