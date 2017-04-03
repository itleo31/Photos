//
//  UIKitExt.swift
//  PhotosSample
//
//  Created by Khanh Pham on 4/2/17.
//  Copyright © 2017 Khanh Pham. All rights reserved.
//

import UIKit

extension UIViewController {
    var isVisible: Bool {
        return isViewLoaded && view.window != nil
    }
}

extension UICollectionView {
    func performBatchUpdates(with changes: [CollectionDataChange], completion: ((Void) -> Void)? = nil) {
        if changes.isEmpty { return }
        
        if changes.contains(where: { $0.isReloadAll }) {
            self.reloadData()
            completion?()
            return
        }
        
        self.performBatchUpdates({
            changes.sorted(by: { $0.order < $1.order }).forEach { change in
                switch change {
                case let .deleteItems(indexPaths):
                    self.deleteItems(at: indexPaths)
                case let .deleteSections(sections):
                    self.deleteSections(sections)
                case let .insertItems(indexPaths):
                    self.insertItems(at: indexPaths)
                case let .insertSections(sections):
                    self.insertSections(sections)
                case let .reloadItems(indexPaths):
                    self.reloadItems(at: indexPaths)
                case let .reloadSections(sections):
                    self.reloadSections(sections)
                case let .moveItems(indexPathPairs):
                    indexPathPairs.forEach { self.moveItem(at: $0, to: $1) }
                case let .moveSections(fromSection, toSection):
                    self.moveSection(fromSection, toSection: toSection)
                case .reloadAll:    break   // If reloadAll, we already triggered reload above
                }
            }
        }, completion: { _ in
            completion?()
        })
    }
}

extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
    
    func reloadDataThenScrollToBottom() {
        // Reload UI
        DispatchQueue.main.async {
            self.reloadData()
            DispatchQueue.main.async {
                // Make sure scrolling triggers after reloading data
                // And if the content fits in the current view, do not scroll to bottom
                if self.contentSize.height > self.frame.height {
                    let bottomOffset = CGPoint(x: 0, y: self.contentSize.height - self.bounds.height)
                    self.setContentOffset(bottomOffset, animated: false)
                }
            }
        }
    }
}
