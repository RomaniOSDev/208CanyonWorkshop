import SwiftUI
import UIKit

struct AnnotationGalleryView: View {
    @EnvironmentObject private var store: AppStorageStore
    @StateObject private var viewModel = AnnotationGalleryViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 0) {
                    filterPanel

                    let visibleAnnotations = viewModel.filteredAnnotations(using: store)

                    if visibleAnnotations.isEmpty {
                        emptyState
                    } else {
                        quickStatsBar
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        List {
                            ForEach(visibleAnnotations) { annotation in
                                Group {
                                    if viewModel.isBulkMode {
                                        Button {
                                            FeedbackService.tap()
                                            viewModel.toggleBulkSelection(annotation.id)
                                        } label: {
                                            cardContent(annotation: annotation)
                                        }
                                    } else {
                                        NavigationLink {
                                            annotationDetail(annotation)
                                        } label: {
                                            cardContent(annotation: annotation)
                                        }
                                    }
                                }.buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) {
                                        FeedbackService.tap()
                                        viewModel.delete(annotationId: annotation.id, store: store)
                                    }
                                    Button("Edit") {
                                        FeedbackService.tap()
                                        viewModel.startEditing(annotation)
                                    }
                                    .tint(Color("AppPrimary"))
                                    Button(store.isNoteFavourite(annotationId: annotation.id) ? "Unfavorite" : "Favorite") {
                                        FeedbackService.tap()
                                        store.toggleNoteFavourite(annotationId: annotation.id)
                                    }
                                    .tint(Color("AppAccent"))
                                    Button(annotation.isPinned ? "Unpin" : "Pin") {
                                        FeedbackService.tap()
                                        store.toggleAnnotationPinned(annotationId: annotation.id)
                                    }
                                    .tint(Color("AppPrimary"))
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }

                }
                .navigationTitle("My Annotations")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(viewModel.isBulkMode ? "Done" : "Select") {
                            FeedbackService.tap()
                            viewModel.isBulkMode ? viewModel.stopBulkMode() : (viewModel.isBulkMode = true)
                        }
                    }
                }

                SuccessBadgeOverlay(isVisible: $viewModel.showSuccessBadge)
                floatingAddButton
                undoSnackbar
            }
        }
        .sheet(isPresented: $viewModel.isEditorPresented) {
            editorSheet
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            ActivitySheet(text: viewModel.exportPayload)
        }
        .onAppear {
            viewModel.loadFilters(from: store)
        }
        .onChange(of: viewModel.searchText) { _ in
            viewModel.saveFiltersToStore(store)
        }
        .onChange(of: viewModel.filterFavoritesOnly) { _ in
            viewModel.saveFiltersToStore(store)
        }
        .onChange(of: viewModel.filterLast7Days) { _ in
            viewModel.saveFiltersToStore(store)
        }
    }

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 62))
                    .foregroundStyle(Color("AppAccent"))
                Text("No annotations yet! Start capturing your musical thoughts today.")
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            .frame(maxWidth: .infinity, minHeight: 350)
            .padding(.top, 44)
        }
    }

    private var quickStatsBar: some View {
        HStack(spacing: 10) {
            AppCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pinned")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                    Text("\(store.annotations.filter(\.isPinned).count)")
                        .font(.title3.bold())
                        .foregroundStyle(Color("AppTextPrimary"))
                }
            }
            AppCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Favorites")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                    Text("\(store.favourites.filter { $0.hasPrefix("note_") }.count)")
                        .font(.title3.bold())
                        .foregroundStyle(Color("AppTextPrimary"))
                }
            }
            AppCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shown")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                    Text("\(viewModel.filteredAnnotations(using: store).count)")
                        .font(.title3.bold())
                        .foregroundStyle(Color("AppTextPrimary"))
                }
            }
        }
    }

    private var filterPanel: some View {
        VStack(spacing: 10) {
            AppSearchField(placeholder: "Search title, text, artist", text: $viewModel.searchText)

            HStack(spacing: 10) {
                filterChip(title: "Favorites only", isActive: $viewModel.filterFavoritesOnly)
                filterChip(title: "Last 7 days", isActive: $viewModel.filterLast7Days)
                if viewModel.isBulkMode {
                    Button {
                        FeedbackService.tap()
                        viewModel.favouriteSelected(using: store)
                    } label: {
                        Text("Favorite").appChip(active: true)
                    }

                    Button {
                        FeedbackService.tap()
                        viewModel.exportSelected(using: store)
                    } label: {
                        Text("Export").appChip(active: true)
                    }

                    Button {
                        FeedbackService.tap()
                        viewModel.deleteBulk(store: store)
                    } label: {
                        Text("Delete")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .appSurface(radius: 20)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            let tags = Array(Set(store.annotations.flatMap(\.tags))).sorted()
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            FeedbackService.tap()
                            viewModel.selectedTagFilter = "All Tags"
                        } label: {
                            Text("All Tags")
                                .appChip(active: viewModel.selectedTagFilter == "All Tags")
                        }
                        ForEach(tags, id: \.self) { tag in
                            Button {
                                FeedbackService.tap()
                                viewModel.selectedTagFilter = tag
                            } label: {
                                Text(tag.replacingOccurrences(of: "mood:", with: "Mood: ").replacingOccurrences(of: "genre:", with: "Genre: ").replacingOccurrences(of: "activity:", with: "Activity: "))
                                    .appChip(active: viewModel.selectedTagFilter == tag)
                            }
                        }
                    }
                }
            }
        }
        .appPanel(radius: 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    private func filterChip(title: String, isActive: Binding<Bool>) -> some View {
        Button {
            FeedbackService.tap()
            isActive.wrappedValue.toggle()
        } label: {
            Text(title)
                .appChip(active: isActive.wrappedValue)
        }
    }

    private var editorSheet: some View {
        NavigationStack {
            Form {
                Section("Song Info") {
                    TextField("Song title", text: $viewModel.titleInput)
                        .modifier(ShakeEffect(animatableData: viewModel.shakeTrigger))
                    TextField("Artist", text: $viewModel.artistInput)
                        .modifier(ShakeEffect(animatableData: viewModel.shakeTrigger))
                    TextField("Emoji icon", text: $viewModel.iconInput)
                }
                .listRowBackground(Color("AppSurface"))

                Section("Annotation") {
                    TextField("Write your music thought", text: $viewModel.noteInput, axis: .vertical)
                        .lineLimit(4...8)
                        .modifier(ShakeEffect(animatableData: viewModel.shakeTrigger))
                    if !viewModel.validationError.isEmpty {
                        Text(viewModel.validationError)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                .listRowBackground(Color("AppSurface"))

                Section("Tags") {
                    Picker("Mood", selection: $viewModel.selectedMood) {
                        ForEach(viewModel.moods, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                    Picker("Genre", selection: $viewModel.selectedGenre) {
                        ForEach(viewModel.genres, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                    Picker("Activity", selection: $viewModel.selectedActivity) {
                        ForEach(viewModel.activities, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                }
                .listRowBackground(Color("AppSurface"))
            }
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .navigationTitle(viewModel.editingAnnotation == nil ? "New Annotation" : "Edit Annotation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        FeedbackService.tap()
                        viewModel.isEditorPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save(using: store)
                    }
                }
            }
        }
    }

    private func annotationDetail(_ annotation: Annotation) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Text(annotation.icon)
                        .font(.system(size: 54))
                    Text(annotation.title)
                        .font(.title2.bold())
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                Text(annotation.artist)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                if !annotation.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(annotation.tags, id: \.self) { tag in
                                Text(tag.replacingOccurrences(of: "mood:", with: "Mood: ").replacingOccurrences(of: "genre:", with: "Genre: ").replacingOccurrences(of: "activity:", with: "Activity: "))
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color("AppSurface"), in: Capsule())
                            }
                        }
                    }
                }

                Text(annotation.text)
                    .font(.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .appSurface(radius: 16)
            }
            .padding(16)
        }
        .background(AppBackgroundView())
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func cardContent(annotation: Annotation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if viewModel.isBulkMode {
                Image(systemName: viewModel.selectedIds.contains(annotation.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(viewModel.selectedIds.contains(annotation.id) ? Color("AppAccent") : Color("AppTextSecondary"))
                    .padding(.top, 4)
            }
            Text(annotation.icon)
                .font(.largeTitle)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(annotation.title)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    if annotation.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(Color("AppAccent"))
                    }
                    if store.isNoteFavourite(annotationId: annotation.id) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(Color("AppAccent"))
                    }
                }
                Text(annotation.artist)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(annotation.text)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
                if !annotation.tags.isEmpty {
                    Text(annotation.tags.joined(separator: " • "))
                        .font(.caption2)
                        .foregroundStyle(Color("AppAccent"))
                        .lineLimit(1)
                }
            }
        }
        .padding(10)
        .appSurface(radius: 14)
        .padding(.vertical, 4)
    }

    private var undoSnackbar: some View {
        VStack {
            Spacer()
            if viewModel.showUndoSnackbar {
                HStack {
                    Text("Annotation deleted")
                        .foregroundStyle(Color("AppTextPrimary"))
                    Spacer()
                    Button("Undo") {
                        FeedbackService.tap()
                        viewModel.undoDeletion(using: store)
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .appElevatedCard(radius: 14)
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showUndoSnackbar)
    }

    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    FeedbackService.tap()
                    viewModel.startCreating()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(width: 56, height: 56)
                        .appFAB()
                }
                .padding(.trailing, 16)
                .padding(.bottom, 92)
            }
        }
    }

}

private struct ActivitySheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("selected_annotations_\(UUID().uuidString).json")
        try? text.data(using: .utf8)?.write(to: tempURL)
        return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
