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
    var followingMons = Set<String>()
    
    
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
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        lpgr.minimumPressDuration = 0.2
        self.pokemonDisplay.addGestureRecognizer(lpgr)
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
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        if gesture.state != .ended {
            return
        }
        let p = gesture.location(in: self.pokemonDisplay)
        
        if let indexPath = self.pokemonDisplay.indexPathForItem(at: p) {
            pokeManager.follow(pokeManager.orderedPokemons[indexPath.item])
            update()
        } else {
            print("couldn't find index path")
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
    
    func getDistanceDesc2(_ distance : Int) -> String {
        let distanceRanges = [20, 30, 50, 70, 100, 150, 200, 300, 400, 500, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000]
        if distance < distanceRanges.first! {
            return "< \(distanceRanges.first!)m"
        }
        if distance > distanceRanges.last! {
            return "> \(distanceRanges.last!)m"
        }
        let far = distanceRanges.filter { distance <= $0 }.first!
        let near = distanceRanges.filter { distance > $0 }.last!
        return "\(near)-\(far)m"
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PokemonCell = collectionView.dequeueReusableCell(withReuseIdentifier: "pokemonCell", for: indexPath) as! PokemonCell
        let pokemon = pokeManager.orderedPokemons[indexPath.item]
        cell.name.text = pokemon.pokemonName
        cell.mon = pokemon
        cell.image.image = pokemon.image
        let distance = Int(location.distance(from: pokemon.location))
        
        cell.distance.text = "\(getDistanceDesc2(distance))"
        if pokemon.lifeTimer() < 60 {
            cell.timeout.text = "\(pokemon.lifeTimer())\""
        } else {
            cell.timeout.text = "\(pokemon.lifeTimer()/60)'\(pokemon.lifeTimer()%60)\""
        }
        
        if pokemon.follow {
            cell.backgroundColor = UIColor.green
        } else {
            cell.backgroundColor = UIColor.clear
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        pokeManager.caught(pokeManager.orderedPokemons[indexPath.item])
        update()
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
    }
}

