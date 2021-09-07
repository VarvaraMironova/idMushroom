//
//  VMRecognizingPhotosCell.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 1/9/20.
//  Copyright © 2020 Varvara Myronova. All rights reserved.
//

import UIKit

class VMRecognizingPhotosCell: UICollectionViewCell {
    @IBOutlet var recognizingImageView  : UIImageView!
    @IBOutlet var removeImageButton     : UIButton!
    
    
    public func fill(image: UIImage, deleteTarget: VMImageCaptureViewController, action: Selector, tag: Int) {
        recognizingImageView.image = image
        removeImageButton.addTarget(deleteTarget, action: action, for: .touchUpInside)
        removeImageButton.tag = tag
    }

}
