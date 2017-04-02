//
//  MomentsViewController.swift
//  Photos
//
//  Created by Khanh Pham on 4/2/17.
//  Copyright © 2017 Khanh Pham. All rights reserved.
//

import UIKit

private let PhotoCellIdentifier = "PhotoGridCell"
private let PhotoHeaderIdentifier = "PhotoGridSectionHeader"

class MomentsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let momentsRepo = MomentsRepository.shared
    private let rxBag = DisposeBag()
    
    private var collection: MomentsCollection?
    private var cellSize = CGSize(width: 80, height: 80) {
        didSet {
            let scale = UIScreen.main.scale
            thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        }
    }
    private var thumbnailSize: CGSize = CGSize(width: 80, height: 80)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupBinding()
        fetchCollection()
        invalidateLayout()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        invalidateLayout()
    }
    
    private func invalidateLayout() {
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        
        let padding: CGFloat = 1
        let columns: Int
        if UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) {
            columns = 7
        } else {
            columns = 4
        }
        let cellWidth = (collectionView.frame.size.width - CGFloat(columns - 1) * padding) / CGFloat(columns)
        cellSize = CGSize(width: cellWidth, height: cellWidth)
        
        flowLayout.itemSize = cellSize
        flowLayout.invalidateLayout()
    }
    
    private func setupView() {
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.sectionHeadersPinToVisibleBounds = true
        }
    }
    
    private func setupBinding() {
        momentsRepo
            .momentsCollection
            .asObservable()
            .throttle(0.2, scheduler: MainScheduler.instance)
            .bindNext { [unowned self] (collection) in
                self.collection = collection
                self.collectionView.reloadDataThenScrollToBottom()
            }
            .addDisposableTo(rxBag)
        
        momentsRepo
            .changes
            .asObservable()
            .delay(2, scheduler: MainScheduler.instance)
            .bindNext { [unowned self] (changes) in
                self.collectionView.performBatchUpdates(with: changes)
            }
            .addDisposableTo(rxBag)
    }
    
    private func fetchCollection() {
        momentsRepo.fetch()
    }

    // MARK: - CollectionView
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collection?.collectionCount ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let collection = collection else { return 0 }
        return collection.collection(at: section).assetsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCellIdentifier, for: indexPath) as! PhotoGridCell
        
        if let collection = collection {
            let asset = collection.collection(at: indexPath.section).asset(at: indexPath.item)
            cell.liveImageView.isHidden = !asset.isLivePhoto
            cell.liveImageView.image = Constants.livePhotoIcon
            cell.localIdentifier = asset.phAsset.localIdentifier
            
            // TODO: OperationQueue to optimise loading
            momentsRepo.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill)
                .observeOnMain()
                .bindNext { (image) in
                    if cell.localIdentifier == asset.phAsset.localIdentifier {
                        cell.photoImageView.image = image
                    }
                }
                .addDisposableTo(rxBag)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let collection = collection, kind == UICollectionElementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PhotoHeaderIdentifier, for: indexPath) as! PhotoGridSectionHeader
        
        let assetCollection = collection.collection(at: indexPath.section)
        
        view.textLabel?.text = assetCollection.title
        
        return view
    }
    
    // MARK: - Caching
    
    private var previousPreheatRect = CGRect.zero
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    private func resetCachedAssets() {
        momentsRepo.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    private func updateCachedAssets() {
        // Update only if the view is visible.
        guard let collection = collection, isViewLoaded && view.window != nil else { return }
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in collection.collection(at: indexPath.section).asset(at: indexPath.item).phAsset }
        let removedAssets = removedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in collection.collection(at: indexPath.section).asset(at: indexPath.item).phAsset }
        
        // Update the assets the PHCachingImageManager is caching.
        momentsRepo.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        momentsRepo.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        
        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
    
}

// MARK: - Header and Cell

class PhotoGridSectionHeader: UICollectionReusableView {
    
    @IBOutlet weak var textLabel: UILabel!
    
}

class PhotoGridCell: UICollectionViewCell {
 
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var liveImageView: UIImageView!
    
    var localIdentifier: String?
    
}

extension AssetCollection {
    var title: String? {
        if phAssetCollection.localizedTitle.isNotEmpty {
            return phAssetCollection.localizedTitle
        }
        
        if let date = phAssetCollection.startDate ?? phAssetCollection.endDate {
            return dayFormatter.string(from: date)
        }
        
        return phAssetCollection.localizedLocationNames.first
    }
    
}





