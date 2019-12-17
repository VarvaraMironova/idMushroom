//
//  VMProductViewControllerViewController.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 1/16/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import UIKit

class VMProductViewControllerViewController: UIViewController,
                                             UIGestureRecognizerDelegate,
                                             UICollectionViewDelegate,
                                             UICollectionViewDataSource,
                                             UICollectionViewDelegateFlowLayout
{
    
    weak private var rootView: VMProductRootView? {
        return viewIfLoaded as? VMProductRootView
    }
    
    var mushroomModel: VMMushroomModel!
    
    var animator: UIViewPropertyAnimator!
    
    @IBOutlet var panGR: UIPanGestureRecognizer!
    @IBOutlet var tapGR: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootView?.fillWithModel(model: mushroomModel)
        
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    //MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView.tag {
        case 1:
            return 2
            
        case 2:
            return mushroomModel.twins.count
            
        default:
            return 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch collectionView.tag {
        case 1:
            return 2
            
        case 2:
            return 1
            
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VMPhotoCollectionViewCell", for: indexPath) as! VMPhotoCollectionViewCell
        
        switch collectionView.tag {
        case 1:
            let index = indexPath.row + indexPath.section
            let images = self.mushroomModel.images
            
            if (images.count > index) {
                let image = self.mushroomModel.images[index]
                cell.fillWithImage(image: image)
            }
            
            break
            
        case 2:
            let twinModel = self.mushroomModel.twins[indexPath.row]
            
            if let image = twinModel.images.first {
                cell.fillWithImage(image: image)
            }
            
            break
            
        default:
            break
        }
        
        return cell
    }
    
    //MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch collectionView.tag {
        case 1:
            return CGSize(width:  collectionView.bounds.size.width, height:  collectionView.bounds.size.height)
            
        case 2:
            return CGSize(width: collectionView.bounds.size.height, height: collectionView.bounds.size.height)
            
        default:
            return CGSize.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        switch collectionView.tag {
        case 1:
            return 1.0
            
        case 2:
            return 3.0
            
        default:
            return 0.0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch collectionView.tag {
        case 1:
            return 5.0
            
        default:
            return 0.0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    //MARK: - Gesture recognizers
    
    @IBAction func onPanGR(_ sender: UIPanGestureRecognizer) {
        guard let recognizerView = sender.view else {
            return
        }
        
        guard let rootView = rootView else {
            return
        }
        
        let translation = sender.translation(in: rootView)
        var destinationPoint = recognizerView.center
        let halfHeight = recognizerView.bounds.size.height / 2.0
        let maxY = rootView.bounds.maxY
        let newCenterMaxY = maxY + halfHeight - 80.0
        let newCenterMinY = maxY - halfHeight
        
        switch sender.state {
        case .began, .changed, .possible:
            destinationPoint.y += translation.y
            destinationPoint.y = min(max(destinationPoint.y, newCenterMinY), newCenterMaxY)
            recognizerView.center = destinationPoint
            sender.setTranslation(.zero, in: rootView)
            
            break
            
        case .ended, .failed, .cancelled:
            let velocity = sender.velocity(in: rootView)
            destinationPoint.y = velocity.y > 0 ? newCenterMaxY : newCenterMinY
            animator = UIViewPropertyAnimator(duration: 0.3,
                                              curve: .easeOut,
                                              animations:
                {
                    recognizerView.center = destinationPoint
            })
            
            animator.pauseAnimation()
            animator.addCompletion { (position) in
                switch position {
                    case .end:
                        rootView.expandedViewState = rootView.expandedViewState == .collapsed ? .expanded : .collapsed
                    break
                    
                default:
                    break
                }
            }
            
            let timing = UICubicTimingParameters(animationCurve: .easeOut)
            animator.continueAnimation(withTimingParameters: timing,
                                       durationFactor: 0)
            
            break
            
        default:
            break
        }
    }
    
    @IBAction func onTapGR(_ sender: UITapGestureRecognizer) {
        guard let recognizerView = sender.view else {
            return
        }
        
        guard let rootView = rootView else {
            return
        }
        
        if let animator = animator {
            animator.stopAnimation(true)
        }
        
        var destinationPoint = recognizerView.center
        let halfHeight = recognizerView.bounds.size.height / 2.0
        let maxY = rootView.bounds.maxY
        let newCenterMaxY = maxY + halfHeight - 80.0
        let newCenterMinY = maxY - halfHeight
        destinationPoint.y = rootView.expandedViewState == .expanded ? newCenterMaxY : newCenterMinY
        animator = UIViewPropertyAnimator(duration: 0.36,
                                          curve: .easeOut,
                                          animations:
            {
                recognizerView.center = destinationPoint
        })
        
        animator.addCompletion { (position) in
            switch position {
                case .end:
                    rootView.expandedViewState = rootView.expandedViewState == .collapsed ? .expanded : .collapsed
                break
                
            default:
                break
            }
        }
        
        let timing = UICubicTimingParameters(animationCurve: .easeOut)
        animator.continueAnimation(withTimingParameters: timing,
                                   durationFactor: 0)
        
        animator.startAnimation()
    }
    
}
