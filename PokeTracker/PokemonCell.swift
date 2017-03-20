import Foundation
import UIKit

class PokemonCell: UICollectionViewCell {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var timeout: UILabel!
    var mon : Pokemon!
    
    func updateTimer() {
        let time = mon.lifeTimer()
        if time < 60 {
            timeout.text = "<1 min"
        } else {
            timeout.text = "~\(time / 60) min"
        }
    }
}
