//
//  PokemonCell.swift
//  PokeTracker
//
//  Created by Lukas Rinke on 01.08.16.
//  Copyright © 2016 Lukas Rinke. All rights reserved.
//

import Foundation
import UIKit

class PokemonCell: UICollectionViewCell {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var timeout: UILabel!
    var mon : Pokemon!
}