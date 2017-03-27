
import Foundation
import Alamofire
import AlamofireObjectMapper
import SwiftyUserDefaults
import ObjectMapper
import MapKit

class Networker {
    
    
    static let scanOffsetLat = 0.150
    static let scanOffsetLon = 0.200
    static func requestPokemons(location : CLLocation, completion : @escaping (PokemonResponse) -> ()) {
        requestServer(pokemons: true, gyms: false, pokestops: false, location: location, range: 0.5) {
            completion($0)
        }
    }
    
    fileprivate static func requestServer<T : Mappable>(pokemons : Bool, gyms : Bool, pokestops : Bool, location : CLLocation, range : Double, completion: @escaping (T) -> Void) {
        guard let url = Defaults[.url] else {
            return
        }
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        let latS = lat.advanced(by: -scanOffsetLat / 2 * range)
        let latE = lat.advanced(by: scanOffsetLat / 2 * range)
        let lonS = lon.advanced(by: -scanOffsetLon / 2 * range)
        let lonE = lon.advanced(by: scanOffsetLon / 2 * range)
        
        let server = url + "/raw_data?pokemon=\(pokemons)&pokestops=\(pokestops)&gyms=\(gyms)&scanned=false&swLat=\(latS)&swLng=\(lonS)&neLat=\(latE)&neLng=\(lonE)&_=\(now())"
        print("requesting \(server)")
        Alamofire.request(server).responseObject { (response:DataResponse<T>) in
            let response = response.result.value
            
            if let response = response {
                completion(response)
            }
        }
    }
    
    static func requestGyms(location : CLLocation, completion : @escaping (GymResponse) -> ()) {
        requestServer(pokemons: false, gyms: true, pokestops: false, location: location, range: 1.0) {
            completion($0)
        }
    }
}
