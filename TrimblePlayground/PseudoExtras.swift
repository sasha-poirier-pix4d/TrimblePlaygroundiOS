//
//  PseudoExtras.swift
//  TrimblePlayground
//
//  Created by Sasha Poirier on 01.02.2024.
//

import Foundation

struct PseudoExtras: Decodable, Identifiable, Equatable {
    static func == (lhs: PseudoExtras, rhs: PseudoExtras) -> Bool {
        return lhs.id == rhs.id
    }
    
    public let id = UUID()
    //public let id: UUID
    
    public enum CodingKeys : String, CodingKey {
        case id, latitude, longitude, altitude,
            speed, bearing,
            accuracy, verticalAccuracy = "verticalAccuracyMeters",
            hdop, vdop, pdop,
             diffAge, diffStatus,
            vrms, hrms,
            receiverModel, mockProvider, battery,
            mslHeight, undulation, geoidModel,
            utcTime, gpsTimeStamp, utcTimeStamp,
            subscriptionType, satellites, totalSatInView,
            satelliteView
    }

    public let latitude: Double
    public let longitude: Double
    public let altitude: Double
    
    public let speed: Float
    public let bearing: Float
    public let accuracy: Float //TODO if horizontal rename to horizontalAccuracy
    public let verticalAccuracy: Float
    
    public let hdop: Float
    public let vdop: Float
    public let pdop: Float
    
    public let diffAge: Float   //Message age of any RTK message in seconds
    public enum DiffStatus: Int, Decodable {
        case Autonomous, DGPS, Fixed, Float, Unknown
        init (from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let type = try? container.decode(Int.self)
            switch type {
                case 1: self = .Autonomous
                case 2: self = .DGPS
                case 4: self = .Fixed
                case 5: self = .Float
                default:  self = .Unknown
            }
        }
    }
    public let diffStatus: DiffStatus
    
    //Currently ignoring as when -1 is actually a String!!!
    //Have never seen 4-digit ID, so don't want to risk it
    //public let diffID: Int
    
    public let vrms: Float
    public let hrms: Float
    
    public let receiverModel: String
    public let mockProvider: String
    public let battery: Int?    ////Not available for Catalyst DA2
    
    public let mslHeight: Double?   ///Is marked as nullable in some parts of documentation
    public let undulation: Double?  ///Is marked as nullable in some parts of documentation
    public let geoidModel: String?  ///Not in all parts of the documentation
    
    public let utcTime: Float   ///Seems to be device uptime or something
    public let gpsTimeStamp: String
    public let utcTimeStamp: String
    
    public enum SubscriptionType: Decodable {
        case Free, Meter, Submeter, Decimeter, Precision, PrecisionOnDemand, GNSS, Unknown
        
        init (from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let type = try? container.decode(Int.self)
            switch type {
                case 0: self = .Free
                case 1: self = .Meter
                case 2: self = .Submeter
                case 3: self = .Decimeter
                case 4: self = .Precision
                case 5: self = .PrecisionOnDemand
                case 100: self = .GNSS
                default:  self = .Unknown
            }
        }
    }
    public let subscriptionType: SubscriptionType
    
    // MARK: Satellites
    public let satellites: Int
    public let totalSatInView: Int
    
    public struct Satellite : Codable {
        public let id: Int
        public let elv: Int
        public let azm: Int
        public let snr: Int
        public let use: Bool
        public let type: SatelliteType
        
        public enum CodingKeys : String, CodingKey {
            case id = "Id", elv = "Elv", azm = "Azm", snr = "Snr", use = "Use", type = "Type"
        }
    }
    
    public enum SatelliteType: Int, Codable {
        case GPS, SBAS, GLONASS, OMNISTAR, GALILEO, BEIDOU, QZSS, IRNSS
    }
    
    public let satelliteView: [Satellite]
    
    //This is how the documentation says satellite info is structured
    // it is not
    /*public let satellitesView: Int
    public let satellitesId: [Int]
    public let satellitesElv: [Int]
    public let satellitesAzm: [Int]
    public let satellitesSnr: [Int]
    public let satellitesUse: [Bool]
    public let satellitesType: [SatelliteType]*/
    //Struct used for merging satellite info
    //Current lazy var impl is't great, but works for now...
    /*public lazy var satellitesMerged : [Satellite] = {
        var tmp = [Satellite]()
        for index in 0...self.satellitesView - 1 {
            let id = self.satellitesId[index]
            let elv = self.satellitesElv[index]
            let azm = self.satellitesAzm[index]
            let snr = self.satellitesSnr[index]
            let use = self.satellitesUse[index]
            let type = self.satellitesType[index]
            tmp.append(Satellite(id: id, elv: elv, azm: azm, snr: snr, use: use, type: type))
        }
        return tmp
    }()*/
    
    static func parse(string: String) throws -> PseudoExtras? {
        let json = string.data(using: .utf8)!
        do {
            return try JSONDecoder().decode(PseudoExtras.self, from: json)
        } catch {
            print("Failed parsing string : \(string)")
        }
        
        return nil
    }
    
    static var zero: PseudoExtras {
        return PseudoExtras(latitude: 0, longitude: 0, altitude: 0, speed: 0, bearing: 0, accuracy: 0, verticalAccuracy: 0, hdop: 0, vdop: 0, pdop: 0, diffAge: 0, diffStatus: DiffStatus.Unknown, vrms: 0, hrms: 0, receiverModel: "", mockProvider: "", battery: nil, mslHeight: 0, undulation: 0, geoidModel: "", utcTime: 0, gpsTimeStamp: "", utcTimeStamp: "", subscriptionType: SubscriptionType.Free, satellites: 0, totalSatInView: 0, satelliteView: [])
    }
    
    static var malley: PseudoExtras {
        //Variance
        let lat = 46.52955048375884 - Double.random(in: -0.001...0.001)
        let lon = 6.600880505618732 - Double.random(in: -0.001...0.001)
        let millis = Float(Date().timeIntervalSince1970 * 1000)
        
        return PseudoExtras(latitude: lat, longitude: lon, altitude: 400, speed: 0, bearing: 0, accuracy: 0, verticalAccuracy: 0, hdop: 0, vdop: 0, pdop: 0, diffAge: 0, diffStatus: DiffStatus.Unknown, vrms: 0, hrms: 0, receiverModel: "", mockProvider: "", battery: nil, mslHeight: 0, undulation: 0, geoidModel: "", utcTime: millis, gpsTimeStamp: "", utcTimeStamp: "", subscriptionType: SubscriptionType.Free, satellites: 0, totalSatInView: 0, satelliteView: [])
    }
}
