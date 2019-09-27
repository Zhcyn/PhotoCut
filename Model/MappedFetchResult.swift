import Photos
struct MappedFetchResult<P, M> where P: PHObject {
    let fetchResult: PHFetchResult<P>
    let array: [M]
    let map: (P) -> (M)
}
extension MappedFetchResult {
    init(fetchResult: PHFetchResult<P>, map: @escaping (P) -> (M)) {
        let array = enumerate(fetchResult: fetchResult, map: map)
        self.init(fetchResult: fetchResult, array: array, map: map)
    }
}
