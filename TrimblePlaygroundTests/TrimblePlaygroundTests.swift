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
    
    private func loadWSMessageFile(name: String, ext: String = "json") throws -> PseudoExtras {
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
        let parsed = try! loadWSMessageFile(name: "test_real")

        XCTAssert(parsed.totalSatInView == parsed.satelliteView.count) //THIS IS NOT GUARANTEED FOR REAL MESSAGES
        XCTAssert(parsed.subscriptionType == .Submeter)
        XCTAssert(parsed.satellites == parsed.satelliteView.filter {sat in return sat.use}.count)   //This should be guaranteed
        
        //String parsing
        XCTAssert(parsed.mockProvider == "TMM")
        XCTAssert(parsed.receiverModel == "Some Model")
        XCTAssert(parsed.geoidModel == "Yuck")
        
        //Time
        let dateFormatter = DateFormatter()
        //dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"
        XCTAssertNotNil(parsed.gpsTimeStamp)
        XCTAssertNotNil(parsed.utcTimeStamp)
        let gpsTime = dateFormatter.date(from:parsed.gpsTimeStamp)!
        let utcTime = dateFormatter.date(from:parsed.utcTimeStamp)!
        
        let calendar = Calendar.current
        let gpsComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: gpsTime)
        let utcComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: utcTime)
        XCTAssert(gpsComponents.year == 2024)
        XCTAssert(utcComponents.year == 2024)
        XCTAssert(gpsComponents.month == 2)
        XCTAssert(utcComponents.month == 2)
        XCTAssert(gpsComponents.day == 12)
        XCTAssert(utcComponents.day == 12)
        XCTAssert(gpsComponents.hour == 19)
        XCTAssert(utcComponents.hour == 19)
        XCTAssert(gpsComponents.minute == 19)
        XCTAssert(utcComponents.minute == 19)
        XCTAssert(gpsComponents.second == 42)
        XCTAssert(utcComponents.second == 24)
        
        //Diff
        XCTAssert(parsed.diffAge == 0.1)
        XCTAssert(parsed.diffStatus == .DGPS)
        
        //Float parsing
        XCTAssert(parsed.vdop == 0.2)
        XCTAssert(parsed.hdop == 0.2)
        XCTAssert(parsed.vdop == 0.2)
        XCTAssert(parsed.vrms == 0.2)
        XCTAssert(parsed.hrms == 0.2)
        
        XCTAssert(parsed.bearing == 175.0)
        
        //Make sure optionals aren't nil
        XCTAssert(parsed.battery == 50)
        XCTAssert(parsed.mslHeight == 520.0)
        XCTAssert(parsed.undulation == 32.0)
    }
    
    func testPartialJsonParsing() {
        let parsed = try! loadWSMessageFile(name: "test_partial")

        XCTAssert(parsed.totalSatInView == parsed.satelliteView.count) //THIS IS NOT GUARANTEED FOR REAL MESSAGES
        XCTAssert(parsed.subscriptionType == .Decimeter)
        XCTAssert(parsed.satellites == parsed.satelliteView.filter {sat in return sat.use}.count)   //This should be guaranteed
        
        //Make sure optionals are null
        XCTAssertNil(parsed.battery)
        XCTAssertNil(parsed.mslHeight)
        XCTAssertNil(parsed.undulation)
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
    
    private func testPortResponse(url: String, expected: Int) {
        guard let request = URL(string: url) else {
            XCTFail("Should be able to parse this URL")
            return
        }
        
        guard let parsed = TMMServerSocketPortResponse.decode(response: request) else {
            XCTFail("Should not be null")
            return
        }
        
        XCTAssert(parsed.port == expected, "Port was \(parsed.port) when it should have been \(expected)")
    }
    
    func testPortResponse() {
        /**
         {
           "port": 9635
         }
         base64: ewogICJwb3J0IjogOTYzNQp9
         */
        testPortResponse(url: "socketport://ting.playground.ios?ewogICJwb3J0IjogOTYzNQp9", expected: 9635)
        
        /**
         { "port": 41296 }
         base64: eyAicG9ydCI6IDQxMjk2IH0=
         */
        testPortResponse(url: "socketport://ting.playground.ios?eyAicG9ydCI6IDQxMjk2IH0=", expected: 41296)
    }
}
