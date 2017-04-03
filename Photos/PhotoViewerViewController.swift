//
//  PhotoViewerViewController.swift
//  PhotosSample
//
//  Created by Khanh Pham on 4/2/17.
//  Copyright © 2017 Khanh Pham. All rights reserved.
//

import UIKit

class PhotoViewerViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var imageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageStopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet var singleTapGesture: UITapGestureRecognizer!
    @IBOutlet var doubleTapGesture: UITapGestureRecognizer!
    
    var image: UIImage! {
        didSet {
            if imageView != nil {
                loadImage()
            }
        }
    }
    
    var index: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadImage()
    }
    
    private func loadImage() {
        imageView.image = image
        view.setNeedsLayout()
        view.layoutIfNeeded()
        updateMinZoomScale(forSize: view.bounds.size)
        updateConstraints(forSize: view.bounds.size)
    }
    
    private func setup() {
        imageView.image = nil
        singleTapGesture.require(toFail: doubleTapGesture)
    }
    
    @IBAction func didDoubleTap(_ sender: UITapGestureRecognizer) {
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }
    
    @IBAction func didTapScrollView(_ sender: Any) {
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateMinZoomScale(forSize: view.bounds.size)
    }
    
    // MARK: - ScrollView
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraints(forSize: view.bounds.size)
    }
    
    // MARK: - Sizing
    
    private func updateMinZoomScale(forSize size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)
        
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
    }
    
    private func updateConstraints(forSize size: CGSize) {
        
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        imageStopConstraint.constant = yOffset
        imageBottomConstraint.constant = yOffset
        
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        imageLeadingConstraint.constant = xOffset
        imageTrailingConstraint.constant = xOffset
        
        view.layoutIfNeeded()
    }
    
}

extension Asset {
    var title: String? {
        if let date = phAsset.creationDate {
            return dayFormatter.string(from: date)
        }
        
        return nil
    }
}
