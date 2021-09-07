//
//  VMProductViewController.swift
//  VMMushrooms
//
//  Created by Varvara Myronova on 1/16/19.
//  Copyright © 2019 Varvara Myronova. All rights reserved.
//

import UIKit

extension VMProductViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController)
        -> UIViewControllerAnimatedTransitioning?
    {
            if let selectedTwinFrame = selectedTwinFrame, let finalAnimationFrame = finalAnimationFrame, let selectedTwinView = selectedTwinView
            {
                return VMPresentTwinAnimationController(
                    originFrame: selectedTwinFrame,
                    finalFrame: finalAnimationFrame,
                    animationView: selectedTwinView)
            }
            
            return nil
    }
    
    func animationController(forDismissed dismissed: UIViewController)
      -> UIViewControllerAnimatedTransitioning?
    {
        if let dismissedVC = dismissed as? VMTwinViewController, let selectedTwinFrame = selectedTwinFrame, let originFrame = dismissedVC.originalAnimationFrame, let animationView = dismissedVC.animationView
        {
            return VMDismissTwinAnimationContoller(
                originFrame: originFrame,
                finalFrame: selectedTwinFrame,
                animationView: animationView,
                interactionController: dismissedVC.swipeInteractionController
            )
        }

        return nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
      -> UIViewControllerInteractiveTransitioning?
    {
      guard let animator = animator as? VMDismissTwinAnimationContoller,
        let interactionController = animator.interactionController,
        interactionController.interactionInProgress
        else {
            return nil
        }
        
        return interactionController
    }
}

