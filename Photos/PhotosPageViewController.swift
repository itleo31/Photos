//
//  PhotosPageViewController.swift
//  PhotosSample
//
//  Created by Khanh Pham on 4/3/17.
//  Copyright © 2017 Khanh Pham. All rights reserved.
//

import UIKit

class PhotosPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    let viewModel = PhotosPageViewModel()
    
    let rxBag = DisposeBag()
    
    var didLoad = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if didLoad { return }
        didLoad = true
        
        let vc = self.photoViewController(at: viewModel.currentIndex)
        setViewControllers([vc], direction: .forward, animated: false, completion: nil)
    }
    
    
    @IBAction func didTapBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapDelete(_ sender: Any) {
        viewModel.deleteAsset(at: viewModel.currentIndex)
            .observeOnMain()
            .subscribe(onError: { (err) in
                log("\(err)")
            }, onCompleted: { [unowned self] in
                self.handleAfterDeleteAsset()
            })
            .addDisposableTo(rxBag)
        
    }
    
    private func handleAfterDeleteAsset() {
        // TODO: Need to move forward or backward
        dismiss(animated: true, completion: nil)
    }
    
    private func setup() {
        dataSource = self
        delegate = self
        view.backgroundColor = .white
    }
    
    func setCurrentIndex(_ index: IndexPath, inCollection c: MomentsCollection) {
        viewModel.collection = c
        viewModel.currentIndex = viewModel.convertToIndex(from: index)
        
    }
    
    private func photoViewController(at index: Int) -> PhotoViewerViewController {
        let vc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoViewerViewController") as! PhotoViewerViewController
        vc.index = index
        
        viewModel
            .loadAsset(at: index)
            .observeOnMain()
            .bindNext { (image) in
                vc.image = image
            }
            .addDisposableTo(rxBag)
        return vc
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - PageViewController

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currVC = viewController as? PhotoViewerViewController else { return nil }
        
        let idx = currVC.index + 1
        if !viewModel.hasAsset(at: idx) {
            return nil
        }
        return photoViewController(at: idx)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currVC = viewController as? PhotoViewerViewController else { return nil }
        let idx = currVC.index - 1
        if !viewModel.hasAsset(at: idx) {
            return nil
        }
        return photoViewController(at: idx)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if !completed { return }
        if let vc = viewControllers?.first as? PhotoViewerViewController {
            viewModel.currentIndex = vc.index
        }
    }

}
