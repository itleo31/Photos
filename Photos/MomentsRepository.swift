//
//  MomentsRepository.swift
//  PhotosSample
//
//  Created by Khanh Pham on 4/2/17.
//  Copyright © 2017 Khanh Pham. All rights reserved.
//

import Foundation
import UIKit

enum PhotoError: Error {
    case failedToLoad
    case unknown
}

class MomentsRepository: NSObject, PHPhotoLibraryChangeObserver {
    
    static let shared = MomentsRepository()
    
    let momentsCollection = Variable<MomentsCollection?>(nil)
    
    // TODO: This CollectionDataChange like UI stuff. Should refactor
    let changes = Variable<[CollectionDataChange]>([])
    private let photoLibrary = PHPhotoLibrary.shared()
    private let imageManager = PHCachingImageManager()
    private let changeQueue = DispatchQueue(label: "com.khanhpham.PhotosSample.photosChangeQueue")
    private let fetchQueue = DispatchQueue(label: "com.khanhpham.PhotosSample.photosFetchQueue")
    
    override init() {
        super.init()
        photoLibrary.register(self)
    }
    
    deinit {
        photoLibrary.unregisterChangeObserver(self)
    }
    
    // MARK: - Fetching
    
    func fetch() {
        let fetchResult = PHAssetCollection.fetchMoments(with: nil)
        momentsCollection.value = MomentsCollection(fetchResult: fetchResult)
        
        
    }
    
    func requestImage(for asset: Asset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?) -> Observable<UIImage> {
        return Observable.create { (observer) -> Disposable in
            self.fetchQueue.async {
                self.imageManager.requestImage(for: asset.phAsset, targetSize: targetSize, contentMode: contentMode, options: options) { (image, _) in
                    if let image = image {
                        observer.onNext(image)
                        observer.onCompleted()
                    } else {
                        observer.onError(PhotoError.failedToLoad)
                    }
                }
            }
            return Disposables.create()
        }
        
    }
    
    // MARK: - Updating
    
    func delete(image: Asset, inCollection c: AssetCollection) -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
            
            self.photoLibrary.performChanges({
                let imagesToDelete = NSArray(array: [image.phAsset])
                PHAssetChangeRequest.deleteAssets(imagesToDelete)
            }, completionHandler: { (success, error) in
                if success {
                    observer.onNext(())
                    observer.onCompleted()
                } else if let error = error {
                    observer.onError(error)
                } else {
                    observer.onError(PhotoError.unknown)
                }
            })
            
            return Disposables.create()
        }
    }
    
    // MARK: - Caching
    
    func stopCachingImagesForAllAssets() {
        imageManager.stopCachingImagesForAllAssets()
    }
    
    func startCachingImages(for assets: [PHAsset], targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?) {
        imageManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: contentMode, options: options)
    }
    
    func stopCachingImages(for assets: [PHAsset], targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?) {
        imageManager.stopCachingImages(for: assets, targetSize: targetSize, contentMode: contentMode, options: options)
    }
    
    // MARK: - Observe changes
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let collection = momentsCollection.value {
            changeQueue.sync {
                guard let changes = changeInstance.changeDetails(for: collection.fetchResult) else {
                    return
                }
                
                collection.reload(from: changes.fetchResultAfterChanges)
                if changes.hasIncrementalChanges {
                    if let changed = changes.changedIndexes {
                        var shouldReload = false
                        if let removed = changes.removedIndexes, !removed.isEmpty, changed.hasIntersect(with: removed) {
                            shouldReload = true
                        } else if let inserted = changes.insertedIndexes, !inserted.isEmpty,changed.hasIntersect(with: inserted) {
                            shouldReload = true
                        } else {
                            changes.enumerateMoves({ (from, to) in
                                if changed.contains(from) || changed.contains(to) {
                                    shouldReload = true
                                }
                            })
                        }
                        if shouldReload {
                            self.changes.value = [CollectionDataChange.reloadAll]
                            return
                        }
                    }
                    
                    
                    // For indexes to make sense, updates must be in this order:
                    // delete, insert, reload, move
                    var dataChanges = [CollectionDataChange]()
                    if let removed = changes.removedIndexes, !removed.isEmpty {
                        dataChanges.append(CollectionDataChange.deleteSections(removed))
                    }
                    if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                        dataChanges.append(CollectionDataChange.insertSections(inserted))
                    }
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        dataChanges.append(CollectionDataChange.reloadSections(changed))
                    }
                    
                    changes.enumerateMoves { fromIndex, toIndex in
                        dataChanges.append(CollectionDataChange.moveSections(fromIndex, toIndex))
                    }
                    
                    self.changes.value = dataChanges
                } else {
                    self.changes.value = [CollectionDataChange.reloadAll]
                }
            }
        } else {
            fetch()
        }
        
    }
}
