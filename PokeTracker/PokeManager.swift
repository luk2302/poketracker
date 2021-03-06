import Foundation
import UIKit
import CoreLocation
import SwiftyUserDefaults

class PokeManager {
    
    fileprivate var pokemons = [String : Pokemon]()

    func submitPokemons(_ newMons : [Pokemon]) {
        print("\(newMons.count) new pokemon")
        newMons.forEach { pokemon in
            if pokemons[pokemon.id] != nil {
                return
            }
            pokemons[pokemon.id] = pokemon
        }
    }
    
    var orderedPokemons = [Pokemon]()
    
    func caught(_ mon : Pokemon) {
        mon.caught = true
        orderedPokemons = orderedPokemons.filter { $0.id != mon.id }
    }
    
    func toggleFollow(_ mon : Pokemon) {
        mon.follow = !mon.follow
    }
    
    fileprivate var exclusions : Set<Int>!
    func updateSettings() {
        exclusions = Set(Defaults[.exclusions])
        print(exclusions)
    }
    
    func tick(_ location : CLLocation) {
        let despawned = pokemons.values.filter {
            $0.lifeTimer() <= 0
        }
        despawned.forEach {
            pokemons.removeValue(forKey: $0.id)
        }
        orderedPokemons = getOrderedList(location).filter { !exclusions.contains($0.pokemonId) }
        
    }
    
    fileprivate func getOrderedList(_ location : CLLocation) -> [Pokemon] {
        let filtered = pokemons.values.filter { !$0.caught }
        return filtered.sorted {
            location.distance(from: $0.0.location) < location.distance(from: $0.1.location)
        }
    }
}
