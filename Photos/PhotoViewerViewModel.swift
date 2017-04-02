//
//  PhotoViewerViewModel.swift
//  PhotosSample
//
//  Created by Khanh Pham on 4/2/17.
//  Copyright © 2017 Khanh Pham. All rights reserved.
//

import Foundation

enum PhotoViewerViewModelError: Error {
    case assetEmpty
}

class PhotoViewerViewModel: NSObject {
    
    var collection: MomentsCollection!
    let momentsRepo = MomentsRepository.shared
    
    var currentIndex: Int = -1
    
    var currentAsset: Asset? {
        return asset(at: currentIndex)
    }
    
    func asset(at idx: Int) -> Asset? {
        if currentIndex < 0 {
            return nil
        }
        
        var tempCount = 0
        for colIdx in 0..<collection.collectionCount {
            if tempCount + collection.collection(at: colIdx).assetsCount > idx {
                return collection.collection(at: colIdx).asset(at: idx - tempCount)
            } else {
                tempCount = tempCount + collection.collection(at: colIdx).assetsCount
            }
        }
        return nil
    }
    
    func loadCurrentAsset() -> Observable<UIImage> {
        guard let asset = currentAsset else { return Observable.error(PhotoViewerViewModelError.assetEmpty) }
        
        let scale = UIScreen.main.scale
        let size = UIScreen.main.bounds.size
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        return momentsRepo.requestImage(for: asset, targetSize: targetSize, contentMode: PHImageContentMode.aspectFit, options: options)
    }
    
    func convertToIndex(from indexPath: IndexPath) -> Int {
        var tempCount = 0
        for colIdx in 0..<indexPath.section {
            tempCount = tempCount + collection.collection(at: colIdx).assetsCount
        }
        
        return tempCount + indexPath.item
    }
    
}
