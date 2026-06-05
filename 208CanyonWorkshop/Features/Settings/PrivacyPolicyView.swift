import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    if content.isEmpty {
                        ProgressView()
                            .tint(Color("AppPrimary"))
                            .padding(.top, 40)
                    } else {
                        Markdown(content)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .tint(Color("AppPrimary"))
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        FeedbackService.tap()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadMarkdown()
            }
        }
    }

    private func loadMarkdown() {
        guard
            let url = Bundle.main.url(forResource: "privacy_policy", withExtension: "md"),
            let text = try? String(contentsOf: url)
        else {
            content = "# Privacy Policy\nUnable to load privacy policy."
            return
        }
        content = text
    }
}

struct Markdown: View {
    let rawText: String

    init(_ rawText: String) {
        self.rawText = rawText
    }

    var body: some View {
        if let attributed = try? AttributedString(markdown: rawText) {
            Text(attributed)
        } else {
            Text(rawText)
        }
    }
}
