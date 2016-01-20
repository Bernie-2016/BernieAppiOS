//
//  ZipCodeValidatorTest.swift
//  Movement
//
//  Created by Susan Crayne on 1/20/16.
//  Copyright © 2016 Coders For Sanders. All rights reserved.
//

import XCTest
@testable import Movement


class ZipCodeValidatorTest: XCTestCase {
    

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testThatNumericZipCodeReturnsTrue(){
        let testValidator = ZipCodeValidator();
        XCTAssertTrue(testValidator.validate("12345"))
    }
    
    
}
