import UIKit
import Alamofire
import MapKit
import AlamofireObjectMapper
import ObjectMapper
import SwiftyUserDefaults

class MainViewController: UIViewController, CLLocationManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var serverTextField: UITextField!
    var locationManager : CLLocationManager!
    var location = CLLocation(latitude: 0.0, longitude: 0.0)
    var lastScan = CLLocation(latitude: 0.0, longitude: 0.0)
    var timer : Timer?
    var playing = false
    @IBOutlet weak var actionButton: UIButton!
    var pokeManager = PokeManager()
    @IBOutlet weak var pokemonDisplay: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()

        if let str = Defaults[.url] {
            serverTextField.text = str
        }
        if Defaults[.autoStart] {
            Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(MainViewController.play), userInfo: nil, repeats: false)
        }
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
        print("double press")
        let p = gesture.location(in: self.pokemonDisplay)
        
        if let indexPath = self.pokemonDisplay.indexPathForItem(at: p) {
            pokeManager.caught(pokeManager.orderedPokemons[indexPath.item])
            update()
        }

    }
    
    var followingPokemon : Pokemon?
    func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        print("long press")
        if gesture.state != .began {
            return
        }
        let p = gesture.location(in: self.pokemonDisplay)
        
        if let indexPath = self.pokemonDisplay.indexPathForItem(at: p) {
            followingPokemon = pokeManager.orderedPokemons[indexPath.item]
            update()
        }
    }
    
    var postcounter = 0
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last!
        
        if playing {
            if location.distance(from: lastScan) > 75 {
                lastScan = location
            }
            update()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location updating error: " + error.localizedDescription)
    }
    
    @IBAction func play() {
        timer?.invalidate()
        serverTextField.resignFirstResponder()
        playing = !playing
        if playing {
            print("starting to play")
            timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(MainViewController.requestServer), userInfo: nil, repeats: true)
            timer?.fire()
        }
        actionButton.setTitle(playing ? "stop" : "start", for: UIControlState())
        Defaults[.url] = serverTextField.text
    }
    
    var range = 1
    var requestCount = 0
    let scanOffsetLat = 0.01
    let scanOffsetLon = 0.05
    
    func requestServer() {
        
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
        
        let server = serverTextField.text! + "/raw_data?pokemon=true&pokestops=false&gyms=false&scanned=false&swLat=\(latS)&swLng=\(lonS)&neLat=\(latE)&neLng=\(lonE)&_=\(now())"
        Alamofire.request(server).responseObject { (response:DataResponse<PokemonResponse>) in

            let pokemonResponse = response.result.value
            
            if let pokemonResponse = pokemonResponse {
                self.pokeManager.submitPokemons(pokemonResponse.pokemons)
            }
            self.update()
        }
        requestCount = (requestCount + 1) % (range * range)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        pokeManager.updateSettings()
    }
    
    func update() {
        pokeManager.tick(location)
        pokemonDisplay.reloadData()
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
        if pokemon.lifeTimer() < 60 {
            cell.timeout.text = "\(pokemon.lifeTimer())\""
        } else {
            cell.timeout.text = "\(pokemon.lifeTimer()/60)'\(pokemon.lifeTimer()%60)\""
        }
        
        if followingPokemon?.id == pokemon.id {
            cell.backgroundColor = UIColor.green
        } else {
            cell.backgroundColor = UIColor.clear
        }
        
        return cell
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
    }
}

