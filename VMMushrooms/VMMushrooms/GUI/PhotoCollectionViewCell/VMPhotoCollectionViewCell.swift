//
//  VMPhotoCollectionViewCell.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 1/23/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import UIKit

class VMPhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet var mushroomImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func fillWithImage(image:UIImage) {
        self.mushroomImageView.image = image
    }

}
