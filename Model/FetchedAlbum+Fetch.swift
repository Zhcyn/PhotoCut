import Photos
extension FetchedAlbum {
    static func fetchAssets(in assetCollection: PHAssetCollection, options: PHFetchOptions? = nil) -> FetchedAlbum {
        let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: options)
        return FetchedAlbum(assetCollection: assetCollection, fetchResult: fetchResult)
    }
    static func fetchUpdate(for assetCollection: PHAssetCollection, assetFetchOptions: PHFetchOptions? = nil) -> FetchedAlbum? {
        let id = assetCollection.localIdentifier
        guard let updatedCollection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil).firstObject else {
            return nil
        }
        return fetchAssets(in: updatedCollection, options: assetFetchOptions)
    }
    static func fetchSmartAlbums(with types: [PHAssetCollectionSubtype], assetFetchOptions: PHFetchOptions? = nil) -> [FetchedAlbum] {
        PHAssetCollection.fetchSmartAlbums(with: types)
            .map { fetchAssets(in: $0, options: assetFetchOptions) }
    }
}
