import SwiftUI

struct CaptionsDiscoverWorkbenchView: View {
    @State private var selectedSection: SectionType = .captions

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 14) {
                    Picker("Section", selection: $selectedSection) {
                        ForEach(SectionType.allCases, id: \.rawValue) { section in
                            Text(section.title).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(6)
                    .appSurface(radius: 12)
                    .padding(.horizontal, 16)

                    Group {
                        switch selectedSection {
                        case .captions:
                            MusicCaptionsView()
                        case .discover:
                            MusicNotesDiscoverView()
                        }
                    }
                }
            }
            .navigationTitle(selectedSection.navTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private enum SectionType: String, CaseIterable {
    case captions
    case discover

    var title: String {
        switch self {
        case .captions: return "Captions"
        case .discover: return "Discover"
        }
    }

    var navTitle: String {
        switch self {
        case .captions: return "Music Captions"
        case .discover: return "Discover Music Notes"
        }
    }
}
