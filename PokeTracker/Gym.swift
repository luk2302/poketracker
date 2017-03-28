
import Foundation
import ObjectMapper
import CoreLocation


class Gym : Mappable {
    static let prestigeLevels = [0, 2000, 4000, 8000, 12000, 16000, 20000, 30000, 40000, 50000]
    var enabled : Bool!
    var id : String!
    var prestige : Int!
    fileprivate var lat : Double!
    fileprivate var lon : Double!
    var team : Int!
    var location : CLLocation {
        get {
            return CLLocation(latitude: lat, longitude: lon)
        }
    }
    var level : Int {
        get {
            let level = Gym.prestigeLevels.index { $0 > prestige }
            if let level = level {
                return level.littleEndian
            } else {
                return 10
            }
        }
    }
    var progress : Double {
        get {
            let nextLevel = Gym.prestigeLevels.index { $0 > prestige }
            if let nextLevel = nextLevel {
                if nextLevel == Gym.prestigeLevels.startIndex {
                    return 0
                }
                let nextPrestige = Gym.prestigeLevels[nextLevel]
                let lastPrestige = Gym.prestigeLevels[nextLevel.advanced(by: -1)]
                let overPrestige = prestige - lastPrestige
                let prestigeNeeded = nextPrestige - lastPrestige
                return Double(overPrestige) / Double(prestigeNeeded)
            } else {
                return 0
            }
        }
    }

    required init?(map: Map) {}
    
    func mapping(map: Map) {
        lat             <- map["latitude"]
        lon             <- map["longitude"]
        id              <- map["gym_id"]
        enabled         <- map["enabled"]
        prestige        <- map["gym_points"]
        team            <- map["team_id"]
    }
}

class GymResponse : Mappable {
    var gyms : [String : Gym]!
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        gyms   <- map["gyms"]
    }
}
