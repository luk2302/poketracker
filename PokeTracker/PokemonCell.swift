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
    
    func updateColor(_ lookingAtFollowing : Bool, _ following : Pokemon?) {
        if let following = following {
            if following.id == mon.id {
                if lookingAtFollowing {
                    backgroundColor = UIColor.green
                } else {
                    backgroundColor = UIColor.orange
                }
            } else {
                backgroundColor = UIColor.clear
            }
        } else {
            backgroundColor = UIColor.clear
        }
    }
}
