enum ImageFormat: String {
    case heif = "public.heic"  
    case jpg = "public.jpeg"
}
extension ImageFormat: Equatable, Codable { }
extension ImageFormat {
    var displayString: String {
        switch self {
        case .heif: return "HEIF"
        case .jpg: return "JPG"
        }
    }
}
