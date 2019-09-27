import Photos
struct FetchedAlbumChangeDetails {
    let albumAfterChanges: FetchedAlbum?
    let assetCollectionChanges: PHObjectChangeDetails<PHAssetCollection>?
    let fetchResultChanges: PHFetchResultChangeDetails<PHAsset>?
    var albumWasDeleted: Bool {
        albumAfterChanges == nil
    }
}
extension PHChange {
    func changeDetails(for album: FetchedAlbum) -> FetchedAlbumChangeDetails? {
        let albumChanges = changeDetails(for: album.assetCollection)
        let assetChanges = changeDetails(for: album.fetchResult)
        let didChange = (albumChanges, assetChanges) != (nil, nil)
        let wasDeleted = albumChanges?.objectWasDeleted ?? false
        guard didChange else { return nil }
        let updatedAlbum: FetchedAlbum?
        if wasDeleted {
            updatedAlbum = nil
        } else {
            updatedAlbum = FetchedAlbum(assetCollection: albumChanges?.objectAfterChanges ?? album.assetCollection,
                                        fetchResult: assetChanges?.fetchResultAfterChanges ?? album.fetchResult)
        }
        return FetchedAlbumChangeDetails(albumAfterChanges: updatedAlbum, assetCollectionChanges: albumChanges, fetchResultChanges: assetChanges)
    }
}
