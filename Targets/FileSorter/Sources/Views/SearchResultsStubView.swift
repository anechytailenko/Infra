import SwiftUI

// MARK: - SearchResultsStubView
// Placeholder for the future search results screen. Shown when the user submits a query from HomeView.

struct SearchResultsStubView: View {
    let query: String
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button { dismiss() } label: {
                    HStack(spacing: AppStyle.backButtonHStackSpacing) {
                        Image(systemName: AppStyle.backButtonIcon)
                            .font(AppStyle.backButtonFont)
                        Text(AppStyle.backButtonLabel)
                            .font(AppStyle.backButtonFont)
                    }
                    .foregroundStyle(AppStyle.backButtonForegroundColor)
                    .padding(.horizontal, AppStyle.backButtonPaddingHorizontal)
                    .padding(.vertical, AppStyle.backButtonPaddingVertical)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            Text("Search results for: \(query)")
                .font(AppStyle.headlineFont)
                .foregroundStyle(AppStyle.textPrimary)
                .multilineTextAlignment(.center)
            Text("This screen will be implemented later.")
                .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                .foregroundStyle(AppStyle.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppStyle.screenBackground)
        .navigationTitle("Search")
    }
}
