//
//  iMessageExtensionUITests.swift
//  iMessageExtensionUITests
//
//  Created by Developer on 1/4/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import XCTest

class iMessageExtensionUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        
    XCUIApplication().scrollViews.children(matching: .other).element.children(matching: .other).element(boundBy: 0).buttons["play"].tap()
        
        let windows = XCUIApplication().windows
        XCTAssert(windows.staticTexts["Frost"].exists)
        XCTAssert(windows.staticTexts["Blaze"].exists)
        XCTAssert(windows.staticTexts["Timber"].exists)
        
        let app = XCUIApplication()
        let previewCount = app.scrollViews.children(matching: .other).element.children(matching: .other).matching(identifier: "coursePreview").count
        
        XCTAssertEqual(previewCount, 3)
    }
    
}
