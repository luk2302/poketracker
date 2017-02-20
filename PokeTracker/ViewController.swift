import UIKit
import Alamofire
import MapKit
import AlamofireObjectMapper
import ObjectMapper

class ViewController: UIViewController, CLLocationManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
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

        if let string = UserDefaults.standard.object(forKey: "url") as? String {
            serverTextField.text = string
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
        print("changed")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location updating error: " + error.localizedDescription)
    }
    
    @IBAction func play(_ sender: AnyObject) {
        timer?.invalidate()
        serverTextField.resignFirstResponder()
        playing = !playing
        if playing {
            print("starting to play")
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.requestServer), userInfo: nil, repeats: true)
            timer?.fire()
            alert("Started", body: "Started requesting pokemon data")
        }
        actionButton.setTitle(playing ? "stop" : "start", for: UIControlState())
        UserDefaults.standard.set(serverTextField.text!, forKey: "url")
    }
    
    func alert(_ title : String, body : String) {
        let alert = UIAlertView(title: title, message: body, delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "Ok")
        alert.show()
    }
    
    var range = 5
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
        
        //print("requesting pokemon for \(lat + offsetLat), \(lon + offsetLon)")
        
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
    
    func update() {
        pokeManager.tick(location)
        pokemonDisplay.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pokeManager.pokemonCount
    }
    
    func getDistanceDesc(_ distance : Int) -> String {
        let distanceRanges = [50, 100, 200, 500, 1000, 2000]
        let distanceDesc = ["Catch it", "Quite Close", "Close", "Medium", "A Walk", "Far Away", "Far faaar"]
        let near = distanceRanges.filter { $0 < distance }.count
        return "\(distanceDesc[near])"
    }
    
    func getDistanceDesc2(_ distance : Int) -> String {
        let distanceRanges = [20, 30, 50, 70, 100, 150, 200, 300, 400, 500, 700, 800, 900, 1000]
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
        let distance = Int(location.distance(from: pokemon.location))
        
        cell.distance.text = "\(getDistanceDesc2(distance))"
        
        cell.timeout.text = "\(pokemon.lifeTimer())s"
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        pokeManager.caught(pokeManager.orderedPokemons[indexPath.item])
        update()
    }
}

