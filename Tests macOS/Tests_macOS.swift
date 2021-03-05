//
//  Tests_macOS.swift
//  Tests macOS
//
//  Created by Georg Meissner on 13.11.20.
//

import XCTest

class Tests_macOS: XCTestCase {
    var grocyVM: GrocyViewModel = .shared

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func test_relativeDate() {
//        let today = Calendar.startOfDay(Date())
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let oneWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        let oneYear = Calendar.current.date(byAdding: .year, value: 1, to: today)!
        XCTAssertEqual(getRelativeDateAsText(today, localizationKey: "en"), "Today")
        XCTAssertEqual(getRelativeDateAsText(tomorrow, localizationKey: "en"), "Tomorrow")
        XCTAssertEqual(getRelativeDateAsText(yesterday, localizationKey: "en"), "Yesterday")
        XCTAssertEqual(getRelativeDateAsText(oneWeek, localizationKey: "en"), "next week")
        XCTAssertEqual(getRelativeDateAsText(oneYear, localizationKey: "en"), "next year")
    }
    
    func test_MDLocations() {
        grocyVM.setDemoModus()
        grocyVM.getEntity(entity: .locations, completion: { (result: Result<MDLocations, Error>) in
            switch result {
            case let .success(entityResult):
                XCTAssertGreaterThan(entityResult.count, 0)
            case .failure:
                XCTFail()
            }
        })
    }

    func test_MDProducts() {
        grocyVM.setDemoModus()
        grocyVM.getEntity(entity: .products, completion: { (result: Result<MDProducts, Error>) in
            switch result {
            case let .success(entityResult):
                XCTAssertGreaterThan(entityResult.count, 0)
            case .failure:
                XCTFail()
            }
        })
    }
    
    func test_SystemInfo() {
        grocyVM.setDemoModus()
        grocyVM.getSystemInfo(completion: { (result: Result<SystemInfo, Error>) in
            switch result {
            case let .success(entityResult):
                XCTAssertNotNil(entityResult)
            case .failure:
                XCTFail()
            }
        })
    }
}
