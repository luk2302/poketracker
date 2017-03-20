import UIKit
import Alamofire
import MapKit
import AlamofireObjectMapper
import ObjectMapper
import SwiftyUserDefaults
import AudioToolbox

class MainViewController: UIViewController, CLLocationManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate {
    
    var locationManager : CLLocationManager!
    var location = CLLocation(latitude: 0.0, longitude: 0.0)
    var timer : Timer?
    var playing = false
    @IBOutlet weak var actionButton: UIButton!
    var pokeManager = PokeManager()
    @IBOutlet weak var pokemonDisplay: UICollectionView!
    var firstLocationUpdate = true
    
    override func viewDidLoad() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()

        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(MainViewController.handleLongPress))
        lpgr.delegate = self
        lpgr.minimumPressDuration = 0.2
        self.pokemonDisplay.addGestureRecognizer(lpgr)
        
        let dtgr =  UITapGestureRecognizer(target: self, action: #selector(MainViewController.handleDoublePress))
        dtgr.numberOfTapsRequired = 2
        dtgr.delegate = self
        self.pokemonDisplay.addGestureRecognizer(dtgr)
    }

    func handleDoublePress(gesture : UITapGestureRecognizer) {
        let p = gesture.location(in: self.pokemonDisplay)
        
        if let indexPath = self.pokemonDisplay.indexPathForItem(at: p) {
            pokeManager.caught(pokeManager.orderedPokemons[indexPath.item])
            update()
        }
    }
    
    var followingPokemon : Pokemon?
    var followingDidRecentlyVibrate = false
    var lookingAtFollowing = false
    func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        if gesture.state != .began {
            return
        }
        let p = gesture.location(in: self.pokemonDisplay)
        
        if let indexPath = self.pokemonDisplay.indexPathForItem(at: p) {
            let newFollow = pokeManager.orderedPokemons[indexPath.item]
            if let current = followingPokemon {
                if current === newFollow {
                    followingPokemon = nil
                } else {
                    followingPokemon = newFollow
                }
            } else {
                followingPokemon = newFollow
            }
            followingDidRecentlyVibrate = false
            lookingAtFollowing = false
            update()
        }
    }
    
    var postcounter = 0
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        
        print("location update")
        if newLocation.distance(from: location) > 10 {
            location = newLocation
            print("updating")
            update()
        }
        if firstLocationUpdate && Defaults[.autoStart] {
            firstLocationUpdate = false
            play()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location updating error: " + error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
        guard let pokemon = followingPokemon else {
            return
        }
        let me = location
        let mon = pokemon.location
        let heading = newHeading.trueHeading
        var bearing = getBearingBetweenTwoPoints1(point1: me, point2: mon)
        if bearing < 0 {
            bearing = 360 + bearing
        }
        
        let bearingThreshold = 22.5
        let relativeBearing = heading - bearing
        if abs(relativeBearing) < bearingThreshold {
            if !followingDidRecentlyVibrate {
                if Defaults[.vibration] {
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
                followingDidRecentlyVibrate = true
            }
            if !lookingAtFollowing {
                lookingAtFollowing = true
                update()
            }
        } else {
            followingDidRecentlyVibrate = false
            if lookingAtFollowing {
                lookingAtFollowing = false
                update()
            }
        }
    }    
    
    @IBAction func play() {
        timer?.invalidate()
        playing = !playing
        if playing {
            timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(MainViewController.requestServer), userInfo: nil, repeats: true)
            timer?.fire()
        }
        actionButton.setTitle(playing ? "stop" : "start", for: UIControlState())
    }
    
    var range = 1
    var requestCount = 0
    let scanOffsetLat = 0.025 * 2.0
    let scanOffsetLon = 0.125 * 2.0
    
    func requestServer() {
        
        guard let url = Defaults[.url] else {
            return
        }
        
        let xoff = requestCount / range - (range - 1) / 2
        let yoff = requestCount % range - (range - 1) / 2
        
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let offsetLat = Double(xoff) * scanOffsetLat // negative is down, positive is up
        let offsetLon = Double(yoff) * scanOffsetLon // negative is left, positive is right
        let rangeLat = scanOffsetLat
        let rangeLon = scanOffsetLon
        
        let latS = lat.advanced(by: offsetLat - rangeLat / 2)
        let latE = lat.advanced(by: offsetLat + rangeLat / 2)
        let lonS = lon.advanced(by: offsetLon - rangeLon / 2)
        let lonE = lon.advanced(by: offsetLon + rangeLon / 2)
        
        let server = url + "/raw_data?pokemon=true&pokestops=false&gyms=false&scanned=false&swLat=\(latS)&swLng=\(lonS)&neLat=\(latE)&neLng=\(lonE)&_=\(now())"
        print("requesting \(server)")
        Alamofire.request(server).responseObject { (response:DataResponse<PokemonResponse>) in

            let pokemonResponse = response.result.value
            
            if let pokemonResponse = pokemonResponse {
                self.pokeManager.submitPokemons(pokemonResponse.pokemons)
            }
            self.update()
        }
        requestCount = (requestCount + 1) % (range * range)
    }
    
    var updateTimer : Timer?
    override func viewWillAppear(_ animated: Bool) {
        pokeManager.updateSettings()
        if let updateTimer = updateTimer {
            updateTimer.invalidate()
        }
        updateTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(MainViewController.updateTimeouts), userInfo: nil, repeats: true)
        update()
    }
    
    func updateTimeouts() {
        print("update")
        pokemonDisplay.reloadItems(at: pokemonDisplay.indexPathsForVisibleItems)
        pokemonDisplay.indexPathsForVisibleItems.forEach {
            if let cell = pokemonDisplay.cellForItem(at: $0) as? PokemonCell {
                cell.updateTimer()
            }
        }
    }
    
    func update() {
        pokeManager.tick(location)
        pokemonDisplay.reloadData()
        print("updated")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pokeManager.pokemonCount
    }
    
    func getDistanceDesc3(_ distance : Int) -> String {
        return "~\(Int(round(Double(distance) / 10) * 10))m"
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PokemonCell = collectionView.dequeueReusableCell(withReuseIdentifier: "pokemonCell", for: indexPath) as! PokemonCell
        let pokemon = pokeManager.orderedPokemons[indexPath.item]
        cell.name.text = pokemon.pokemonName
        cell.mon = pokemon
        cell.image.image = pokemon.image
        let distance = Int(location.distance(from: pokemon.location))
        
        cell.distance.text = "\(getDistanceDesc3(distance))"
        cell.updateTimer()
        
        if followingPokemon?.id == pokemon.id {
            if lookingAtFollowing {
                cell.backgroundColor = UIColor.green
            } else {
                cell.backgroundColor = UIColor.orange
            }
        } else {
            cell.backgroundColor = UIColor.clear
        }
        
        return cell
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
    }
}

