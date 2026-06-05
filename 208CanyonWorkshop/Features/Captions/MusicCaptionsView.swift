import SwiftUI

struct MusicCaptionsView: View {
    @EnvironmentObject private var store: AppStorageStore
    @StateObject private var viewModel = MusicCaptionsViewModel()

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                AppSectionTitle(
                    title: "Caption Workspace",
                    subtitle: "Add details, capture context, and revisit edits quickly."
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                HStack(spacing: 10) {
                    AppCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total")
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text("\(store.captions.count)")
                                .font(.title3.bold())
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                    }
                    AppCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recent Songs")
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text("\(store.recentlyEditedSongIds.count)")
                                .font(.title3.bold())
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                if store.captions.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.captions) { caption in
                            NavigationLink {
                                captionDetail(caption)
                                    .onAppear {
                                        store.lastOpenedCaptionId = caption.id
                                    }
                            } label: {
                                VStack(alignment: .leading, spacing: 7) {
                                    HStack {
                                        Text(caption.songTitle)
                                            .font(.headline)
                                            .foregroundStyle(Color("AppTextPrimary"))
                                        Spacer()
                                        if store.lastOpenedCaptionId == caption.id {
                                            Text("Recent")
                                                .font(.caption2.bold())
                                                .foregroundStyle(Color("AppTextPrimary"))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(AppDesign.primaryGradient, in: Capsule())
                                        }
                                    }
                                    Text(caption.artist)
                                        .font(.subheadline)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                    Text(caption.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                    Text(caption.content)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                                .padding(10)
                                .appSurface(radius: 14)
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    FeedbackService.tap()
                                    store.deleteCaption(id: caption.id)
                                }
                                Button("Edit") {
                                    FeedbackService.tap()
                                    viewModel.openEditComposer(caption)
                                }
                                .tint(Color("AppPrimary"))
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                Button {
                    FeedbackService.tap()
                    viewModel.openNewComposer()
                } label: {
                    Text("New Caption")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .appPrimaryButton()
                }
                .padding(16)
            }

            SuccessBadgeOverlay(isVisible: $viewModel.showSuccessBadge)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    FeedbackService.tap()
                    viewModel.openNewComposer()
                }
            }
        }
        .sheet(isPresented: $viewModel.showComposer) {
            composerSheet
                .presentationDetents([.medium, .large])
        }
    }

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: "music.note")
                    .font(.system(size: 58))
                    .foregroundStyle(Color("AppAccent"))
                Text("No music annotations yet — tap '+' to add your first caption")
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Text("Start annotating your music experiences")
                    .font(.footnote)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(maxWidth: .infinity, minHeight: 320)
            .padding(.top, 50)
        }
    }

    private var composerSheet: some View {
        NavigationStack {
            Form {
                Section("Song") {
                    Picker("Select Song", selection: $viewModel.selectedSong) {
                        ForEach(viewModel.songs, id: \.self) { song in
                            Text("\(song.title) — \(song.artist)").tag(Optional(song))
                        }
                    }
                    .modifier(ShakeEffect(animatableData: viewModel.shakeTrigger))
                }
                .listRowBackground(Color("AppSurface"))

                Section("Caption Details") {
                    DatePicker("Timestamp", selection: $viewModel.captionDate)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.templates, id: \.title) { template in
                                Button(template.title) {
                                    viewModel.applyTemplate(template.body)
                                }
                                .appChip(active: true)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    TextField("Write your caption", text: $viewModel.captionText, axis: .vertical)
                        .lineLimit(4...8)
                        .modifier(ShakeEffect(animatableData: viewModel.shakeTrigger))
                    if !viewModel.validationError.isEmpty {
                        Text(viewModel.validationError)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                .listRowBackground(Color("AppSurface"))
            }
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .navigationTitle(viewModel.editingCaption == nil ? "New Caption" : "Edit Caption")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        FeedbackService.tap()
                        viewModel.showComposer = false
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

    private func captionDetail(_ caption: Caption) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(caption.songTitle)
                        .font(.title3.bold())
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(caption.artist)
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                    Text(caption.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                Text(caption.content)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .appSurface(radius: 14)
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            .padding(16)
        }
        .background(AppBackgroundView())
        .navigationTitle("Caption Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
