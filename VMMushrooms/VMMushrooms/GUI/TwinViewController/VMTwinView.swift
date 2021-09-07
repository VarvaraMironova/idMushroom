//
//  VMTwinView.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 12/20/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import UIKit

class VMTwinView: UIView {
    @IBOutlet var titleLabel        : UILabel!
    @IBOutlet var subtitleLabel     : UILabel!
    @IBOutlet var mushroomImageView : UIImageView!
    
    @IBOutlet var edibilityLabel    : UILabel!
    @IBOutlet var descriptionLabel  : UILabel!
//    @IBOutlet var capLabel          : UILabel!
//    @IBOutlet var stemLabel         : UILabel!
//    @IBOutlet var hymeniumLabel     : UILabel!
//    @IBOutlet var sporePrintLabel   : UILabel!
//    @IBOutlet var flashLabel        : UILabel!
//    @IBOutlet var odorLabel         : UILabel!
    
    @IBOutlet var titleLabels       : [UILabel]!
    
    func fill(model: VMTwinModel) {
        titleLabel.text = model.name
        subtitleLabel.text = model.latinName
        mushroomImageView.image = model.image
        descriptionLabel.text = model.mushroomDescription
        
        if let edibility = model.edibility {
            edibilityLabel.text = String(format: "%@", edibility.rawValue)
        }
        
    }

}
