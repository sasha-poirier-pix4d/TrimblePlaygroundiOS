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
        let parsed = try! loadWSData(name: "test_real")

        XCTAssert(parsed.totalSatInView == parsed.satelliteView.count) //THIS IS NOT GUARANTEED
        XCTAssert(parsed.subscriptionType == .Submeter)
        
    }
    
    func testPortRequest() {
        let request = TMMServerSocketPortRequest(returl: "socketport://spp4d.playground.ios")
        let expected = "tmmsocketserverport://trimble.TMM.ios?eyJyZXR1cmwiOiJzb2NrZXRwb3J0Oi8vc3BwNGQucGxheWdyb3VuZC5pb3MifQ=="
        //Multi-line  : ewogICJyZXR1cmwiOiAic29ja2V0cG9ydDovL3NwcDRkLnBsYXlncm91bmQuaW9zIgp9
        //Single line : eyJyZXR1cmwiOiJzb2NrZXRwb3J0Oi8vc3BwNGQucGxheWdyb3VuZC5pb3MifQ==
        guard let made = request.makeTMMRequestURL() else {
            XCTFail("Should be able to parse")
            return
        }
        
        XCTAssert(made.absoluteString == expected, "Found \(made.absoluteString) but expected \(expected)")
    }
    
    func testPortResponse() {
        /**
         ewogICJwb3J0IjogOTYzNQp9
         is the base64 representation of the following JSON:
         {
           "port": 9635
         }
         */
        guard let request = URL(string:"socketport://ting.playground.ios?ewogICJwb3J0IjogOTYzNQp9") else {
            XCTFail("Should be able to parse this URL")
            return
        }
        
        guard let parsed = TMMServerSocketPortResponse.decode(response: request) else {
            XCTFail("Should not be null")
            return
        }
        
        XCTAssert(parsed.port == 9635, "Port was \(parsed.port) when it should have been 9635")
    }
}
