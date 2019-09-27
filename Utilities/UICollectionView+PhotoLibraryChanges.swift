import UIKit
import Photos
extension UICollectionView {
    func applyPhotoLibraryChanges<T>(for changes: PHFetchResultChangeDetails<T>, in section: Int = 0, cellConfigurator: (IndexPath) -> ()) {
        guard changes.hasIncrementalChanges else {
            reloadData()
            return
        }
        performBatchUpdates({
            if let removed = changes.removedIndexes, !removed.isEmpty {
                deleteItems(at: removed.indexPaths(in: section))
            }
            if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                insertItems(at: inserted.indexPaths(in: section))
            }
        })
        performBatchUpdates({
            changes.enumerateMoves { from, to in
                self.moveItem(at: IndexPath(item: from, section: section),
                              to: IndexPath(item: to, section: section))
            }
        })
        if let changed = changes.changedIndexes, !changed.isEmpty {
            changed.indexPaths(in: section).forEach(cellConfigurator)
        }
    }
}
extension IndexSet {
    func indexPaths(in section: Int = 0) -> [IndexPath] {
        map { IndexPath(item: $0, section: section) }
    }
}
