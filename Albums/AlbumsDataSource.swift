import Photos
class AlbumsDataSource: NSObject, PHPhotoLibraryChangeObserver {
    static let defaultSmartAlbumTypes: [PHAssetCollectionSubtype] =
        [.smartAlbumVideos, .smartAlbumFavorites, .smartAlbumTimelapses, .smartAlbumSlomoVideos]
    var smartAlbumsChangedHandler: (([Album]) -> ())?
    var userAlbumsChangedHandler: (([Album]) -> ())?
    private(set) var smartAlbums = [FetchedAlbum]() {
        didSet {
            guard smartAlbums != oldValue else { return }
            smartAlbumsChangedHandler?(smartAlbums)
        }
    }
    private(set) var userAlbums = [StaticAlbum]() {
        didSet { userAlbumsChangedHandler?(userAlbums) }
    }
    private var userAlbumsFetchResult: MappedFetchResult<PHAssetCollection, StaticAlbum>!  {
        didSet { userAlbums = userAlbumsFetchResult.array.filter { !$0.isEmpty } }
    }
    private let updateQueue: DispatchQueue
    private let photoLibrary: PHPhotoLibrary
    init(smartAlbumTypes: [PHAssetCollectionSubtype] = AlbumsDataSource.defaultSmartAlbumTypes,
         smartAlbumAssetFetchOptions: PHFetchOptions = .smartAlbumVideos(),
         userAlbumFetchOptions: PHFetchOptions = .userAlbums(),
         userAlbumAssetFetchOptions: PHFetchOptions = .userAlbumVideos(),
         updateQueue: DispatchQueue = .init(label: String(describing: AlbumsDataSource.self), qos: .userInitiated),
         photoLibrary: PHPhotoLibrary = .shared()) {
        self.updateQueue = updateQueue
        self.photoLibrary = photoLibrary
        super.init()
        photoLibrary.register(self)
        initSmartAlbums(with: smartAlbumTypes, assetFetchOptions: smartAlbumAssetFetchOptions)
        initUserAlbums(with: userAlbumFetchOptions, assetFetchOptions: userAlbumAssetFetchOptions)
    }
    deinit {
        photoLibrary.unregisterChangeObserver(self)
    }
    func photoLibraryDidChange(_ change: PHChange) {
        updateSmartAlbums(with: change)
        updateUserAlbums(with: change)
    }
}
private extension AlbumsDataSource {
    func initSmartAlbums(with types: [PHAssetCollectionSubtype], assetFetchOptions: PHFetchOptions) {
        updateQueue.async { [weak self] in
            let smartAlbums = FetchedAlbum.fetchSmartAlbums(with: types, assetFetchOptions: assetFetchOptions)
            DispatchQueue.main.sync {
                self?.smartAlbums = smartAlbums
            }
        }
    }
    func updateSmartAlbums(with change: PHChange) {
        updateQueue.async { [weak self] in
            guard let self = self else { return }
            let smartAlbums = DispatchQueue.main.sync {
                self.smartAlbums
            }
            let updatedAlbums: [FetchedAlbum] = smartAlbums.compactMap {
                let changes = change.changeDetails(for: $0)
                return (changes == nil) ? $0 : changes!.albumAfterChanges
            }
            DispatchQueue.main.sync {
                self.smartAlbums = updatedAlbums
            }
        }
    }
    func initUserAlbums(with albumFetchOptions: PHFetchOptions, assetFetchOptions: PHFetchOptions) {
        updateQueue.async { [weak self] in
            let fetchResult = PHAssetCollection.fetchUserAlbums(with: albumFetchOptions)
            let userAlbums = MappedFetchResult(fetchResult: fetchResult) {
                StaticAlbum(album: FetchedAlbum.fetchAssets(in: $0, options: assetFetchOptions))
            }
            DispatchQueue.main.sync {
                self?.userAlbumsFetchResult = userAlbums
            }
        }
    }
    func updateUserAlbums(with change: PHChange) {
        updateQueue.async { [weak self] in
            guard let self = self else { return }
            let userAlbums = DispatchQueue.main.sync {
                self.userAlbumsFetchResult!
            }
            guard let changes = change.changeDetails(for: userAlbums.fetchResult) else { return }
            let updatedAlbums = applyIncrementalChanges(changes, to: userAlbums)
            DispatchQueue.main.sync {
                self.userAlbumsFetchResult = updatedAlbums
            }
        }
    }
}