class VMProductViewController: UIViewController,
                                             UIGestureRecognizerDelegate,
                                             UICollectionViewDelegate,
                                             UICollectionViewDataSource,
                                             UICollectionViewDelegateFlowLayout
{
    
    weak private var rootView: VMProductRootView? {
        return viewIfLoaded as? VMProductRootView
    }
    
    //MARK:- attributes for presentation TWIN Animation
    var selectedTwinFrame : CGRect?
    private var selectedTwinView  : VMTwinModelCollectionViewCell?
    
    private var finalAnimationFrame : CGRect? {
        if let rootView = rootView, let mushroomImagesCollectionView = rootView.mushroomImagesCollectionView {
            return mushroomImagesCollectionView.frame
        }
        
        return nil
    }
    
    //MARK:- attributes for TWIN Animation dismiss
    var mushroomModel: VMMushroomModel!
    var animator     : UIViewPropertyAnimator!
    
    
    //MARK:- Gesture Recognizers
    @IBOutlet var panGR: UIPanGestureRecognizer!
    @IBOutlet var tapGR: UITapGestureRecognizer!
    
    //MARK:- Constants
    let kVMTopDescriptionInsect     : CGFloat = 70.0
    let kVMMinInterItemSpacingPhoto : CGFloat = 4.0
    let kVMMinInterItemSpacingTwins : CGFloat = 4.0
    
    var kVMImageProportions : CGFloat {
        get {
            if let rootView = rootView, let collectionView = rootView.mushroomImagesCollectionView {
                return collectionView.bounds.size.width / collectionView.bounds.size.height
            }
            
            return 200.0 / 120.0
        }
    }
    
    //MARK:- View Life Cicle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let rootView = rootView {
            rootView.fillWithModel(model: mushroomModel)
        }
        
        if let navigationController = navigationController {
            if let interactivePopGestureRecognizer = navigationController.interactivePopGestureRecognizer {
                interactivePopGestureRecognizer.delegate = self
                interactivePopGestureRecognizer.isEnabled = true
            }
        }
    }
    
    //MARK:- Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? VMTwinViewController, segue.identifier == "showTwin" {
            if let cell = sender as? VMTwinModelCollectionViewCell, let model = cell.model, let identifier = model.identifier {
                destinationViewController.transitioningDelegate = self
                destinationViewController.model = VMTwinModel(identifier: identifier)
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return true
    }
    
    //MARK:- UICollectionViewDataSource
    func collectionView(_ collectionView                : UICollectionView,
                        numberOfItemsInSection section  : Int) -> Int
    {
        switch collectionView.tag {
        case 1:
            return mushroomModel.imagesCount
            
        case 2:
            return mushroomModel.twins.count
            
        default:
            return 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch collectionView.tag {
        case 1:
            return 1
            
        case 2:
            return 1
            
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView.tag {
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VMPhotoCollectionViewCell",
            for: indexPath) as! VMPhotoCollectionViewCell
            let index = indexPath.row + indexPath.section
            let images = self.mushroomModel.images
            
            if (images.count > index) {
                let image = self.mushroomModel.images[index]
                cell.fillWithImage(image: image)
            }
            
            return cell
            
        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VMTwinModelCollectionViewCell",
            for: indexPath) as! VMTwinModelCollectionViewCell
            let twinModel = self.mushroomModel.twins[indexPath.row]
            
            cell.fillWithModel(model: twinModel)
            
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    //MARK:- UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView.tag {
        case 1:
            //dismiss twin productView
            if let _ = collectionView.cellForItem(at: indexPath) as? VMPhotoCollectionViewCell {
                dismiss(animated: true, completion: nil)
            }
            
            break
            
        case 2:
            //show productView for twin mushroom
            if let selectedItem = collectionView.cellForItem(at: indexPath) as? VMTwinModelCollectionViewCell {
                if let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
                    let rect = collectionView.convert(attributes.frame, to: rootView)
                    selectedTwinFrame = rect
                    selectedTwinView = selectedItem
                    
                    performSegue(withIdentifier: "showTwin", sender: selectedTwinView)
                }
            }
            
            break
                
        default:
            break
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let rootView = rootView {
            rootView.pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        }
    }
    
    //MARK:- UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.bounds.size.height
        
        switch collectionView.tag {
        case 1:
            let width = collectionView.bounds.size.width - kVMMinInterItemSpacingPhoto
            return CGSize(width: width, height: height)
            
        case 2:
            let twinImageWidth = height * kVMImageProportions
            return CGSize(width: twinImageWidth, height: height)
            
        default:
            return CGSize.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        switch collectionView.tag {
        case 1:
            return 0.01
            
        case 2:
            return 0.01
            
        default:
            return 0.01
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch collectionView.tag {
        case 1:
            return kVMMinInterItemSpacingPhoto
            
        default:
            return kVMMinInterItemSpacingTwins
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    //MARK:- Interface Handling
    @IBAction func onPageControl(_ sender: UIPageControl) {
        scrollPhotosToItem(item: sender.currentPage)
    }
    
    //MARK:- Gesture recognizers
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
        let newCenterMaxY = maxY + halfHeight - kVMTopDescriptionInsect
        let newCenterMinY = maxY - halfHeight
        
        switch sender.state {
        case .began, .changed:
            destinationPoint.y += translation.y
            destinationPoint.y = min(max(destinationPoint.y, newCenterMinY), newCenterMaxY)
            recognizerView.center = destinationPoint
            sender.setTranslation(.zero, in: rootView)
            
        case .ended, .failed, .cancelled:
            destinationPoint.y = rootView.expandedViewState == .collapsed ? newCenterMinY : newCenterMaxY
            animator = UIViewPropertyAnimator(duration: 0.3,
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
            
            animator.startAnimation()
            
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
        let newCenterMaxY = maxY + halfHeight - kVMTopDescriptionInsect
        let newCenterMinY = maxY - halfHeight
        
        switch rootView.expandedViewState {
        case .expanded:
            destinationPoint.y = newCenterMaxY
            break
            
        case .collapsed:
            destinationPoint.y = newCenterMinY
            
            break
        }
        
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
        
        animator.startAnimation()
    }
    
    //MARK:- Private
    private func scrollPhotosToItem(item: Int) {
        if let rootView = rootView, let collectionView = rootView.mushroomImagesCollectionView {
            let indexPath = IndexPath(row: item, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
}
