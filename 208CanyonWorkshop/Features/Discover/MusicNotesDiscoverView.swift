import SwiftUI

struct MusicNotesDiscoverView: View {
    @EnvironmentObject private var store: AppStorageStore
    @StateObject private var viewModel = MusicNotesDiscoverViewModel()

    private let columns: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppBackgroundView()

            if store.lastVisitedDate == nil {
                firstLaunchState
            } else if viewModel.filteredCollections.isEmpty {
                emptyState
            } else {
                ScrollView {
                    AppSectionTitle(
                        title: "Curated Collections",
                        subtitle: "Tap cards to open details or long-swipe for quick actions."
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    HStack(spacing: 10) {
                        AppCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                Text("\(viewModel.filteredCollections.count)")
                                    .font(.title3.bold())
                                    .foregroundStyle(Color("AppTextPrimary"))
                            }
                        }
                        AppCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Favorited")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                Text("\(store.favourites.filter { !$0.hasPrefix("note_") }.count)")
                                    .font(.title3.bold())
                                    .foregroundStyle(Color("AppTextPrimary"))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.filteredCollections) { collection in
                            NavigationLink {
                                discoverDetail(collection)
                            } label: {
                                card(for: collection)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button {
                                    FeedbackService.tap()
                                    store.toggleFavourite(collectionId: collection.id)
                                } label: {
                                    Text(store.favourites.contains(collection.id) ? "Unfavourite" : "Favourite")
                                }
                                .tint(Color("AppPrimary"))
                            }
                        }
                    }
                    .padding(16)
                }
            }

            favouriteButton
                .padding(.trailing, 18)
                .padding(.bottom, 20)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    FeedbackService.tap()
                    viewModel.showSearchSheet = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $viewModel.showSearchSheet) {
            searchSheet
                .presentationDetents([.fraction(0.35)])
        }
        .overlay {
            SuccessBadgeOverlay(isVisible: $viewModel.showSuccessBadge)
        }
    }

    private var firstLaunchState: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 64))
                    .foregroundStyle(Color("AppAccent"))
                Text("Explore curated notes to start your journey")
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button("Explore Collections") {
                    FeedbackService.tap()
                    store.markDiscoverVisited()
                }
                .appPrimaryButton()
            }
            .frame(maxWidth: .infinity, minHeight: 320)
            .padding(.top, 40)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "music.note.list")
                .font(.system(size: 56))
                .foregroundStyle(Color("AppAccent"))
            Text("Start exploring curated collections!")
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(.top, 40)
    }

    private var favouriteButton: some View {
        Button {
            FeedbackService.tap()
            viewModel.saveSelected(using: store)
        } label: {
            Text("Favourite")
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(AppDesign.primaryGradient, in: Capsule())
                .overlay(Capsule().stroke(Color("AppAccent").opacity(0.45), lineWidth: 1))
                .modifier(AppShadowModifier(enabled: true, radius: 6, y: 3))
        }
        .disabled(viewModel.selectedIds.isEmpty)
        .opacity(viewModel.selectedIds.isEmpty ? 0.55 : 1.0)
    }

    private func card(for collection: DiscoverCollection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppDesign.cardGradient)
                .overlay(
                    Image(systemName: collection.symbol)
                        .font(.system(size: 30))
                        .foregroundStyle(Color("AppAccent"))
                )
                .frame(height: 86)

            Text(collection.title)
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(2)

            Text(collection.description)
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(3)

            HStack {
                Spacer()
                Image(systemName: store.favourites.contains(collection.id) ? "heart.fill" : "heart")
                    .foregroundStyle(Color("AppAccent"))
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    viewModel.selectedIds.contains(collection.id)
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [Color("AppPrimary").opacity(0.45), Color("AppAccent").opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    : AnyShapeStyle(AppDesign.cardGradient)
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color("AppAccent").opacity(0.4), lineWidth: 1)
        )
        .onTapGesture {
            FeedbackService.tap()
            viewModel.toggleSelected(collection.id)
        }
    }

    private var searchSheet: some View {
        NavigationStack {
            Form {
                Section("Search collections") {
                    TextField("Search", text: $viewModel.query)
                        .textInputAutocapitalization(.never)
                    Button("Save Search") {
                        FeedbackService.tap()
                        store.registerSearch(viewModel.query)
                    }
                }
                .listRowBackground(Color("AppSurface"))

                if !store.searchHistory.isEmpty {
                    Section("Recent searches") {
                        ForEach(store.searchHistory, id: \.self) { item in
                            Button(item) {
                                FeedbackService.tap()
                                viewModel.query = item
                            }
                            .foregroundStyle(Color("AppTextPrimary"))
                        }
                    }
                    .listRowBackground(Color("AppSurface"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .navigationTitle("Search")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        FeedbackService.tap()
                        viewModel.showSearchSheet = false
                    }
                }
            }
        }
    }

    private func discoverDetail(_ collection: DiscoverCollection) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(collection.title)
                    .font(.title3.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(collection.description)
                    .foregroundStyle(Color("AppTextSecondary"))
                Button(store.favourites.contains(collection.id) ? "Unfavourite" : "Favourite") {
                    FeedbackService.tap()
                    store.toggleFavourite(collectionId: collection.id)
                    FeedbackService.softFavourite()
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .appPrimaryButton()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .background(AppBackgroundView())
        .navigationTitle("Collection")
        .navigationBarTitleDisplayMode(.inline)
    }
}
