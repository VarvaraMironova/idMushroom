//
//  VMTwinModelCollectionViewCell.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 12/17/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import UIKit

class VMTwinModelCollectionViewCell: UICollectionViewCell {
    @IBOutlet var twinImageView: UIImageView!
    
    var model : VMTwinModel!
    
    func fillWithModel(model: VMTwinModel) {
        self.model = model
        
        if let image = model.image {
            twinImageView.image = image
        }
    }

}
