
import Foundation
import UIKit
import SwiftyUserDefaults


extension DefaultsKeys {
    static let autoStart = DefaultsKey<Bool>("autoStart")
    static let pokemonCount = DefaultsKey<Int>("pokemonCount")
    static let exclusions = DefaultsKey<[Int]>("exclusions")
    static let url = DefaultsKey<String?>("url")
    static let vibrationThreshold = DefaultsKey<Int>("vibrationThreshold")
    static let vibration = DefaultsKey<Bool>("vibration")
}

class SettingViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var vibrationSwitcher: UISwitch!
    @IBOutlet weak var serverTextfield: UITextField!
    @IBOutlet weak var vibrationThresholdLabel: UILabel!
    @IBOutlet weak var pokemonCountLabel: UILabel!
    @IBOutlet weak var exclusionView: UICollectionView!
    @IBOutlet weak var autoStartSwitcher: UISwitch!
    @IBOutlet weak var pokemonCountStepper: UIStepper!
    @IBOutlet weak var vibrationThreasholdStepper: UIStepper!
    
    var excluded : Set<Int>!
    
    override func viewDidLoad() {
        let layout = exclusionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.sectionHeadersPinToVisibleBounds = true
    }
    
    @IBAction func vibrationThresholdChanged(_ sender: UIStepper) {
        serverTextfield.resignFirstResponder()
        Defaults[.vibrationThreshold] = Int(vibrationThreasholdStepper.value)
        vibrationThresholdLabel.text = "\(Defaults[.vibrationThreshold])"
    }
    override func viewWillAppear(_ animated: Bool) {
        pokemonCountStepper.value = Double(Defaults[.pokemonCount])
        pokemonCountLabel.text = "\(Defaults[.pokemonCount])"
        vibrationThreasholdStepper.value = Double(Defaults[.vibrationThreshold])
        vibrationThresholdLabel.text = "\(Defaults[.vibrationThreshold])"
        autoStartSwitcher.isOn = Defaults[.autoStart]
        excluded = Set(Defaults[.exclusions])
        vibrationSwitcher.isOn = Defaults[.vibration]
        serverTextfield.text = Defaults[.url]
    }
    @IBAction func vibrationToggleChanged() {
        serverTextfield.resignFirstResponder()
        Defaults[.vibration] = vibrationSwitcher.isOn
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Defaults[.pokemonCount]
    }
    @IBAction func serverEditingEnded(_ sender: UITextField) {
        Defaults[.url] = sender.text
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "exclusionHeader", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "pokemonSettingCell", for: indexPath) as! PokemonSettingCell
        
        cell.image.image = Pokemon.sprites[indexPath.row]
        if excluded.contains(indexPath.row + 1) {
            cell.backgroundColor = UIColor.orange
        } else {
            cell.backgroundColor = UIColor.clear
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        serverTextfield.resignFirstResponder()
        if excluded.contains(indexPath.row + 1) {
            excluded.remove(indexPath.row + 1)
        } else{
            excluded.insert(indexPath.row + 1)
        }
        Defaults[.exclusions] = Array(excluded)
        collectionView.reloadData()
    }
    
    @IBAction func autoStartChanged() {
        serverTextfield.resignFirstResponder()
        Defaults[.autoStart] = autoStartSwitcher.isOn
    }
    
    @IBAction func pokemonCountChanged() {
        serverTextfield.resignFirstResponder()
        Defaults[.pokemonCount] = Int(pokemonCountStepper.value)
        pokemonCountLabel.text = "\(Int(pokemonCountStepper.value))"
        exclusionView.reloadData()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        serverTextfield.resignFirstResponder()
    }
}

class PokemonSettingCell : UICollectionViewCell {
    @IBOutlet weak var image: UIImageView!
}
