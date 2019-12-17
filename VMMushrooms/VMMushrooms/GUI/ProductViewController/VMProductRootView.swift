//
//  VMProductRootView.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 1/16/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import UIKit

enum State : Int {
    case expanded
    case collapsed
}

class VMProductRootView: UIView {
    @IBOutlet var titleLabel        : UILabel!
    //@IBOutlet var blurView          : UIVisualEffectView!
    @IBOutlet var subtitleLabel     : UILabel!
    @IBOutlet var descriptionLabel  : UILabel!
    
    @IBOutlet var edibilityTitleLabelLabel  : UILabel!
    @IBOutlet var edibilityLabel            : UILabel!
    @IBOutlet var confusedTitleLabel        : UILabel!
    
    @IBOutlet var mushroomImagesCollectionView  : UICollectionView!
    @IBOutlet var confusedCollectionView        : UICollectionView!
    
    @IBOutlet var expandedView: UIView!
    
    var expandedViewState: State = .collapsed
    
    override func awakeFromNib() {
        mushroomImagesCollectionView.register(UINib(nibName: "VMPhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "VMPhotoCollectionViewCell")
        confusedCollectionView.register(UINib(nibName: "VMPhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "VMPhotoCollectionViewCell")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)

//        expandedView.roundCorner(corner: .Top, radius: 30.0)
//        expandedView.drawShadow()
    }
    
    public func fillWithModel (model: VMMushroomModel) {
        titleLabel.text = model.name
        subtitleLabel.text = model.latinName
        
        if let edibility = model.edibility {
            edibilityLabel.text = String(format: "edibility: %@", edibility.rawValue)
        }
        
        descriptionLabel.text = model.mushroomDescription
    }

}
