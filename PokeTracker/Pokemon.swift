

import Foundation
import ObjectMapper
import CoreLocation

class Pokemon: Mappable {
    var disappearTime : Int
    var pokemonId : Int
    var pokemonName : String
    fileprivate var lat : Double
    fileprivate var lon : Double
    var id : String
    var caught = false
    var location : CLLocation {
        get {
            return CLLocation(latitude: lat, longitude: lon)
        }
    }
    
    func lifeTimer() -> Int {
        return Int((disappearTime - now()) / 1000)
    }
    
    
    required init?(map: Map) {
        disappearTime = 1
        pokemonId = -1
        pokemonName = "none"
        lat = 0
        lon = 0
        id = "-1"
    }
    
    func mapping(map: Map) {
        disappearTime   <- map["disappear_time"]
        lat             <- map["latitude"]
        lon             <- map["longitude"]
        pokemonId       <- map["pokemon_id"]
        pokemonName     <- map["pokemon_name"]
        id              <- map["encounter_id"]
    }
}

class PokemonResponse : Mappable {
    var pokemons : [Pokemon]!
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        pokemons   <- map["pokemons"]
    }
}