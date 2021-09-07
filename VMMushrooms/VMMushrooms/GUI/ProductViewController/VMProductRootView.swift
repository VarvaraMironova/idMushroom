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
    @IBOutlet var subtitleLabel     : UILabel!
    @IBOutlet var descriptionLabel  : UILabel!
    @IBOutlet var pageControl       : UIPageControl!
    
    @IBOutlet var edibilityTitleLabelLabel  : UILabel!
    @IBOutlet var edibilityLabel            : UILabel!
    @IBOutlet var confusedTitleLabel        : UILabel!
    
    @IBOutlet var mushroomImagesCollectionView  : UICollectionView!
    @IBOutlet var confusedCollectionView        : UICollectionView!
    
    @IBOutlet var expandedView: UIView!
    
    var expandedViewState: State = .collapsed
    
    override func awakeFromNib() {
        mushroomImagesCollectionView.register(UINib(nibName: "VMPhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "VMPhotoCollectionViewCell")
        confusedCollectionView.register(UINib(nibName: "VMTwinModelCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "VMTwinModelCollectionViewCell")
    }
    
    public func fillWithModel (model: VMMushroomModel) {
        titleLabel.text = model.name
        subtitleLabel.text = model.latinName
        
        if let edibility = model.edibility {
            edibilityLabel.text = String(format: "%@", edibility.rawValue)
        }
        
        descriptionLabel.text = model.mushroomDescription
    }

}
