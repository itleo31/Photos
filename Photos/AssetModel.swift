//
//  AssetModel.swift
//  PhotosSample
//
//  Created by Khanh Pham on 4/2/17.
//  Copyright © 2017 Khanh Pham. All rights reserved.
//

import Foundation

enum CollectionDataChange {
    case deleteItems([IndexPath])
    case deleteSections(IndexSet)
    case insertItems([IndexPath])
    case insertSections(IndexSet)
    case reloadItems([IndexPath])
    case reloadSections(IndexSet)
    case moveItems([(IndexPath, IndexPath)])
    case moveSections(Int, Int)
    
    case reloadAll
    
    var isReloadAll: Bool {
        if case CollectionDataChange.reloadAll = self {
            return true
        }
        return false
    }
    
    var order: Int {
        switch self {
        case .deleteItems: return 1
        case .deleteSections: return 2
        case .insertItems: return 3
        case .insertSections: return 4
        case .reloadItems: return 5
        case .reloadSections: return 6
        case .moveItems: return 7
        case .moveSections: return 8
        case .reloadAll: return 0
        }
    }
}

class MomentsCollection {
    private(set) var fetchResult: PHFetchResult<PHAssetCollection> {
        didSet {
            refreshCollectionArray()
        }
    }
    
    private var collections: [AssetCollection] = []
    
    init(fetchResult: PHFetchResult<PHAssetCollection>) {
        self.fetchResult = fetchResult
        refreshCollectionArray()
    }
    
    func reload(from fetchResult: PHFetchResult<PHAssetCollection>) {
        self.fetchResult = fetchResult
    }
    
    var collectionCount: Int {
        return collections.count
    }
    
    func collection(at: Int) -> AssetCollection {
        return collections[at]
    }
    
    var enumeratedCollections: EnumeratedSequence<[AssetCollection]> {
        return collections.enumerated()
    }
    
    private func refreshCollectionArray() {
        var collections = [AssetCollection]()
        fetchResult.enumerateObjects({ (collection, idx, _) in
            collections.append(collection.assetCollection)
        })
        self.collections = collections
    }
}

class AssetCollection {
    let phAssetCollection: PHAssetCollection
    let assetFetchResult: PHFetchResult<PHAsset>
    
    init(phAssetCollection: PHAssetCollection) {
        self.phAssetCollection = phAssetCollection
        self.assetFetchResult = PHAsset.fetchAssets(in: phAssetCollection, options: nil)
    }
    
    func asset(at: Int) -> Asset {
        return assetFetchResult.object(at: at).asset
    }
    
    var assetsCount: Int {
        return assetFetchResult.count
    }
}

private extension PHAssetCollection {
    var assetCollection: AssetCollection {
        return AssetCollection(phAssetCollection: self)
    }
}

class Asset {
    let phAsset: PHAsset
    
    fileprivate init(phAsset: PHAsset) {
        self.phAsset = phAsset
    }
    
    var title: String? {
        return phAsset.burstIdentifier
    }
    
    var isLivePhoto: Bool {
        return phAsset.mediaSubtypes.contains(.photoLive)
    }
}

private extension PHAsset {
    var asset: Asset {
        return Asset(phAsset: self)
    }
}
