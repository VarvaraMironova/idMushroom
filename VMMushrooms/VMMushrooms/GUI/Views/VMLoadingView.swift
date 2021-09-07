//
//  VMLoadingView.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 3/3/20.
//  Copyright © 2020 Varvara Myronova. All rights reserved.
//

import UIKit

class VMLoadingView: UIView {
    weak var rootView: UIView?
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    private var isShown: Bool = false
    
    private func show() {
        if isShown {
            return
        }
        
        if let rootView = rootView {
            DispatchQueue.main.async {[weak self] in
                guard let strongSelf = self else { return }
                var frame = rootView.frame
                frame.origin = .zero
                strongSelf.frame = frame
                rootView.addSubview(strongSelf)
                
                strongSelf.activityIndicator.startAnimating()
                
                strongSelf.isShown = true
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    class func loadingView(inView view: UIView) -> VMLoadingView? {
        if let loadingView = UINib(nibName: "VMLoadingView", bundle: nil).instantiate(withOwner: nil, options: nil).first as? VMLoadingView
        {
            loadingView.rootView = view
            loadingView.show()
            return loadingView
        } else {
            return nil
        }
    }
    
    func hide() {
        if !isShown {
            return
        }
        
        DispatchQueue.main.async {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.activityIndicator.stopAnimating()
            
            strongSelf.removeFromSuperview()
            
            strongSelf.isShown = false
        }
    }
}
