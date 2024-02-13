//
//  TrimblePlaygroundTests.swift
//  TrimblePlaygroundTests
//
//  Created by Sasha Poirier on 01.02.2024.
//

import XCTest
@testable import TrimblePlayground

final class TrimblePlaygroundTests: XCTestCase {
    enum ReadingError: Error {
        case readingError(String)
    }
    
    private func loadWSData(name: String, ext: String = "json") throws -> PseudoExtras {
        print("Reading file: \(name)")
        let url = Bundle(for: TrimblePlaygroundTests.self).url(forResource: name, withExtension: ext)
        var string: String
        do {
            string = try String(contentsOf: url!)
        } catch {
            XCTFail("Error reading to string")
            throw ReadingError.readingError("Failed reading file")
        }
        
        do {
            return try PseudoExtras.parse(string: string)!
        } catch {
            XCTFail("Error reading file: \(name)")
            throw ReadingError.readingError("Failed parsing file")
        }
    }
    
    func testJsonParsing() {
        var parsed = try! loadWSData(name: "test_real")

        XCTAssert(parsed.totalSatInView == parsed.satelliteView.count) //THIS IS NOT GUARANTEED
        XCTAssert(parsed.subscriptionType == .Submeter)
        
    }
}
