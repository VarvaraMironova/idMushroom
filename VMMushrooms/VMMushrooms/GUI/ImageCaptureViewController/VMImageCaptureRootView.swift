//
//  VMImageCaptureRootView.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 1/15/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import UIKit

class VMImageCaptureRootView: UIView {
    @IBOutlet var capturedImageView     : UIImageView!
    @IBOutlet var previewView           : VMPreviewView!
    @IBOutlet var photosCollectionView  : UICollectionView!
    @IBOutlet var takePhotoButton       : UIButton!
    
    private var loadingView:    VMLoadingView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let kVMCellName = "VMRecognizingPhotosCell"
        photosCollectionView.register(UINib(nibName              : kVMCellName,
                                            bundle               : nil),
                                      forCellWithReuseIdentifier : kVMCellName)
        
        clearImage(animated: false)
    }
    
    //MARK:- Public
    public func showLoadingView() {
        if let _ = loadingView {
            return
        }
        
        loadingView = VMLoadingView.loadingView(inView: self)
    }
    
    public func hideLoadingView() {
        if let loadingView = loadingView {
            loadingView.hide()
            self.loadingView = nil
        }
    }
    
    public func fill(image: UIImage) {
        capturedImageView.alpha = 1.0
        capturedImageView.image = image
    }
    
    func clearImage(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.26,
                           animations:
            {
                self.capturedImageView.alpha = 0.0
            })
            { (finished) in
                if finished {
                    self.capturedImageView.image = nil
                }
            }
        } else {
            self.capturedImageView.alpha = 0.0
            self.capturedImageView.image = nil
        }
    }
    
}
