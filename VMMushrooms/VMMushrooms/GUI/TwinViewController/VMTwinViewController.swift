//
//  VMTwinViewController.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 12/20/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import UIKit

class VMTwinViewController: UIViewController {
    
    weak private var rootView: VMTwinView? {
        return viewIfLoaded as? VMTwinView
    }
    
    var model : VMTwinModel?
    
    //MARK:- attributes for interacting animations
    var swipeInteractionController: VMSwipeInteractionController?
    
    //MARK:- helper attributes fo dismissing TWIN animation
    var animationView : UIView? {
        if let rootView = rootView {
            return rootView.mushroomImageView
        }
        
        return nil
    }
    
    var originalAnimationFrame : CGRect? {
        if let rootView = rootView {
            return rootView.mushroomImageView.frame
        }
        
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let rootView = rootView, let model = model {
            rootView.fill(model: model)
        }
        
        swipeInteractionController = VMSwipeInteractionController(viewController: self)
    }
    
    @IBAction func onDismissButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

}
