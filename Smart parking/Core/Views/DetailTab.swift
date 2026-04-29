import Foundation

enum DetailTab: CaseIterable, Hashable {
    case about
    case gallery
    case review

    var title: String {
        let loc = LocalizationManager.shared
        switch self {
        case .about: return loc.str(.detailAbout)
        case .gallery: return loc.str(.detailGallery)
        case .review: return loc.str(.detailReview)
        }
    }
}
