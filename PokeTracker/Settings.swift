
import Foundation
import UIKit
import SwiftyUserDefaults


extension DefaultsKeys {
    static let autoStart = DefaultsKey<Bool>("autoStart")
    static let pokemonCount = DefaultsKey<Int>("pokemonCount")
    static let exclusions = DefaultsKey<[Int]>("exclusions")
    static let url = DefaultsKey<String?>("url")
}

class SettingViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var pokemonCountLabel: UILabel!
    @IBOutlet weak var exclusionView: UICollectionView!
    @IBOutlet weak var autoStartSwitcher: UISwitch!
    @IBOutlet weak var pokemonCountStepper: UIStepper!
    
    var excluded : Set<Int>!
    
    override func viewWillAppear(_ animated: Bool) {
        pokemonCountStepper.value = Double(Defaults[.pokemonCount])
        pokemonCountLabel.text = "\(Defaults[.pokemonCount])"
        autoStartSwitcher.isOn = Defaults[.autoStart]
        
        excluded = Set(Defaults[.exclusions])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Defaults[.pokemonCount]
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
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
        if excluded.contains(indexPath.row + 1) {
            excluded.remove(indexPath.row + 1)
        } else{
            excluded.insert(indexPath.row + 1)
        }
        Defaults[.exclusions] = Array(excluded)
        collectionView.reloadData()
    }
    
    @IBAction func autoStartChanged() {
        Defaults[.autoStart] = autoStartSwitcher.isOn
    }
    
    @IBAction func pokemonCountChanged() {
        Defaults[.pokemonCount] = Int(pokemonCountStepper.value)
        pokemonCountLabel.text = "\(Int(pokemonCountStepper.value))"
        exclusionView.reloadData()
    }
}

class PokemonSettingCell : UICollectionViewCell {
    @IBOutlet weak var image: UIImageView!
}
