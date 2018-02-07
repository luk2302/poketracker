
import Foundation
import ObjectMapper
import CoreLocation

class Raid : Mappable {
    var cp : Int!
    var start : Int!
    var spawn : Int!
    var end : Int!
    var pokemon : Int!
    var level : Int!
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        cp            <- map["cp"]
        end           <- map["end"]
        spawn         <- map["spawn"]
        start         <- map["start"]
        pokemon       <- map["pokemon_id"]
        level         <- map["level"]
    }
    
    func isOngoing() -> Bool {
        let n = now()
        return n > start && n < end
    }
}

class Gym : Mappable {
    var enabled : Bool!
    var id : String!
    fileprivate var lat : Double!
    fileprivate var lon : Double!
    var team : Int!
    var totalCP : Int!
    var raid : Raid!
    var availableSlots : Int!
    
    var location : CLLocation {
        get {
            return CLLocation(latitude: lat, longitude: lon)
        }
    }
    var level : Int {
        get {
            return 6 - availableSlots
        }
    }
    var progress : Double {
        get {
            guard hasRaid else { return 0 }
            let n = now()
            if raid.isOngoing() {
                return Double((n - raid.start)) / Double((raid.end - raid.start))
            }
            return Double((n - raid.spawn)) / Double((raid.start - raid.spawn))
        }
    }
    var hasRaid : Bool {
        get {
            return raid != nil && raid.end != 0 && raid.start != 0 && raid.spawn != 0 && raid.end > now()
        }
    }

    required init?(map: Map) {}
    
    func mapping(map: Map) {
        lat             <- map["latitude"]
        lon             <- map["longitude"]
        id              <- map["gym_id"]
        enabled         <- map["enabled"]
        availableSlots  <- map["slots_available"]
        team            <- map["team_id"]
        totalCP         <- map["total_cp"]
        raid            <- map["raid"]
        
    }
}

class GymResponse : Mappable {
    var gyms : [String : Gym]!
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        gyms   <- map["gyms"]
    }
}
