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
            pokemonDisplay.deleteItems(at: [indexPath])
            UIButton().contentHorizontalAlignment = .left
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        if let timer = updateTimer {
            timer.invalidate()
            updateTimer = nil
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
            updateFollowingColors()
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
                updateFollowingColors()
            }
        } else {
            followingDidRecentlyVibrate = false
            if lookingAtFollowing {
                lookingAtFollowing = false
                updateFollowingColors()
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
    }
    
    func requestServer() {
        Networker.requestPokemons(location: location) {
            self.pokeManager.submitPokemons($0.pokemons)
            self.update()
        }
    }
    
    var updateTimer : Timer?
    override func viewWillAppear(_ animated: Bool) {
        pokeManager.updateSettings()
        if let updateTimer = updateTimer {
            updateTimer.invalidate()
        }
        updateTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(MainViewController.updateTimeouts), userInfo: nil, repeats: true)
        update()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func updateTimeouts() {
        DispatchQueue.main.async {
            self.pokemonDisplay.forEachVisibleCell { (cell : PokemonCell) in
                cell.updateTimer()
            }
        }
    }
    
    func updateFollowingColors() {
        pokemonDisplay.forEachVisibleCell { (cell : PokemonCell) in
            cell.updateColor(self.lookingAtFollowing, self.followingPokemon)
        }
    }
    
    func update() {
        pokeManager.tick(location)
        DispatchQueue.main.async {
            self.pokemonDisplay.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("reloaded")
        return pokeManager.orderedPokemons.count
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
        cell.updateColor(lookingAtFollowing, followingPokemon)
        
        return cell
    }
}

