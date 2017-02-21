import Foundation
import UIKit
import CoreLocation
import SwiftyUserDefaults

class PokeManager {
    
    fileprivate var pokemons = [String : Pokemon]()

    func submitPokemons(_ newMons : [Pokemon]) {
        print("\(newMons.count) new pokemon")
        newMons.forEach { pokemon in
            if let alreadyHere = pokemons[pokemon.id], alreadyHere.caught == true {
                return
            }
            pokemons[pokemon.id] = pokemon
        }
    }
    var pokemonCount = 0
    
    var orderedPokemons = [Pokemon]()
    
    func caught(_ mon : Pokemon) {
        mon.caught = true
    }
    
    func follow(_ mon : Pokemon) {
        mon.follow = true
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
        pokemonCount = orderedPokemons.count
    }
    
    fileprivate func getOrderedList(_ location : CLLocation) -> [Pokemon] {
        return pokemons.values.filter { !$0.caught } .sorted {
            location.distance(from: $0.0.location) < location.distance(from: $0.1.location)
        }
    }
}
