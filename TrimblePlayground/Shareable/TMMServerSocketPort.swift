//
//  TMMServerSocketPort.swift
//  TrimblePlayground
//
//  Created by Sasha Poirier on 14.02.2024.
//

import Foundation

struct TMMServerSocketPortRequest: Encodable {
    public let returl: String// = "socketport://spp4d.playground.ios"
    
    ///Converts to a JSON object and encodes into a base64 string
    public func encode64() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        let encoded = try encoder.encode(self)
        print(String(data: encoded, encoding: .utf8)!)
        return encoded.base64EncodedString()
    }
    
    /// Builds the Trimble Mobile Manager WebSocket port request string
    public func makeTMMRequestURL() -> URL? {
        do {
            let encoded : String = try encode64()
            return URL(string: "tmmsocketserverport://trimble.TMM.ios?" + encoded)
        } catch {
            print("Threw while encoding")
            return nil
        }
    }
}

struct TMMServerSocketPortResponse: Decodable {
    public let port: Int
    
    ///Decodes the TMM URL scheme response
    public static func decode(response: URL) -> TMMServerSocketPortResponse? {
        guard let query = response.query else {
            return nil
        }
        guard let data = Data(base64Encoded: query) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(TMMServerSocketPortResponse.self, from: data)
        } catch {
            return nil
        }
    }
}

