import Foundation

enum AppTab: String, CaseIterable {
    case home
    case gallery
    case workbench
    case stats
    case settings

    var title: String {
        switch self {
        case .home: return "Home"
        case .gallery: return "Gallery"
        case .workbench: return "Tools"
        case .stats: return "Stats"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .gallery: return "music.note.list"
        case .workbench: return "square.stack.3d.up"
        case .stats: return "chart.bar.xaxis"
        case .settings: return "gearshape"
        }
    }
}
